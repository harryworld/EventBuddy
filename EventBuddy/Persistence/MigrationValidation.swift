import CryptoKit
import Foundation
import SwiftData

enum MigrationValidationMode: String {
    case legacyBaseline = "--migration-legacy-baseline"
    case sqliteMigrated = "--migration-sqlite-migrated"

    private static let environmentKey = "EVENTBUDDY_VALIDATION_MODE"

    static var current: MigrationValidationMode? {
        let environment = ProcessInfo.processInfo.environment
        if let rawValue = environment[environmentKey] {
            switch rawValue {
            case "legacy":
                return .legacyBaseline
            case "sqlite":
                return .sqliteMigrated
            default:
                break
            }
        }

        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(Self.legacyBaseline.rawValue) {
            return .legacyBaseline
        }
        if arguments.contains(Self.sqliteMigrated.rawValue) {
            return .sqliteMigrated
        }
        return nil
    }

    var title: String {
        switch self {
        case .legacyBaseline:
            return "SwiftData Baseline"
        case .sqliteMigrated:
            return "SQLite Migration"
        }
    }

    var shouldEnableSyncEngine: Bool {
        false
    }

    func prepareForLaunch() throws {
        switch self {
        case .legacyBaseline:
            try MigrationValidationStorage.resetAllStores()
        case .sqliteMigrated:
            try MigrationValidationStorage.resetSQLiteStores()
        }
    }
}

struct MigrationProfileSnapshot: Codable, Equatable {
    let id: UUID
    let name: String
    let bio: String
    let email: String?
    let phone: String?
    let title: String
    let company: String
    let avatarSystemName: String
    let socialMediaAccounts: [String: String]
    let preferences: [String: Bool]
}

struct MigrationFriendSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let jobTitle: String?
    let company: String?
    let socialMediaHandles: [String: String]
    let notes: String?
    let isFavorite: Bool
}

struct MigrationEventSnapshot: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let eventDescription: String
    let location: String
    let address: String?
    let startDate: Date
    let endDate: Date
    let eventType: String
    let notes: String?
    let requiresTicket: Bool
    let requiresRegistration: Bool
    let url: String?
    let isAttending: Bool
    let originalTimezoneIdentifier: String?
    let isCustomEvent: Bool
    let attendeeIDs: [UUID]
    let wishIDs: [UUID]
}

struct MigrationSnapshot: Codable, Equatable {
    let profile: MigrationProfileSnapshot?
    let friends: [MigrationFriendSnapshot]
    let events: [MigrationEventSnapshot]

    var profileCount: Int { profile == nil ? 0 : 1 }
    var attendeeLinkCount: Int { events.reduce(0) { $0 + $1.attendeeIDs.count } }
    var wishLinkCount: Int { events.reduce(0) { $0 + $1.wishIDs.count } }

    var digestSource: String {
        let friendChunks = friends
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.name,
                    $0.email ?? "",
                    $0.phone ?? "",
                    $0.jobTitle ?? "",
                    $0.company ?? "",
                    encodeStableDictionary($0.socialMediaHandles),
                    $0.notes ?? "",
                    $0.isFavorite ? "1" : "0"
                ].joined(separator: "|")
            }
            .joined(separator: "\n")

        let eventChunks = events
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map {
                [
                    $0.id.uuidString,
                    $0.title,
                    $0.eventDescription,
                    $0.location,
                    $0.address ?? "",
                    ISO8601DateFormatter.validation.string(from: $0.startDate),
                    ISO8601DateFormatter.validation.string(from: $0.endDate),
                    $0.eventType,
                    $0.notes ?? "",
                    $0.requiresTicket ? "1" : "0",
                    $0.requiresRegistration ? "1" : "0",
                    $0.url ?? "",
                    $0.isAttending ? "1" : "0",
                    $0.originalTimezoneIdentifier ?? "",
                    $0.isCustomEvent ? "1" : "0",
                    $0.attendeeIDs.map(\.uuidString).sorted().joined(separator: ","),
                    $0.wishIDs.map(\.uuidString).sorted().joined(separator: ",")
                ].joined(separator: "|")
            }
            .joined(separator: "\n")

        let profileChunk = profile.map {
            [
                $0.id.uuidString,
                $0.name,
                $0.bio,
                $0.email ?? "",
                $0.phone ?? "",
                $0.title,
                $0.company,
                $0.avatarSystemName,
                encodeStableDictionary($0.socialMediaAccounts),
                encodeStableDictionary($0.preferences.mapValues { $0 ? "1" : "0" })
            ].joined(separator: "|")
        } ?? "NO_PROFILE"

        return [profileChunk, friendChunks, eventChunks].joined(separator: "\n---\n")
    }

    var digest: String {
        let hash = SHA256.hash(data: Data(digestSource.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    func makeDomainModels() -> (profile: Profile?, friends: [Friend], events: [Event]) {
        let friends = friends.map {
            let friend = Friend(
                id: $0.id,
                name: $0.name,
                email: $0.email,
                phone: $0.phone,
                jobTitle: $0.jobTitle,
                company: $0.company,
                socialMediaHandles: $0.socialMediaHandles,
                notes: $0.notes,
                isFavorite: $0.isFavorite
            )
            return friend
        }

        let friendMap = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })

        let events = events.map {
            let event = Event(
                id: $0.id,
                title: $0.title,
                eventDescription: $0.eventDescription,
                location: $0.location,
                address: $0.address,
                startDate: $0.startDate,
                endDate: $0.endDate,
                eventType: $0.eventType,
                notes: $0.notes,
                requiresTicket: $0.requiresTicket,
                requiresRegistration: $0.requiresRegistration,
                url: $0.url,
                isAttending: $0.isAttending,
                originalTimezoneIdentifier: $0.originalTimezoneIdentifier,
                isCustomEvent: $0.isCustomEvent
            )
            for friendID in $0.attendeeIDs {
                if let friend = friendMap[friendID] {
                    event.addFriend(friend)
                }
            }
            for friendID in $0.wishIDs {
                if let friend = friendMap[friendID] {
                    event.addFriendWish(friend)
                }
            }
            return event
        }

        let profile = profile.map {
            Profile(
                id: $0.id,
                name: $0.name,
                bio: $0.bio,
                email: $0.email,
                phone: $0.phone,
                profileImage: nil,
                socialMediaAccounts: $0.socialMediaAccounts,
                preferences: $0.preferences,
                title: $0.title,
                company: $0.company,
                avatarSystemName: $0.avatarSystemName
            )
        }

        return (profile, friends, events)
    }
}

struct MigrationComparison {
    let legacy: MigrationSnapshot
    let sqlite: MigrationSnapshot

    var matchesExactly: Bool {
        legacy == sqlite && legacy.digest == sqlite.digest
    }
}

enum MigrationFixtureData {
    static let profile = MigrationProfileSnapshot(
        id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
        name: "Taylor Developer",
        bio: "Building EventBuddy migration fixtures.",
        email: "taylor@example.com",
        phone: "+1 555 000 1000",
        title: "iOS Engineer",
        company: "Build with Harry",
        avatarSystemName: "person.crop.circle.fill",
        socialMediaAccounts: [
            "github": "taylordev",
            "linkedin": "taylor-developer"
        ],
        preferences: [
            "darkMode": true,
            "notificationsEnabled": true,
            "shareLocation": false
        ]
    )

    static let friends = [
        MigrationFriendSnapshot(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB01")!,
            name: "Avery Chen",
            email: "avery@example.com",
            phone: "+1 555 000 2001",
            jobTitle: "Swift Engineer",
            company: "Apple",
            socialMediaHandles: ["twitter": "averyswift"],
            notes: "Met at the labs.",
            isFavorite: true
        ),
        MigrationFriendSnapshot(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB02")!,
            name: "Sam Rivera",
            email: "sam@example.com",
            phone: "+1 555 000 2002",
            jobTitle: "Product Designer",
            company: "Figma",
            socialMediaHandles: ["instagram": "samdesigns"],
            notes: "Great conversation about prototypes.",
            isFavorite: false
        ),
        MigrationFriendSnapshot(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB03")!,
            name: "Jordan Kim",
            email: "jordan@example.com",
            phone: "+1 555 000 2003",
            jobTitle: "Cloud Architect",
            company: "RevenueCat",
            socialMediaHandles: ["github": "jordankim"],
            notes: "Discussed sync edge cases.",
            isFavorite: true
        )
    ]

    static let events = [
        MigrationEventSnapshot(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC01")!,
            title: "Swift on Tap",
            eventDescription: "Evening meetup to talk about modern Swift and migration strategy.",
            location: "Cafe Macs",
            address: "Apple Park Visitor Center",
            startDate: date(year: 2025, month: 6, day: 8, hour: 18, minute: 0),
            endDate: date(year: 2025, month: 6, day: 8, hour: 20, minute: 0),
            eventType: EventType.social.rawValue,
            notes: "Bring notes for migration comparison.",
            requiresTicket: false,
            requiresRegistration: true,
            url: "https://example.com/swift-on-tap",
            isAttending: true,
            originalTimezoneIdentifier: "America/Los_Angeles",
            isCustomEvent: true,
            attendeeIDs: [
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB01")!,
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB02")!
            ],
            wishIDs: [
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB03")!
            ]
        ),
        MigrationEventSnapshot(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC02")!,
            title: "VisionOS Breakfast",
            eventDescription: "Morning coffee meetup about spatial UI.",
            location: "Philz Coffee",
            address: "19439 Stevens Creek Blvd, Cupertino, CA",
            startDate: date(year: 2025, month: 6, day: 9, hour: 8, minute: 30),
            endDate: date(year: 2025, month: 6, day: 9, hour: 9, minute: 30),
            eventType: EventType.meetup.rawValue,
            notes: "Short walk to Apple Park afterwards.",
            requiresTicket: false,
            requiresRegistration: false,
            url: "https://example.com/vision-breakfast",
            isAttending: false,
            originalTimezoneIdentifier: "America/Los_Angeles",
            isCustomEvent: true,
            attendeeIDs: [
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB03")!
            ],
            wishIDs: [
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB01")!
            ]
        ),
        MigrationEventSnapshot(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCC03")!,
            title: "CloudKit Lab",
            eventDescription: "Hands-on debugging session for sync issues.",
            location: "Hyatt House",
            address: "10380 Perimeter Rd, Cupertino, CA",
            startDate: date(year: 2025, month: 6, day: 10, hour: 14, minute: 0),
            endDate: date(year: 2025, month: 6, day: 10, hour: 16, minute: 0),
            eventType: EventType.keynote.rawValue,
            notes: "Use this event to verify attended relationships.",
            requiresTicket: true,
            requiresRegistration: true,
            url: "https://example.com/cloudkit-lab",
            isAttending: true,
            originalTimezoneIdentifier: "America/Los_Angeles",
            isCustomEvent: true,
            attendeeIDs: [
                UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB02")!
            ],
            wishIDs: []
        )
    ]

    static let snapshot = MigrationSnapshot(
        profile: profile,
        friends: friends,
        events: events
    )

    static func date(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "America/Los_Angeles")
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return components.date!
    }
}

enum MigrationValidationStorage {
    static let lastSyncDateKey = "EventSyncService.lastSyncDate"

    static func appGroupURL() throws -> URL {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: EventBuddyDatabase.appGroupIdentifier
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }

    static func ensureLegacyDirectoryExists() throws -> URL {
        let directory = try appGroupURL().appending(path: "Library/Application Support")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func legacyStoreURL() throws -> URL {
        try ensureLegacyDirectoryExists().appending(path: "default.store")
    }

    static func sqliteStoreURL() throws -> URL {
        try EventBuddyDatabase.databaseURL()
    }

    static func sqliteMetadataURL() throws -> URL {
        try appGroupURL().appending(path: ".EventBuddy.metadata-\(EventBuddyDatabase.cloudKitContainerIdentifier).sqlite")
    }

    static func resetAllStores() throws {
        try removeIfExists(try legacyStoreURL())
        try resetSQLiteStores()
    }

    static func resetSQLiteStores() throws {
        try removeIfExists(try sqliteStoreURL())
        try removeIfExists(try sqliteMetadataURL())
        UserDefaults.standard.removeObject(forKey: lastSyncDateKey)
    }

    static func removeIfExists(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    static func legacyStoreExists() -> Bool {
        guard let url = try? legacyStoreURL() else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}

@MainActor
enum LegacySwiftDataStore {
    @Model
    final class LegacyEvent {
        var id: UUID
        var title: String
        var eventDescription: String
        var location: String
        var address: String?
        var startDate: Date
        var endDate: Date
        var eventType: String
        var notes: String?
        var requiresTicket: Bool
        var requiresRegistration: Bool
        var url: String?
        var createdAt: Date
        var updatedAt: Date
        var isAttending: Bool
        var originalTimezoneIdentifier: String?
        var isCustomEvent: Bool

        @Relationship(deleteRule: .nullify)
        var attendees: [LegacyFriend] = []

        @Relationship(deleteRule: .nullify)
        var friendWishes: [LegacyFriend] = []

        init(snapshot: MigrationEventSnapshot) {
            self.id = snapshot.id
            self.title = snapshot.title
            self.eventDescription = snapshot.eventDescription
            self.location = snapshot.location
            self.address = snapshot.address
            self.startDate = snapshot.startDate
            self.endDate = snapshot.endDate
            self.eventType = snapshot.eventType
            self.notes = snapshot.notes
            self.requiresTicket = snapshot.requiresTicket
            self.requiresRegistration = snapshot.requiresRegistration
            self.url = snapshot.url
            self.createdAt = snapshot.startDate
            self.updatedAt = snapshot.endDate
            self.isAttending = snapshot.isAttending
            self.originalTimezoneIdentifier = snapshot.originalTimezoneIdentifier
            self.isCustomEvent = snapshot.isCustomEvent
        }
    }

    @Model
    final class LegacyFriend {
        var id: UUID
        var name: String
        var email: String?
        var phone: String?
        var jobTitle: String?
        var company: String?
        var socialMediaHandles: [String: String]
        var notes: String?
        var createdAt: Date
        var updatedAt: Date
        var isFavorite: Bool

        @Relationship(deleteRule: .nullify, inverse: \LegacyEvent.attendees)
        var events: [LegacyEvent] = []

        @Relationship(deleteRule: .nullify, inverse: \LegacyEvent.friendWishes)
        var wishEvents: [LegacyEvent] = []

        init(snapshot: MigrationFriendSnapshot) {
            self.id = snapshot.id
            self.name = snapshot.name
            self.email = snapshot.email
            self.phone = snapshot.phone
            self.jobTitle = snapshot.jobTitle
            self.company = snapshot.company
            self.socialMediaHandles = snapshot.socialMediaHandles
            self.notes = snapshot.notes
            self.createdAt = Date()
            self.updatedAt = Date()
            self.isFavorite = snapshot.isFavorite
        }
    }

    @Model
    final class LegacyProfile {
        var id: UUID
        var name: String
        var bio: String
        var email: String?
        var phone: String?
        var profileImage: Data?
        var socialMediaAccounts: [String: String]
        var preferences: [String: Bool]
        var createdAt: Date
        var updatedAt: Date
        var title: String
        var company: String
        var avatarSystemName: String

        init(snapshot: MigrationProfileSnapshot) {
            self.id = snapshot.id
            self.name = snapshot.name
            self.bio = snapshot.bio
            self.email = snapshot.email
            self.phone = snapshot.phone
            self.profileImage = nil
            self.socialMediaAccounts = snapshot.socialMediaAccounts
            self.preferences = snapshot.preferences
            self.createdAt = Date()
            self.updatedAt = Date()
            self.title = snapshot.title
            self.company = snapshot.company
            self.avatarSystemName = snapshot.avatarSystemName
        }
    }

    static func seedFixture() throws -> MigrationSnapshot {
        try MigrationValidationStorage.removeIfExists(MigrationValidationStorage.legacyStoreURL())
        let container = try makeContainer()
        let context = container.mainContext

        let profile = LegacyProfile(snapshot: MigrationFixtureData.profile)
        let friends = MigrationFixtureData.friends.map(LegacyFriend.init(snapshot:))
        let friendMap = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        let events = MigrationFixtureData.events.map(LegacyEvent.init(snapshot:))

        for event in events {
            let record = MigrationFixtureData.events.first { $0.id == event.id }!
            event.attendees = record.attendeeIDs.compactMap { friendMap[$0] }
            event.friendWishes = record.wishIDs.compactMap { friendMap[$0] }
        }

        context.insert(profile)
        for friend in friends {
            context.insert(friend)
        }
        for event in events {
            context.insert(event)
        }
        try context.save()

        let snapshot = try fetchSnapshot()
        print("📦 Seeded legacy SwiftData fixture digest: \(snapshot.digest)")
        return snapshot
    }

    static func fetchSnapshot() throws -> MigrationSnapshot {
        let container = try makeContainer()
        let context = container.mainContext

        let profiles = try context.fetch(SwiftData.FetchDescriptor<LegacyProfile>())
        let friends = try context.fetch(SwiftData.FetchDescriptor<LegacyFriend>())
        let events = try context.fetch(SwiftData.FetchDescriptor<LegacyEvent>())

        let profileSnapshot = profiles.first.map {
            MigrationProfileSnapshot(
                id: $0.id,
                name: $0.name,
                bio: $0.bio,
                email: $0.email,
                phone: $0.phone,
                title: $0.title,
                company: $0.company,
                avatarSystemName: $0.avatarSystemName,
                socialMediaAccounts: $0.socialMediaAccounts,
                preferences: $0.preferences
            )
        }

        let friendSnapshots = friends
            .map {
                MigrationFriendSnapshot(
                    id: $0.id,
                    name: $0.name,
                    email: $0.email,
                    phone: $0.phone,
                    jobTitle: $0.jobTitle,
                    company: $0.company,
                    socialMediaHandles: $0.socialMediaHandles,
                    notes: $0.notes,
                    isFavorite: $0.isFavorite
                )
            }
            .sorted { $0.name < $1.name }

        let eventSnapshots = events
            .map { event in
                let attendeeIDs = event.attendees.map(\.id).sorted { $0.uuidString < $1.uuidString }
                let wishIDs = event.friendWishes.map(\.id).sorted { $0.uuidString < $1.uuidString }

                return MigrationEventSnapshot(
                    id: event.id,
                    title: event.title,
                    eventDescription: event.eventDescription,
                    location: event.location,
                    address: event.address,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    eventType: event.eventType,
                    notes: event.notes,
                    requiresTicket: event.requiresTicket,
                    requiresRegistration: event.requiresRegistration,
                    url: event.url,
                    isAttending: event.isAttending,
                    originalTimezoneIdentifier: event.originalTimezoneIdentifier,
                    isCustomEvent: event.isCustomEvent,
                    attendeeIDs: attendeeIDs,
                    wishIDs: wishIDs
                )
            }
            .sorted { $0.startDate < $1.startDate }

        return MigrationSnapshot(profile: profileSnapshot, friends: friendSnapshots, events: eventSnapshots)
    }

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([LegacyEvent.self, LegacyFriend.self, LegacyProfile.self])
        let configuration = ModelConfiguration(
            "LegacyMigrationStore",
            schema: schema,
            url: try MigrationValidationStorage.legacyStoreURL(),
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor
enum SQLiteMigrationValidator {
    static func fetchSnapshot(modelContext: ModelContext) throws -> MigrationSnapshot {
        let profile = try modelContext.fetch(FetchDescriptor<Profile>()).first
        let friends = try modelContext.fetch(FetchDescriptor<Friend>())
            .map {
                MigrationFriendSnapshot(
                    id: $0.id,
                    name: $0.name,
                    email: $0.email,
                    phone: $0.phone,
                    jobTitle: $0.jobTitle,
                    company: $0.company,
                    socialMediaHandles: $0.socialMediaHandles,
                    notes: $0.notes,
                    isFavorite: $0.isFavorite
                )
            }
            .sorted { $0.name < $1.name }

        let events = try modelContext.fetch(FetchDescriptor<Event>())
            .map {
                MigrationEventSnapshot(
                    id: $0.id,
                    title: $0.title,
                    eventDescription: $0.eventDescription,
                    location: $0.location,
                    address: $0.address,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    eventType: $0.eventType,
                    notes: $0.notes,
                    requiresTicket: $0.requiresTicket,
                    requiresRegistration: $0.requiresRegistration,
                    url: $0.url,
                    isAttending: $0.isAttending,
                    originalTimezoneIdentifier: $0.originalTimezoneIdentifier,
                    isCustomEvent: $0.isCustomEvent,
                    attendeeIDs: $0.attendees.map(\.id).sorted { $0.uuidString < $1.uuidString },
                    wishIDs: $0.friendWishes.map(\.id).sorted { $0.uuidString < $1.uuidString }
                )
            }
            .sorted { $0.startDate < $1.startDate }

        return MigrationSnapshot(
            profile: profile.map {
                MigrationProfileSnapshot(
                    id: $0.id,
                    name: $0.name,
                    bio: $0.bio,
                    email: $0.email,
                    phone: $0.phone,
                    title: $0.title,
                    company: $0.company,
                    avatarSystemName: $0.avatarSystemName,
                    socialMediaAccounts: $0.socialMediaAccounts,
                    preferences: $0.preferences
                )
            },
            friends: friends,
            events: events
        )
    }

    static func migrateLegacyStoreToSQLite(modelContext: ModelContext) throws -> MigrationComparison {
        let legacySnapshot = MigrationValidationStorage.legacyStoreExists()
            ? try LegacySwiftDataStore.fetchSnapshot()
            : try LegacySwiftDataStore.seedFixture()

        try modelContext.delete(model: Event.self)
        try modelContext.delete(model: Friend.self)
        try modelContext.delete(model: Profile.self)

        let models = legacySnapshot.makeDomainModels()

        if let profile = models.profile {
            modelContext.insert(profile)
        }
        for friend in models.friends {
            modelContext.insert(friend)
        }
        for event in models.events {
            modelContext.insert(event)
        }

        try modelContext.save()
        try modelContext.reload()

        let sqliteSnapshot = try fetchSnapshot(modelContext: modelContext)
        print("🗃️ SQLite migration digest: \(sqliteSnapshot.digest)")
        return MigrationComparison(legacy: legacySnapshot, sqlite: sqliteSnapshot)
    }
}

private extension ISO8601DateFormatter {
    static let validation: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private func encodeStableDictionary(_ dictionary: [String: String]) -> String {
    dictionary
        .sorted { $0.key < $1.key }
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: ",")
}
