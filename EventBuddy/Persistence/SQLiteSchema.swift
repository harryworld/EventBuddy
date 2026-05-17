import Foundation
import OSLog
import SQLiteData

@Table
nonisolated struct StoredEvent: Identifiable {
    let id: UUID
    var title = ""
    var eventDescription = ""
    var location = ""
    var address: String?
    var startDate: Date
    var endDate: Date
    var eventType: String = EventType.social.rawValue
    var notes: String?
    var requiresTicket = false
    var requiresRegistration = false
    var url: String?
    var createdAt: Date
    var updatedAt: Date
    var isAttending = false
    var originalTimezoneIdentifier: String?
    var isCustomEvent = true
}

@Table
nonisolated struct StoredFriend: Identifiable {
    let id: UUID
    var name = ""
    var email: String?
    var phone: String?
    var jobTitle: String?
    var company: String?
    var socialMediaHandlesJSON = "{}"
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite = false
}

@Table
nonisolated struct StoredProfile: Identifiable {
    let id: UUID
    var name = ""
    var bio = ""
    var email: String?
    var phone: String?
    var profileImage: Data?
    var socialMediaAccountsJSON = "{}"
    var preferencesJSON = "{}"
    var createdAt: Date
    var updatedAt: Date
    var title = ""
    var company = ""
    var avatarSystemName = "person.crop.circle.fill"
}

@Table
nonisolated struct StoredEventAttendee: Identifiable {
    let id: String
    var eventID: UUID
    var friendID: UUID
}

@Table
nonisolated struct StoredEventWish: Identifiable {
    let id: String
    var eventID: UUID
    var friendID: UUID
}

enum EventBuddyDatabase {
    static let appGroupIdentifier = "group.com.buildwithharry.EventBuddy"
    static let cloudKitContainerIdentifier = "iCloud.com.buildwithharry.EventBuddy"

    static func makeDatabase(attachMetadatabase: Bool) throws -> any DatabaseWriter {
        @Dependency(\.context) var context

        var configuration = Configuration()
        configuration.prepareDatabase { db in
            if attachMetadatabase {
                try db.attachMetadatabase()
            }
            #if DEBUG
            db.trace(options: .profile) {
                logger.debug("\($0.expandedDescription)")
            }
            #endif
        }

        let database: any DatabaseWriter
        switch context {
        case .live:
            let databaseURL = try databaseURL()
            database = try DatabaseQueue(path: databaseURL.path, configuration: configuration)
            logger.info("Open database at \(databaseURL.path, privacy: .public)")
        default:
            let queue = try DatabaseQueue(configuration: configuration)
            logger.info("Open transient database for non-live context")
            database = queue
        }

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create SQLiteData tables") { db in
            try #sql(
                """
                CREATE TABLE "storedEvents" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "eventDescription" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "location" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "address" TEXT,
                  "startDate" TEXT NOT NULL ON CONFLICT REPLACE,
                  "endDate" TEXT NOT NULL ON CONFLICT REPLACE,
                  "eventType" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'Social',
                  "notes" TEXT,
                  "requiresTicket" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "requiresRegistration" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "url" TEXT,
                  "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "isAttending" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
                  "originalTimezoneIdentifier" TEXT,
                  "isCustomEvent" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 1
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "storedFriends" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "email" TEXT,
                  "phone" TEXT,
                  "jobTitle" TEXT,
                  "company" TEXT,
                  "socialMediaHandlesJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
                  "notes" TEXT,
                  "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "isFavorite" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "storedProfiles" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
                  "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "bio" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "email" TEXT,
                  "phone" TEXT,
                  "profileImage" BLOB,
                  "socialMediaAccountsJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
                  "preferencesJSON" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '{}',
                  "createdAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "updatedAt" TEXT NOT NULL ON CONFLICT REPLACE,
                  "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "company" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
                  "avatarSystemName" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT 'person.crop.circle.fill'
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "storedEventAttendees" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
                  "eventID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "storedEvents"("id") ON DELETE CASCADE,
                  "friendID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "storedFriends"("id") ON DELETE CASCADE
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "storedEventWishes" (
                  "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE,
                  "eventID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "storedEvents"("id") ON DELETE CASCADE,
                  "friendID" TEXT NOT NULL ON CONFLICT REPLACE REFERENCES "storedFriends"("id") ON DELETE CASCADE
                ) STRICT
                """
            )
            .execute(db)
        }

        try migrator.migrate(database)
        return database
    }

    static func bootstrap(enableSyncEngine: Bool) throws -> any DatabaseWriter {
        let database = try makeDatabase(attachMetadatabase: enableSyncEngine)
        try prepareDependencies {
            $0.defaultDatabase = database
            if enableSyncEngine {
                $0.defaultSyncEngine = try SyncEngine(
                    for: database,
                    tables: StoredEvent.self,
                    StoredFriend.self,
                    StoredProfile.self,
                    StoredEventAttendee.self,
                    StoredEventWish.self,
                    containerIdentifier: cloudKitContainerIdentifier
                )
            }
        }
        return database
    }

    static func databaseURL() throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return containerURL.appendingPathComponent("EventBuddy.sqlite")
    }

    static func attendeeRowID(eventID: UUID, friendID: UUID) -> String {
        "\(eventID.uuidString)|\(friendID.uuidString)"
    }

    static func wishRowID(eventID: UUID, friendID: UUID) -> String {
        "\(eventID.uuidString)|\(friendID.uuidString)"
    }
}

private let logger = Logger(subsystem: "EventBuddy", category: "Database")
