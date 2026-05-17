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
    let profileImage: Data?
    let createdAt: Date
    let updatedAt: Date
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
    let createdAt: Date
    let updatedAt: Date
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
    let createdAt: Date
    let updatedAt: Date
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
    var isEmpty: Bool { profile == nil && friends.isEmpty && events.isEmpty }

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
                    ISO8601DateFormatter.validation.string(from: $0.createdAt),
                    ISO8601DateFormatter.validation.string(from: $0.updatedAt),
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
                    ISO8601DateFormatter.validation.string(from: $0.createdAt),
                    ISO8601DateFormatter.validation.string(from: $0.updatedAt),
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
                $0.profileImage?.base64EncodedString() ?? "",
                ISO8601DateFormatter.validation.string(from: $0.createdAt),
                ISO8601DateFormatter.validation.string(from: $0.updatedAt),
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
            friend.createdAt = $0.createdAt
            friend.updatedAt = $0.updatedAt
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
            event.createdAt = $0.createdAt
            event.updatedAt = $0.updatedAt
            return event
        }

        let profile = profile.map {
            let profile = Profile(
                id: $0.id,
                name: $0.name,
                bio: $0.bio,
                email: $0.email,
                phone: $0.phone,
                profileImage: $0.profileImage,
                socialMediaAccounts: $0.socialMediaAccounts,
                preferences: $0.preferences,
                title: $0.title,
                company: $0.company,
                avatarSystemName: $0.avatarSystemName
            )
            profile.createdAt = $0.createdAt
            profile.updatedAt = $0.updatedAt
            return profile
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
        profileImage: nil,
        createdAt: date(year: 2025, month: 6, day: 7, hour: 9, minute: 0),
        updatedAt: date(year: 2025, month: 6, day: 7, hour: 10, minute: 0),
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
            createdAt: date(year: 2025, month: 6, day: 8, hour: 19, minute: 0),
            updatedAt: date(year: 2025, month: 6, day: 8, hour: 19, minute: 30),
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
            createdAt: date(year: 2025, month: 6, day: 8, hour: 19, minute: 15),
            updatedAt: date(year: 2025, month: 6, day: 8, hour: 19, minute: 45),
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
            createdAt: date(year: 2025, month: 6, day: 9, hour: 9, minute: 0),
            updatedAt: date(year: 2025, month: 6, day: 9, hour: 9, minute: 30),
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
            createdAt: date(year: 2025, month: 6, day: 7, hour: 12, minute: 0),
            updatedAt: date(year: 2025, month: 6, day: 8, hour: 20, minute: 0),
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
            createdAt: date(year: 2025, month: 6, day: 8, hour: 10, minute: 0),
            updatedAt: date(year: 2025, month: 6, day: 9, hour: 10, minute: 0),
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
            createdAt: date(year: 2025, month: 6, day: 9, hour: 11, minute: 0),
            updatedAt: date(year: 2025, month: 6, day: 10, hour: 16, minute: 0),
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
    static let legacyMigrationDidRunKey = "EventBuddy.LegacySwiftDataMigration.v1.didRun"

    static func appSandboxLegacyStoreURL() throws -> URL {
        guard let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CocoaError(.fileNoSuchFile)
        }
        return directory.appending(path: "default.store")
    }

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
        UserDefaults.standard.removeObject(forKey: legacyMigrationDidRunKey)
    }

    static func removeIfExists(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    static func legacyStoreExists() -> Bool {
        guard let url = try? legacyStoreURL() else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func productionLegacyStoreURL() -> URL? {
        let candidates = [
            try? appSandboxLegacyStoreURL(),
            try? legacyStoreURL()
        ]
        var seen = Set<String>()
        for candidate in candidates.compactMap(\.self) {
            guard seen.insert(candidate.path).inserted else { continue }
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}

@MainActor
enum LegacySwiftDataStore {
    @Model
    final class Event {
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
        var attendees: [Friend] = []

        @Relationship(deleteRule: .nullify)
        var friendWishes: [Friend] = []

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
            self.createdAt = snapshot.createdAt
            self.updatedAt = snapshot.updatedAt
            self.isAttending = snapshot.isAttending
            self.originalTimezoneIdentifier = snapshot.originalTimezoneIdentifier
            self.isCustomEvent = snapshot.isCustomEvent
        }
    }

    @Model
    final class Friend {
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

        @Relationship(deleteRule: .nullify, inverse: \Event.attendees)
        var events: [Event] = []

        @Relationship(deleteRule: .nullify, inverse: \Event.friendWishes)
        var wishEvents: [Event] = []

        init(snapshot: MigrationFriendSnapshot) {
            self.id = snapshot.id
            self.name = snapshot.name
            self.email = snapshot.email
            self.phone = snapshot.phone
            self.jobTitle = snapshot.jobTitle
            self.company = snapshot.company
            self.socialMediaHandles = snapshot.socialMediaHandles
            self.notes = snapshot.notes
            self.createdAt = snapshot.createdAt
            self.updatedAt = snapshot.updatedAt
            self.isFavorite = snapshot.isFavorite
        }
    }

    @Model
    final class Profile {
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
            self.profileImage = snapshot.profileImage
            self.socialMediaAccounts = snapshot.socialMediaAccounts
            self.preferences = snapshot.preferences
            self.createdAt = snapshot.createdAt
            self.updatedAt = snapshot.updatedAt
            self.title = snapshot.title
            self.company = snapshot.company
            self.avatarSystemName = snapshot.avatarSystemName
        }
    }

    static func seedFixture() throws -> MigrationSnapshot {
        try MigrationValidationStorage.removeIfExists(MigrationValidationStorage.legacyStoreURL())
        let container = try makeContainer(storeURL: MigrationValidationStorage.legacyStoreURL())
        let context = container.mainContext

        let profile = Profile(snapshot: MigrationFixtureData.profile)
        let friends = MigrationFixtureData.friends.map(Friend.init(snapshot:))
        let friendMap = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
        let events = MigrationFixtureData.events.map(Event.init(snapshot:))

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

        let snapshot = try fetchSnapshot(from: MigrationValidationStorage.legacyStoreURL())
        print("📦 Seeded legacy SwiftData fixture digest: \(snapshot.digest)")
        return snapshot
    }

    static func fetchSnapshot() throws -> MigrationSnapshot {
        try fetchSnapshot(from: MigrationValidationStorage.legacyStoreURL())
    }

    static func fetchSnapshot(from storeURL: URL) throws -> MigrationSnapshot {
        let container = try makeContainer(storeURL: storeURL)
        let context = container.mainContext

        let profiles = try context.fetch(SwiftData.FetchDescriptor<Profile>())
        let friends = try context.fetch(SwiftData.FetchDescriptor<Friend>())
        let events = try context.fetch(SwiftData.FetchDescriptor<Event>())

        let profileSnapshot = profiles.first.map {
            MigrationProfileSnapshot(
                id: $0.id,
                name: $0.name,
                bio: $0.bio,
                email: $0.email,
                phone: $0.phone,
                profileImage: $0.profileImage,
                createdAt: $0.createdAt,
                updatedAt: $0.updatedAt,
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
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
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
                    createdAt: event.createdAt,
                    updatedAt: event.updatedAt,
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

    private static func makeContainer(storeURL: URL) throws -> ModelContainer {
        let schema = Schema([Event.self, Friend.self, Profile.self])
        let configuration = ModelConfiguration(
            "LegacyMigrationStore",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

@MainActor
enum LegacySwiftDataMigration {
    private static let sampleFriendID = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!

    static func migrateIfNeeded(modelContext: ModelContext) throws -> MigrationSnapshot? {
        guard !UserDefaults.standard.bool(forKey: MigrationValidationStorage.legacyMigrationDidRunKey) else {
            return nil
        }

        guard let legacyStoreURL = MigrationValidationStorage.productionLegacyStoreURL() else {
            UserDefaults.standard.set(true, forKey: MigrationValidationStorage.legacyMigrationDidRunKey)
            return nil
        }

        let snapshot = try LegacySwiftDataStore.fetchSnapshot(from: legacyStoreURL)
        guard !snapshot.isEmpty else {
            UserDefaults.standard.set(true, forKey: MigrationValidationStorage.legacyMigrationDidRunKey)
            return nil
        }

        try modelContext.reload()
        try merge(snapshot, into: modelContext)
        try modelContext.save()
        try modelContext.reload()

        UserDefaults.standard.set(true, forKey: MigrationValidationStorage.legacyMigrationDidRunKey)
        print(
            "✅ Migrated legacy SwiftData store from \(legacyStoreURL.path): " +
            "\(snapshot.events.count) events, \(snapshot.friends.count) friends, \(snapshot.profileCount) profiles"
        )
        return snapshot
    }

    private static func merge(_ snapshot: MigrationSnapshot, into modelContext: ModelContext) throws {
        try mergeProfile(snapshot.profile, into: modelContext)

        var existingFriends = try modelContext.fetch(FetchDescriptor<Friend>())
        let legacyFriendIDs = Set(snapshot.friends.map(\.id))
        if !legacyFriendIDs.isEmpty,
           !legacyFriendIDs.contains(sampleFriendID),
           let sampleFriend = existingFriends.first(where: { $0.id == sampleFriendID }) {
            modelContext.delete(sampleFriend)
            existingFriends.removeAll { $0.id == sampleFriendID }
        }

        var friendsByID = Dictionary(uniqueKeysWithValues: existingFriends.map { ($0.id, $0) })
        for friendSnapshot in snapshot.friends {
            let friend = friendsByID[friendSnapshot.id] ?? makeFriend(from: friendSnapshot)
            apply(friendSnapshot, to: friend)
            if friendsByID[friendSnapshot.id] == nil {
                modelContext.insert(friend)
                friendsByID[friend.id] = friend
            }
        }

        let existingEvents = try modelContext.fetch(FetchDescriptor<Event>())
        var eventsByID = Dictionary(uniqueKeysWithValues: existingEvents.map { ($0.id, $0) })
        for eventSnapshot in snapshot.events {
            let event = eventsByID[eventSnapshot.id] ?? makeEvent(from: eventSnapshot)
            apply(eventSnapshot, to: event, friendsByID: friendsByID)
            if eventsByID[eventSnapshot.id] == nil {
                modelContext.insert(event)
                eventsByID[event.id] = event
            }
        }
    }

    private static func mergeProfile(_ snapshot: MigrationProfileSnapshot?, into modelContext: ModelContext) throws {
        guard let snapshot else { return }

        let profiles = try modelContext.fetch(FetchDescriptor<Profile>())
        if let existingProfile = profiles.first(where: { $0.id == snapshot.id }) {
            apply(snapshot, to: existingProfile, includeID: false)
            return
        }

        if let sampleProfile = profiles.first(where: isSampleProfile) {
            apply(snapshot, to: sampleProfile, includeID: true)
            return
        }

        let profile = makeProfile(from: snapshot)
        modelContext.insert(profile)
    }

    private static func makeProfile(from snapshot: MigrationProfileSnapshot) -> Profile {
        let profile = Profile(
            id: snapshot.id,
            name: snapshot.name,
            bio: snapshot.bio,
            email: snapshot.email,
            phone: snapshot.phone,
            profileImage: snapshot.profileImage,
            socialMediaAccounts: snapshot.socialMediaAccounts,
            preferences: snapshot.preferences,
            title: snapshot.title,
            company: snapshot.company,
            avatarSystemName: snapshot.avatarSystemName
        )
        apply(snapshot, to: profile, includeID: false)
        return profile
    }

    private static func makeFriend(from snapshot: MigrationFriendSnapshot) -> Friend {
        let friend = Friend(
            id: snapshot.id,
            name: snapshot.name,
            email: snapshot.email,
            phone: snapshot.phone,
            jobTitle: snapshot.jobTitle,
            company: snapshot.company,
            socialMediaHandles: snapshot.socialMediaHandles,
            notes: snapshot.notes,
            isFavorite: snapshot.isFavorite
        )
        apply(snapshot, to: friend)
        return friend
    }

    private static func makeEvent(from snapshot: MigrationEventSnapshot) -> Event {
        let event = Event(
            id: snapshot.id,
            title: snapshot.title,
            eventDescription: snapshot.eventDescription,
            location: snapshot.location,
            address: snapshot.address,
            startDate: snapshot.startDate,
            endDate: snapshot.endDate,
            eventType: snapshot.eventType,
            notes: snapshot.notes,
            requiresTicket: snapshot.requiresTicket,
            requiresRegistration: snapshot.requiresRegistration,
            url: snapshot.url,
            isAttending: snapshot.isAttending,
            originalTimezoneIdentifier: snapshot.originalTimezoneIdentifier,
            isCustomEvent: snapshot.isCustomEvent
        )
        event.createdAt = snapshot.createdAt
        event.updatedAt = snapshot.updatedAt
        return event
    }

    private static func apply(_ snapshot: MigrationProfileSnapshot, to profile: Profile, includeID: Bool) {
        if includeID {
            profile.id = snapshot.id
        }
        profile.name = snapshot.name
        profile.bio = snapshot.bio
        profile.email = snapshot.email
        profile.phone = snapshot.phone
        profile.profileImage = snapshot.profileImage
        profile.socialMediaAccounts = snapshot.socialMediaAccounts
        profile.preferences = snapshot.preferences
        profile.createdAt = snapshot.createdAt
        profile.updatedAt = snapshot.updatedAt
        profile.title = snapshot.title
        profile.company = snapshot.company
        profile.avatarSystemName = snapshot.avatarSystemName
    }

    private static func apply(_ snapshot: MigrationFriendSnapshot, to friend: Friend) {
        friend.name = snapshot.name
        friend.email = snapshot.email
        friend.phone = snapshot.phone
        friend.jobTitle = snapshot.jobTitle
        friend.company = snapshot.company
        friend.socialMediaHandles = snapshot.socialMediaHandles
        friend.notes = snapshot.notes
        friend.createdAt = snapshot.createdAt
        friend.updatedAt = snapshot.updatedAt
        friend.isFavorite = snapshot.isFavorite
    }

    private static func apply(
        _ snapshot: MigrationEventSnapshot,
        to event: Event,
        friendsByID: [UUID: Friend]
    ) {
        event.title = snapshot.title
        event.eventDescription = snapshot.eventDescription
        event.location = snapshot.location
        event.address = snapshot.address
        event.startDate = snapshot.startDate
        event.endDate = snapshot.endDate
        event.eventType = snapshot.eventType
        event.notes = snapshot.notes
        event.requiresTicket = snapshot.requiresTicket
        event.requiresRegistration = snapshot.requiresRegistration
        event.url = snapshot.url
        event.isAttending = snapshot.isAttending
        event.originalTimezoneIdentifier = snapshot.originalTimezoneIdentifier
        event.isCustomEvent = snapshot.isCustomEvent

        event.attendees.removeAll()
        event.friendWishes.removeAll()
        for friendID in snapshot.attendeeIDs {
            if let friend = friendsByID[friendID] {
                event.addFriend(friend)
            }
        }
        for friendID in snapshot.wishIDs {
            if let friend = friendsByID[friendID] {
                event.addFriendWish(friend)
            }
        }

        event.createdAt = snapshot.createdAt
        event.updatedAt = snapshot.updatedAt
    }

    private static func isSampleProfile(_ profile: Profile) -> Bool {
        profile.name == "John Appleseed" &&
            profile.email == "john@apple.com" &&
            profile.company == "Apple Inc." &&
            profile.title == "iOS Developer"
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
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
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
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
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
                    profileImage: $0.profileImage,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt,
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
