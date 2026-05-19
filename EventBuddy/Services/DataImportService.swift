import Foundation
import UniformTypeIdentifiers
import Contacts

@MainActor
@Observable
class DataImportService {
    private let persistenceService: EventPersistenceService
    
    var isImporting = false
    var importError: String?
    var importProgress: Double = 0.0
    var importSummary: ImportSummary?
    
    init(persistenceService: EventPersistenceService) {
        self.persistenceService = persistenceService
    }
    
    // MARK: - Main Import Function
    
    func importData(from url: URL) async -> ImportResult? {
        isImporting = true
        importError = nil
        importProgress = 0.0
        importSummary = nil
        
        defer {
            isImporting = false
            importProgress = 0.0
        }
        
        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Check if it's a directory (exported folder) or a file
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            
            print("Import Debug - URL: \(url)")
            print("Import Debug - Path: \(url.path)")
            print("Import Debug - Exists: \(exists)")
            print("Import Debug - Is Directory: \(isDirectory.boolValue)")
            
            guard exists else {
                print("Import Debug - File not found at path: \(url.path)")
                throw ImportError.fileNotFound
            }
            
            if !isDirectory.boolValue && isVCardFile(url) {
                let result = try await importPersonalNamecard(from: url)
                importProgress = 1.0
                return result
            }

            let jsonURL: URL
            let personalNamecardURL: URL?
            if isDirectory.boolValue {
                // Look for the JSON backup file in the directory
                jsonURL = url.appendingPathComponent("eventbuddy_backup.json")
                guard FileManager.default.fileExists(atPath: jsonURL.path) else {
                    throw ImportError.invalidFormat("No backup file found in the selected folder")
                }
                let namecardURL = url.appendingPathComponent("personal_namecard.vcf")
                personalNamecardURL = FileManager.default.fileExists(atPath: namecardURL.path) ? namecardURL : nil
            } else {
                // Direct JSON file
                jsonURL = url
                personalNamecardURL = nil
            }
            
            importProgress = 0.1
            
            // Read and parse JSON
            let data = try Data(contentsOf: jsonURL)
            importProgress = 0.2
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let backup = try decoder.decode(DataBackup.self, from: data)
            importProgress = 0.3
            
            // Validate backup
            try validateBackup(backup)
            importProgress = 0.4
            
            // Import data with conflict resolution
            let result = try await importBackupData(
                backup,
                personalNamecardURL: personalNamecardURL
            )
            importProgress = 1.0
            
            return result
            
        } catch {
            if let importError = error as? ImportError {
                self.importError = importError.localizedDescription
            } else if let cocoaError = error as? CocoaError {
                switch cocoaError.code {
                case .fileReadNoSuchFile:
                    self.importError = "The selected file could not be found. Please try selecting the file again."
                case .fileReadNoPermission:
                    self.importError = "Permission denied. Please ensure the file is accessible and try again."
                case .fileReadCorruptFile:
                    self.importError = "The backup file appears to be corrupted or invalid."
                default:
                    self.importError = "File access error: \(error.localizedDescription)"
                }
            } else {
                self.importError = "Failed to import data: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    // MARK: - Backup Validation
    
    private func validateBackup(_ backup: DataBackup) throws {
        // Check version compatibility
        guard backup.version == "1.0" else {
            throw ImportError.incompatibleVersion(backup.version)
        }
        
        // Validate data integrity
        let eventIds = Set(backup.events.map { $0.id })
        let friendIds = Set(backup.friends.map { $0.id })
        
        // Check that all relationship references exist
        for attendee in backup.relationships.eventAttendees {
            guard eventIds.contains(attendee.eventId) else {
                throw ImportError.invalidFormat("Event reference not found: \(attendee.eventId)")
            }
            guard friendIds.contains(attendee.friendId) else {
                throw ImportError.invalidFormat("Friend reference not found: \(attendee.friendId)")
            }
        }
        
        for wish in backup.relationships.eventWishes {
            guard eventIds.contains(wish.eventId) else {
                throw ImportError.invalidFormat("Event reference not found: \(wish.eventId)")
            }
            guard friendIds.contains(wish.friendId) else {
                throw ImportError.invalidFormat("Friend reference not found: \(wish.friendId)")
            }
        }
    }
    
    // MARK: - Data Import
    
    private func importBackupData(
        _ backup: DataBackup,
        personalNamecardURL: URL?
    ) async throws -> ImportResult {
        var summary = ImportSummary()
        
        // Create lookup dictionaries for existing data
        let existingEvents = try fetchExistingEvents()
        let existingFriends = try fetchExistingFriends()
        
        importProgress = 0.5
        
        // Import friends first (events may reference them)
        let friendIdMap = try await importFriends(
            backup.friends,
            existingFriends: existingFriends,
            summary: &summary
        )
        
        importProgress = 0.7
        
        // Import events
        let eventIdMap = try await importEvents(
            backup.events,
            existingEvents: existingEvents,
            summary: &summary
        )
        
        importProgress = 0.9
        
        // Import relationships
        try await importRelationships(
            backup.relationships,
            eventIdMap: eventIdMap,
            friendIdMap: friendIdMap,
            summary: &summary
        )

        let profile: Profile?
        if let profileDTO = backup.profile {
            profile = try overrideProfile(from: profileDTO, summary: &summary)
        } else if let personalNamecardURL {
            profile = try overrideProfile(fromVCardAt: personalNamecardURL, summary: &summary)
        } else {
            profile = nil
        }
        
        try persistenceService.persist(
            Array(eventIdMap.values),
            friends: Array(friendIdMap.values),
            profiles: profile.map { [$0] } ?? []
        )
        
        self.importSummary = summary
        
        return ImportResult(
            success: true,
            summary: summary,
            importDate: Date()
        )
    }

    private func importPersonalNamecard(from url: URL) async throws -> ImportResult {
        importProgress = 0.1
        var summary = ImportSummary()
        let profile = try overrideProfile(fromVCardAt: url, summary: &summary)
        importProgress = 0.9
        try persistenceService.persist(profile)

        self.importSummary = summary

        return ImportResult(
            success: true,
            summary: summary,
            importDate: Date()
        )
    }
    
    private func importFriends(
        _ friendDTOs: [FriendExportDTO],
        existingFriends: [String: Friend],
        summary: inout ImportSummary
    ) async throws -> [String: Friend] {
        var friendIdMap: [String: Friend] = [:]
        
        for dto in friendDTOs {
            if let existingFriend = existingFriends[dto.id] {
                // Update existing friend if the imported data is newer
                if dto.updatedAt > existingFriend.updatedAt {
                    updateFriend(existingFriend, from: dto)
                    summary.friendsUpdated += 1
                } else {
                    summary.friendsSkipped += 1
                }
                friendIdMap[dto.id] = existingFriend
            } else {
                // Create new friend
                let friend = createFriend(from: dto)
                friendIdMap[dto.id] = friend
                summary.friendsCreated += 1
            }
        }
        
        return friendIdMap
    }
    
    private func importEvents(
        _ eventDTOs: [EventExportDTO],
        existingEvents: [String: Event],
        summary: inout ImportSummary
    ) async throws -> [String: Event] {
        var eventIdMap: [String: Event] = [:]
        
        for dto in eventDTOs {
            if let existingEvent = existingEvents[dto.id] {
                // Update existing event if the imported data is newer
                if dto.updatedAt > existingEvent.updatedAt {
                    updateEvent(existingEvent, from: dto)
                    summary.eventsUpdated += 1
                } else {
                    summary.eventsSkipped += 1
                }
                eventIdMap[dto.id] = existingEvent
            } else {
                // Create new event
                let event = createEvent(from: dto)
                eventIdMap[dto.id] = event
                summary.eventsCreated += 1
            }
        }
        
        return eventIdMap
    }
    
    private func importRelationships(
        _ relationships: RelationshipData,
        eventIdMap: [String: Event],
        friendIdMap: [String: Friend],
        summary: inout ImportSummary
    ) async throws {
        // Import attendee relationships
        for attendeeRelation in relationships.eventAttendees {
            guard let event = eventIdMap[attendeeRelation.eventId],
                  let friend = friendIdMap[attendeeRelation.friendId] else {
                continue
            }
            
            if !event.attendees.contains(where: { $0.id == friend.id }) {
                event.addFriend(friend)
                summary.relationshipsCreated += 1
            }
        }
        
        // Import wish relationships
        for wishRelation in relationships.eventWishes {
            guard let event = eventIdMap[wishRelation.eventId],
                  let friend = friendIdMap[wishRelation.friendId] else {
                continue
            }
            
            if !event.friendWishes.contains(where: { $0.id == friend.id }) {
                event.addFriendWish(friend)
                summary.relationshipsCreated += 1
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func fetchExistingEvents() throws -> [String: Event] {
        let events = try persistenceService.events()
        return Dictionary(uniqueKeysWithValues: events.map { ($0.id.uuidString, $0) })
    }
    
    private func fetchExistingFriends() throws -> [String: Friend] {
        let friends = try persistenceService.friends()
        return Dictionary(uniqueKeysWithValues: friends.map { ($0.id.uuidString, $0) })
    }

    private func isVCardFile(_ url: URL) -> Bool {
        url.pathExtension.localizedCaseInsensitiveCompare("vcf") == .orderedSame
    }

    private func overrideProfile(fromVCardAt url: URL, summary: inout ImportSummary) throws -> Profile {
        let data = try Data(contentsOf: url)
        importProgress = 0.3
        let contacts = try CNContactVCardSerialization.contacts(with: data)
        guard let contact = contacts.first else {
            throw ImportError.invalidFormat("No contact found in the selected namecard")
        }

        importProgress = 0.5
        return try overrideProfile(with: contact, summary: &summary)
    }

    private func overrideProfile(from dto: ProfileExportDTO, summary: inout ImportSummary) throws -> Profile {
        let profiles = try persistenceService.profiles()

        if let profile = profiles.first {
            profile.name = dto.name
            profile.bio = dto.bio
            profile.email = Profile.normalizedEmail(dto.email)
            profile.phone = dto.phone
            profile.profileImage = dto.profileImage
            profile.socialMediaAccounts = dto.socialMediaAccounts
            profile.preferences = dto.preferences
            profile.title = dto.title
            profile.company = dto.company
            profile.avatarSystemName = dto.avatarSystemName
            profile.updatedAt = Date()
            summary.profilesUpdated += 1
            return profile
        } else {
            let profile = Profile(
                id: UUID(uuidString: dto.id) ?? UUID(),
                name: dto.name,
                bio: dto.bio,
                email: Profile.normalizedEmail(dto.email),
                phone: dto.phone,
                profileImage: dto.profileImage,
                socialMediaAccounts: dto.socialMediaAccounts,
                preferences: dto.preferences,
                title: dto.title,
                company: dto.company,
                avatarSystemName: dto.avatarSystemName
            )
            profile.createdAt = dto.createdAt
            profile.updatedAt = dto.updatedAt
            summary.profilesCreated += 1
            return profile
        }
    }

    private func overrideProfile(with contact: CNContact, summary: inout ImportSummary) throws -> Profile {
        let profiles = try persistenceService.profiles()
        let socialMediaAccounts = socialMediaAccounts(from: contact)

        if let profile = profiles.first {
            profile.name = displayName(for: contact)
            profile.email = Profile.normalizedEmail(contact.emailAddresses.first.map { String($0.value) })
            profile.phone = contact.phoneNumbers.first?.value.stringValue
            profile.profileImage = contact.imageData ?? profile.profileImage
            profile.socialMediaAccounts = socialMediaAccounts
            profile.title = contact.jobTitle
            profile.company = contact.organizationName
            profile.markAsUpdated()
            summary.profilesUpdated += 1
            return profile
        } else {
            let profile = Profile(
                name: displayName(for: contact),
                bio: "",
                email: Profile.normalizedEmail(contact.emailAddresses.first.map { String($0.value) }),
                phone: contact.phoneNumbers.first?.value.stringValue,
                profileImage: contact.imageData,
                socialMediaAccounts: socialMediaAccounts,
                preferences: [
                    "darkMode": false,
                    "notificationsEnabled": true,
                    "shareLocation": false
                ],
                title: contact.jobTitle,
                company: contact.organizationName,
                avatarSystemName: "person.crop.circle.fill"
            )
            summary.profilesCreated += 1
            return profile
        }
    }

    private func displayName(for contact: CNContact) -> String {
        if let formattedName = CNContactFormatter.string(from: contact, style: .fullName),
           !formattedName.isEmpty {
            return formattedName
        }

        let nameParts = [
            contact.givenName,
            contact.middleName,
            contact.familyName
        ].filter { !$0.isEmpty }

        if !nameParts.isEmpty {
            return nameParts.joined(separator: " ")
        }

        if !contact.nickname.isEmpty {
            return contact.nickname
        }

        if !contact.organizationName.isEmpty {
            return contact.organizationName
        }

        return "Your Name"
    }

    private func socialMediaAccounts(from contact: CNContact) -> [String: String] {
        var accounts: [String: String] = [:]

        for socialProfile in contact.socialProfiles {
            let profile = socialProfile.value
            let username = cleanUsername(
                profile.username.isEmpty
                    ? usernameFromURL(profile.urlString)
                    : profile.username
            )

            guard !username.isEmpty else { continue }

            let service = socialMediaServiceKey(
                service: profile.service,
                label: socialProfile.label
            )
            accounts[service] = username
        }

        return accounts
    }

    private func socialMediaServiceKey(service: String, label: String?) -> String {
        let normalized = "\(service) \(label ?? "")".lowercased()

        if normalized.contains("twitter") || normalized.contains("x-socialprofile") {
            return "twitter"
        } else if normalized.contains("linkedin") {
            return "linkedin"
        } else if normalized.contains("github") {
            return "github"
        } else if normalized.contains("instagram") {
            return "instagram"
        } else if normalized.contains("facebook") {
            return "facebook"
        } else if normalized.contains("threads") {
            return "threads"
        } else if normalized.contains("youtube") {
            return "youtube"
        }

        let fallback = service.isEmpty ? (label ?? "social") : service
        return fallback
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
    }

    private func usernameFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString),
              let lastPathComponent = url.pathComponents.last,
              lastPathComponent != "/" else {
            return ""
        }

        return lastPathComponent
    }

    private func cleanUsername(_ username: String) -> String {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
    }
    
    private func createFriend(from dto: FriendExportDTO) -> Friend {
        let friend = Friend(
            id: UUID(uuidString: dto.id) ?? UUID(),
            name: dto.name,
            email: dto.email,
            phone: dto.phone,
            jobTitle: dto.jobTitle,
            company: dto.company,
            socialMediaHandles: dto.socialMediaHandles,
            notes: dto.notes,
            isFavorite: dto.isFavorite
        )
        
        // Set the original timestamps
        friend.createdAt = dto.createdAt
        friend.updatedAt = dto.updatedAt
        
        return friend
    }
    
    private func updateFriend(_ friend: Friend, from dto: FriendExportDTO) {
        friend.name = dto.name
        friend.email = dto.email
        friend.phone = dto.phone
        friend.jobTitle = dto.jobTitle
        friend.company = dto.company
        friend.socialMediaHandles = dto.socialMediaHandles
        friend.notes = dto.notes
        friend.isFavorite = dto.isFavorite
        friend.updatedAt = dto.updatedAt
    }
    
    private func createEvent(from dto: EventExportDTO) -> Event {
        let event = Event(
            id: UUID(uuidString: dto.id) ?? UUID(),
            title: dto.title,
            eventDescription: dto.eventDescription,
            location: dto.location,
            address: dto.address,
            startDate: dto.startDate,
            endDate: dto.endDate,
            eventType: dto.eventType,
            notes: dto.notes,
            requiresTicket: dto.requiresTicket,
            requiresRegistration: dto.requiresRegistration,
            url: dto.url,
            isAttending: dto.isAttending,
            originalTimezoneIdentifier: dto.originalTimezoneIdentifier,
            isCustomEvent: dto.isCustomEvent
        )
        
        // Set the original timestamps
        event.createdAt = dto.createdAt
        event.updatedAt = dto.updatedAt
        
        return event
    }
    
    private func updateEvent(_ event: Event, from dto: EventExportDTO) {
        event.title = dto.title
        event.eventDescription = dto.eventDescription
        event.location = dto.location
        event.address = dto.address
        event.startDate = dto.startDate
        event.endDate = dto.endDate
        event.eventType = dto.eventType
        event.notes = dto.notes
        event.requiresTicket = dto.requiresTicket
        event.requiresRegistration = dto.requiresRegistration
        event.url = dto.url
        event.isAttending = dto.isAttending
        event.originalTimezoneIdentifier = dto.originalTimezoneIdentifier
        event.isCustomEvent = dto.isCustomEvent
        event.updatedAt = dto.updatedAt
    }
}

// MARK: - Data Structures

struct ImportResult {
    let success: Bool
    let summary: ImportSummary
    let importDate: Date
}

struct ImportSummary {
    var profilesCreated = 0
    var profilesUpdated = 0
    var eventsCreated = 0
    var eventsUpdated = 0
    var eventsSkipped = 0
    var friendsCreated = 0
    var friendsUpdated = 0
    var friendsSkipped = 0
    var relationshipsCreated = 0
    
    var totalProfiles: Int { profilesCreated + profilesUpdated }
    var totalEvents: Int { eventsCreated + eventsUpdated + eventsSkipped }
    var totalFriends: Int { friendsCreated + friendsUpdated + friendsSkipped }
    var totalChanges: Int { profilesCreated + profilesUpdated + eventsCreated + eventsUpdated + friendsCreated + friendsUpdated + relationshipsCreated }
}

// MARK: - Error Types

enum ImportError: LocalizedError {
    case fileNotFound
    case invalidFormat(String)
    case incompatibleVersion(String)
    case dataCorruption
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The selected file or folder could not be found"
        case .invalidFormat(let details):
            return "Invalid backup format: \(details)"
        case .incompatibleVersion(let version):
            return "Incompatible backup version: \(version). This app supports version 1.0"
        case .dataCorruption:
            return "The backup file appears to be corrupted"
        case .permissionDenied:
            return "Permission denied to access the selected file"
        }
    }
}
