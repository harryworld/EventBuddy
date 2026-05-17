import CloudKit
import Foundation
import SQLiteData

@MainActor
enum CloudKitSyncPusher {
    private static var pendingPushTask: Task<Void, Never>?
    private static var isPushing = false

    static func schedulePushAfterLocalChange() {
        guard UserSettings.storedCloudKitSyncEnabled() else { return }

        pendingPushTask?.cancel()
        pendingPushTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            await pushLocalChanges()
        }
    }

    static func pushLocalChanges() async {
        await sync()
    }

    static func syncAllChanges() async {
        await sync()
    }

    private static func sync() async {
        guard UserSettings.storedCloudKitSyncEnabled(), !isPushing else { return }

        isPushing = true
        defer { isPushing = false }

        do {
            let status = try await CKContainer(
                identifier: EventBuddyDatabase.cloudKitContainerIdentifier
            )
            .accountStatus()
            guard status == .available else { return }

            @Dependency(\.defaultSyncEngine) var syncEngine
            try await syncEngine.start()
            try await syncEngine.syncChanges()

            UserDefaults.standard.set(Date(), forKey: UserSettings.cloudKitLastSyncedAtKey)
            NotificationCenter.default.post(name: .eventBuddyCloudKitLastSyncedAtDidChange, object: nil)
        } catch {
            print("CloudKit sync push failed: \(error)")
        }
    }
}

extension Notification.Name {
    static let eventBuddyCloudKitLastSyncedAtDidChange = Notification.Name("EventBuddy.cloudKitLastSyncedAtDidChange")
}
