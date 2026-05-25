import Foundation
import OSLog
#if os(macOS)
import Security
#endif
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
    static let appGroupIdentifier = EventBuddyStorageConfiguration.appGroupIdentifier
    static let cloudKitContainerIdentifier = EventBuddyStorageConfiguration.cloudKitContainerIdentifier

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
        let migrationBackup: SQLiteDataStoreMigrationBackup.Handle?
        switch context {
        case .live:
            let databaseURL = try databaseURL()
            migrationBackup = try SQLiteDataStoreMigrationBackup.createIfNeeded(databaseURL: databaseURL)
            database = try DatabaseQueue(path: databaseURL.path, configuration: configuration)
            logger.info("Open database at \(databaseURL.path, privacy: .public)")
        default:
            migrationBackup = nil
            let queue = try DatabaseQueue(configuration: configuration)
            logger.info("Open transient database for non-live context")
            database = queue
        }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create SQLiteData tables") { db in
            try createSQLiteDataTablesIfNeeded(in: db)
        }

        migrator.registerMigration("Repair missing SQLiteData tables") { db in
            try createSQLiteDataTablesIfNeeded(in: db)
        }

        try migrator.migrate(database)
        try database.write { db in
            try createSQLiteDataTablesIfNeeded(in: db)
        }
        try migrationBackup?.finish(database: database)
        return database
    }

    static func bootstrap(configureSyncEngine: Bool, startSyncEngine: Bool = true) throws -> any DatabaseWriter {
        let database: any DatabaseWriter
        var shouldConfigureSyncEngine = configureSyncEngine

        do {
            database = try makeDatabase(attachMetadatabase: configureSyncEngine)
        } catch {
            guard configureSyncEngine else { throw error }
            let message = String(describing: error)
            logger.error("CloudKit database bootstrap failed; opening local database without sync metadata: \(message, privacy: .public)")
            UserDefaults.standard.set(false, forKey: EventBuddyStorageConfiguration.cloudKitSyncEnabledDefaultsKey)
            database = try makeDatabase(attachMetadatabase: false)
            shouldConfigureSyncEngine = false
        }

        prepareDependencies {
            $0.defaultDatabase = database
        }

        if shouldConfigureSyncEngine {
            do {
                let syncEngine = try SyncEngine(
                    for: database,
                    tables: StoredEvent.self,
                    StoredFriend.self,
                    StoredProfile.self,
                    StoredEventAttendee.self,
                    StoredEventWish.self,
                    containerIdentifier: cloudKitContainerIdentifier,
                    startImmediately: startSyncEngine
                )
                prepareDependencies {
                    $0.defaultSyncEngine = syncEngine
                }
            } catch {
                let message = String(describing: error)
                logger.error("CloudKit sync engine bootstrap failed; local SQLite database remains available: \(message, privacy: .public)")
                UserDefaults.standard.set(false, forKey: EventBuddyStorageConfiguration.cloudKitSyncEnabledDefaultsKey)
            }
        }
        return database
    }

    static func databaseURL() throws -> URL {
        #if os(macOS)
        guard canAccessAppGroupContainer else {
            return try applicationSupportDatabaseURL()
        }
        #endif

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return containerURL.appendingPathComponent(EventBuddyStorageConfiguration.databaseFileName)
    }

    #if os(macOS)
    static var canAccessCloudKitContainer: Bool {
        guard let task = SecTaskCreateFromSelf(nil),
              let entitlement = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.developer.icloud-container-identifiers" as CFString,
                nil
              ) else {
            return false
        }

        guard let containers = entitlement as? [String] else { return false }
        return containers.contains(cloudKitContainerIdentifier)
    }

    static var canAccessAppGroupContainer: Bool {
        guard let task = SecTaskCreateFromSelf(nil),
              let entitlement = SecTaskCopyValueForEntitlement(
                task,
                "com.apple.security.application-groups" as CFString,
                nil
              ) else {
            return false
        }

        guard let groups = entitlement as? [String] else { return false }
        return groups.contains(appGroupIdentifier)
    }

    private static func applicationSupportDatabaseURL() throws -> URL {
        let directory = try FileManager.default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("WWDCBuddy", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(EventBuddyStorageConfiguration.databaseFileName)
    }
    #else
    static var canAccessCloudKitContainer: Bool {
        true
    }
    #endif

    static func attendeeRowID(eventID: UUID, friendID: UUID) -> String {
        "\(eventID.uuidString)|\(friendID.uuidString)"
    }

    static func wishRowID(eventID: UUID, friendID: UUID) -> String {
        "\(eventID.uuidString)|\(friendID.uuidString)"
    }

    private static func createSQLiteDataTablesIfNeeded(in db: Database) throws {
        try db.execute(sql: EventBuddyStorageConfiguration.createStoredEventsTableSQL)
        try db.execute(sql: EventBuddyStorageConfiguration.createStoredFriendsTableSQL)
        try db.execute(sql: EventBuddyStorageConfiguration.createStoredProfilesTableSQL)
        try db.execute(sql: EventBuddyStorageConfiguration.createStoredEventAttendeesTableSQL)
        try db.execute(sql: EventBuddyStorageConfiguration.createStoredEventWishesTableSQL)
    }
}

private let logger = Logger(subsystem: "EventBuddy", category: "Database")

private enum SQLiteDataStoreMigrationBackup {
    private static let lastBackupBuildKey = "EventBuddy.SQLiteDataStoreMigrationBackup.lastBuild"

    struct Handle {
        let createdAt: Date
        let directoryURL: URL
        let manifestURL: URL
        let sourceDatabasePath: String
        let copiedFiles: [String]
        let appVersion: String
        let buildNumber: String
        let preMigrationCounts: SQLiteDataStoreCounts?

        func finish(database: any DatabaseWriter) throws {
            let postMigrationCounts = try? database.read { db in
                try SQLiteDataStoreMigrationBackup.counts(in: db)
            }
            let manifest = SQLiteDataStoreBackupManifest(
                createdAt: createdAt,
                completedAt: Date(),
                appVersion: appVersion,
                buildNumber: buildNumber,
                sourceDatabasePath: sourceDatabasePath,
                copiedFiles: copiedFiles,
                preMigrationCounts: preMigrationCounts,
                postMigrationCounts: postMigrationCounts,
                status: "completed"
            )
            try SQLiteDataStoreMigrationBackup.write(manifest, to: manifestURL)
        }
    }

    static func createIfNeeded(databaseURL: URL) throws -> Handle? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: databaseURL.path) else { return nil }

        let appVersion = Bundle.main.eventBuddyVersionString
        let buildNumber = Bundle.main.eventBuddyBuildString
        let buildIdentifier = "\(appVersion)-\(buildNumber)"
        guard UserDefaults.standard.string(forKey: lastBackupBuildKey) != buildIdentifier else {
            return nil
        }

        let createdAt = Date()
        let directoryURL = try backupRootURL(for: databaseURL)
            .appendingPathComponent("SQLiteData-\(buildIdentifier.fileSystemSafe)-\(Self.timestamp.string(from: createdAt))")
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let copiedFiles = try copyDatabaseFiles(from: databaseURL, to: directoryURL)
        let backupDatabaseURL = directoryURL.appendingPathComponent(databaseURL.lastPathComponent)
        let preMigrationCounts = try? counts(inDatabaseAt: backupDatabaseURL)
        let manifestURL = directoryURL.appendingPathComponent("migration_audit.json")

        let manifest = SQLiteDataStoreBackupManifest(
            createdAt: createdAt,
            completedAt: nil,
            appVersion: appVersion,
            buildNumber: buildNumber,
            sourceDatabasePath: databaseURL.path,
            copiedFiles: copiedFiles,
            preMigrationCounts: preMigrationCounts,
            postMigrationCounts: nil,
            status: "started"
        )
        try write(manifest, to: manifestURL)

        UserDefaults.standard.set(buildIdentifier, forKey: lastBackupBuildKey)

        return Handle(
            createdAt: createdAt,
            directoryURL: directoryURL,
            manifestURL: manifestURL,
            sourceDatabasePath: databaseURL.path,
            copiedFiles: copiedFiles,
            appVersion: appVersion,
            buildNumber: buildNumber,
            preMigrationCounts: preMigrationCounts
        )
    }

    private static func backupRootURL(for databaseURL: URL) throws -> URL {
        let url = databaseURL
            .deletingLastPathComponent()
            .appendingPathComponent("SQLiteDataMigrationBackups", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func copyDatabaseFiles(from databaseURL: URL, to directoryURL: URL) throws -> [String] {
        let fileManager = FileManager.default
        var copiedFiles: [String] = []

        for suffix in ["", "-wal", "-shm"] {
            let sourceURL = URL(fileURLWithPath: databaseURL.path + suffix)
            guard fileManager.fileExists(atPath: sourceURL.path) else { continue }

            let destinationURL = directoryURL.appendingPathComponent(sourceURL.lastPathComponent)
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            copiedFiles.append(destinationURL.lastPathComponent)
        }

        return copiedFiles
    }

    private static func counts(inDatabaseAt databaseURL: URL) throws -> SQLiteDataStoreCounts {
        let queue = try DatabaseQueue(path: databaseURL.path)
        return try queue.read { db in
            try counts(in: db)
        }
    }

    private static func counts(in db: Database) throws -> SQLiteDataStoreCounts {
        try SQLiteDataStoreCounts(
            events: countRows(in: "storedEvents", db: db),
            friends: countRows(in: "storedFriends", db: db),
            profiles: countRows(in: "storedProfiles", db: db),
            attendeeLinks: countRows(in: "storedEventAttendees", db: db),
            wishLinks: countRows(in: "storedEventWishes", db: db)
        )
    }

    private static func countRows(in tableName: String, db: Database) throws -> Int {
        guard try db.tableExists(tableName) else { return 0 }
        return try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "\#(tableName)""#) ?? 0
    }

    private static func write(_ manifest: SQLiteDataStoreBackupManifest, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: url, options: .atomic)
    }

    private static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

private struct SQLiteDataStoreBackupManifest: Codable {
    let createdAt: Date
    let completedAt: Date?
    let appVersion: String
    let buildNumber: String
    let sourceDatabasePath: String
    let copiedFiles: [String]
    let preMigrationCounts: SQLiteDataStoreCounts?
    let postMigrationCounts: SQLiteDataStoreCounts?
    let status: String
}

private struct SQLiteDataStoreCounts: Codable {
    let events: Int
    let friends: Int
    let profiles: Int
    let attendeeLinks: Int
    let wishLinks: Int
}

private extension Bundle {
    var eventBuddyVersionString: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    var eventBuddyBuildString: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }
}

private extension String {
    var fileSystemSafe: String {
        components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
