import Foundation
import CloudKit
import SQLiteData
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum PrivacyLevel: String, CaseIterable, Identifiable {
    case public_ = "public"
    case friendsOnly = "friendsOnly"
    case private_ = "private"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .public_: return "Public"
        case .friendsOnly: return "Friends Only"
        case .private_: return "Private"
        }
    }
    
    var icon: String {
        switch self {
        case .public_: return "globe"
        case .friendsOnly: return "person.2"
        case .private_: return "lock"
        }
    }
}

struct PrivacySettings {
    var profileVisibility: PrivacyLevel = .public_
    var eventsVisibility: PrivacyLevel = .public_
    var friendsListVisibility: PrivacyLevel = .friendsOnly
    var contactInfoVisibility: PrivacyLevel = .friendsOnly
}

enum CloudKitAccountAvailability: Equatable {
    case checking
    case available
    case unavailable(String)

    var canUseSync: Bool {
        self == .available
    }

    var description: String {
        switch self {
        case .checking:
            return "Checking..."
        case .available:
            return "Available"
        case let .unavailable(message):
            return message
        }
    }
}

@Observable class UserSettings {
    static var isCloudKitSyncFeatureEnabled: Bool {
        EventBuddyDatabase.canAccessCloudKitContainer
    }
    static let cloudKitSyncEnabledKey = EventBuddyStorageConfiguration.cloudKitSyncEnabledDefaultsKey
    static let cloudKitLastSyncedAtKey = "EventBuddy.UserSettings.cloudKitLastSyncedAt"

    @ObservationIgnored private let userDefaults: UserDefaults

    var notificationsEnabled: Bool = true
    var eventReminders: Bool = true
    var friendRequestNotifications: Bool = true
    var eventInviteNotifications: Bool = true
    var appTheme: AppTheme = .system
    var privacySettings: PrivacySettings = PrivacySettings()
    var cloudKitSyncEnabled: Bool {
        didSet {
            userDefaults.set(cloudKitSyncEnabled, forKey: Self.cloudKitSyncEnabledKey)
        }
    }
    var cloudKitLastSyncedAt: Date? {
        didSet {
            if let cloudKitLastSyncedAt {
                userDefaults.set(cloudKitLastSyncedAt, forKey: Self.cloudKitLastSyncedAtKey)
            } else {
                userDefaults.removeObject(forKey: Self.cloudKitLastSyncedAtKey)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.cloudKitSyncEnabled = Self.storedCloudKitSyncEnabled(in: userDefaults)
        self.cloudKitLastSyncedAt = userDefaults.object(forKey: Self.cloudKitLastSyncedAtKey) as? Date
    }

    static func storedCloudKitSyncEnabled(in userDefaults: UserDefaults = .standard) -> Bool {
        guard isCloudKitSyncFeatureEnabled else { return false }

        if let storedValue = userDefaults.object(forKey: cloudKitSyncEnabledKey) as? Bool {
            return storedValue
        }
        return false
    }

    // Add other settings as needed
}

@MainActor
@Observable class SettingsStore {
    @ObservationIgnored
    @Dependency(\.defaultSyncEngine) private var syncEngine
    @ObservationIgnored private var cloudKitLastSyncedObserver: NSObjectProtocol?

    var settings: UserSettings
    var cloudKitAccountAvailability: CloudKitAccountAvailability = .checking
    var cloudKitSyncError: String?
    var isUpdatingCloudKitSync = false
    
    init() {
        self.settings = UserSettings()
        self.cloudKitLastSyncedObserver = NotificationCenter.default.addObserver(
            forName: .eventBuddyCloudKitLastSyncedAtDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.markCloudKitSyncSucceeded()
            }
        }
    }

    deinit {
        if let cloudKitLastSyncedObserver {
            NotificationCenter.default.removeObserver(cloudKitLastSyncedObserver)
        }
    }
    
    func resetToDefaults() {
        settings = UserSettings()
    }

    var cloudKitLastSyncedDescription: String {
        guard let date = settings.cloudKitLastSyncedAt else {
            return "Not yet"
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var canToggleCloudKitSync: Bool {
        (settings.cloudKitSyncEnabled || cloudKitAccountAvailability.canUseSync) && !isUpdatingCloudKitSync
    }

    func reloadCloudKitLastSyncedAt() {
        settings.cloudKitLastSyncedAt = UserDefaults.standard.object(
            forKey: UserSettings.cloudKitLastSyncedAtKey
        ) as? Date
    }

    func markCloudKitSyncSucceeded() {
        reloadCloudKitLastSyncedAt()
        guard settings.cloudKitSyncEnabled else { return }

        cloudKitAccountAvailability = .available
        cloudKitSyncError = nil
    }

    func refreshCloudKitAccountAvailability() async {
        guard !isUpdatingCloudKitSync else { return }

        reloadCloudKitLastSyncedAt()

        guard UserSettings.isCloudKitSyncFeatureEnabled else {
            setCloudKitAccountUnavailable("iCloud unavailable in this build", disablesSync: true)
            return
        }

        cloudKitAccountAvailability = .checking

        do {
            let status = try await CKContainer(
                identifier: EventBuddyDatabase.cloudKitContainerIdentifier
            )
            .accountStatus()
            guard !isUpdatingCloudKitSync else { return }
            updateCloudKitAccountAvailability(for: status)
        } catch {
            guard !isUpdatingCloudKitSync else { return }
            setCloudKitAccountUnavailable("iCloud account status unavailable")
        }
    }

    func setCloudKitSyncEnabled(_ isEnabled: Bool) {
        guard UserSettings.isCloudKitSyncFeatureEnabled else {
            settings.cloudKitSyncEnabled = false
            cloudKitSyncError = nil
            syncEngine.stop()
            return
        }

        guard settings.cloudKitSyncEnabled != isEnabled else { return }
        cloudKitSyncError = nil

        guard !isEnabled || cloudKitAccountAvailability.canUseSync else {
            settings.cloudKitSyncEnabled = false
            cloudKitSyncError = cloudKitAccountAvailability.description
            syncEngine.stop()
            return
        }

        settings.cloudKitSyncEnabled = isEnabled

        if isEnabled {
            Task {
                await syncCloudKitIfEnabled()
            }
        } else {
            syncEngine.stop()
        }
    }

    func syncCloudKitIfEnabled() async {
        guard UserSettings.isCloudKitSyncFeatureEnabled, settings.cloudKitSyncEnabled, !isUpdatingCloudKitSync else {
            if !UserSettings.isCloudKitSyncFeatureEnabled {
                setCloudKitAccountUnavailable("iCloud unavailable in this build", disablesSync: true)
            }
            return
        }

        isUpdatingCloudKitSync = true
        defer { isUpdatingCloudKitSync = false }

        do {
            try await syncEngine.start()
        } catch {
            print("iCloud sync could not start: \(error)")
            settings.cloudKitSyncEnabled = false
            syncEngine.stop()
            cloudKitSyncError = "iCloud sync could not start. Check iCloud availability and try again."
            return
        }

        do {
            try await syncEngine.syncChanges()
        } catch {
            print("iCloud sync request failed; automatic sync remains enabled: \(error)")
        }

        settings.cloudKitLastSyncedAt = Date()
        NotificationCenter.default.post(name: .eventBuddyCloudKitLastSyncedAtDidChange, object: nil)
        cloudKitAccountAvailability = .available
        cloudKitSyncError = nil
    }

    private func updateCloudKitAccountAvailability(for status: CKAccountStatus) {
        switch status {
        case .available:
            cloudKitAccountAvailability = .available
            cloudKitSyncError = nil
        case .noAccount:
            setCloudKitAccountUnavailable("Sign in to iCloud")
        case .restricted:
            setCloudKitAccountUnavailable("iCloud is restricted")
        case .couldNotDetermine:
            setCloudKitAccountUnavailable("Could not determine iCloud status")
        case .temporarilyUnavailable:
            setCloudKitAccountUnavailable("iCloud is temporarily unavailable")
        @unknown default:
            setCloudKitAccountUnavailable("iCloud account unavailable")
        }
    }

    private func setCloudKitAccountUnavailable(_ message: String, disablesSync: Bool = false) {
        cloudKitAccountAvailability = .unavailable(message)
        if disablesSync, settings.cloudKitSyncEnabled {
            settings.cloudKitSyncEnabled = false
            syncEngine.stop()
        }
    }
}
