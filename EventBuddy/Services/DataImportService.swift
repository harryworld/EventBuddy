import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
class DataImportService {
    private let modelContext: ModelContext
    
    var isImporting = false
    var importError: String?
    var importProgress: Double = 0.0
    var importSummary: ImportSummary?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
            
            let jsonURL: URL
            if isDirectory.boolValue {
                // Look for the JSON backup file in the directory
                jsonURL = url.appendingPathComponent("eventbuddy_backup.json")
                guard FileManager.default.fileExists(atPath: jsonURL.path) else {
                    throw ImportError.invalidFormat("No backup file found in the selected folder")
                }
            } else {
                // Direct JSON file
                jsonURL = url
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
            let result = try await importBackupData(backup)
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
    
    private func importBackupData(_ backup: DataBackup) async throws -> ImportResult {
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
        
        // Save all changes
        try modelContext.save()
        
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
                modelContext.insert(friend)
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
                modelContext.insert(event)
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
        let descriptor = FetchDescriptor<Event>()
        let events = try modelContext.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: events.map { ($0.id.uuidString, $0) })
    }
    
    private func fetchExistingFriends() throws -> [String: Friend] {
        let descriptor = FetchDescriptor<Friend>()
        let friends = try modelContext.fetch(descriptor)
        return Dictionary(uniqueKeysWithValues: friends.map { ($0.id.uuidString, $0) })
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
    var eventsCreated = 0
    var eventsUpdated = 0
    var eventsSkipped = 0
    var friendsCreated = 0
    var friendsUpdated = 0
    var friendsSkipped = 0
    var relationshipsCreated = 0
    
    var totalEvents: Int { eventsCreated + eventsUpdated + eventsSkipped }
    var totalFriends: Int { friendsCreated + friendsUpdated + friendsSkipped }
    var totalChanges: Int { eventsCreated + eventsUpdated + friendsCreated + friendsUpdated + relationshipsCreated }
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