//
//  EventBuddyApp.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI
#if os(iOS)
import UIKit
import WidgetKit
#elseif os(macOS)
import AppKit
#endif

@main
struct EventBuddyApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(EventBuddyMacAppDelegate.self) private var macAppDelegate
    #endif

    private let validationMode: MigrationValidationMode?
    private let eventPersistenceService: EventPersistenceService
    #if os(macOS)
    private let cliCommandProcessor: EventBuddyCLICommandProcessor
    #endif

    @State private var liveActivityService: LiveActivityService

    init() {
        let validationMode = MigrationValidationMode.current
        self.validationMode = validationMode

        #if os(iOS)
        UIDatePicker.appearance().minuteInterval = 5
        #endif

        if let validationMode {
            try? validationMode.prepareForLaunch()
        }

        let shouldConfigureSyncEngine = validationMode?.shouldEnableSyncEngine ?? UserSettings.isCloudKitSyncFeatureEnabled
        let saveDidComplete: @MainActor () -> Void = {
            guard validationMode == nil else { return }
            CloudKitSyncPusher.schedulePushAfterLocalChange()
            #if os(iOS)
            WidgetCenter.shared.reloadEventBuddyTimelines()
            #endif
        }
        do {
            _ = try EventBuddyDatabase.bootstrap(
                configureSyncEngine: shouldConfigureSyncEngine,
                startSyncEngine: false
            )
        } catch {
            fatalError("Unable to open the WWDCBuddy app-group database: \(error)")
        }
        let eventPersistenceService = EventPersistenceService(
            saveDidComplete: validationMode == nil ? saveDidComplete : {}
        )
        self.eventPersistenceService = eventPersistenceService
        #if os(macOS)
        cliCommandProcessor = EventBuddyCLICommandProcessor(persistenceService: eventPersistenceService)
        if validationMode == nil {
            cliCommandProcessor.start()
        }
        #endif
        _liveActivityService = State(initialValue: LiveActivityService())
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(eventPersistenceService)
                .environment(liveActivityService)
                .modifier(EventBuddyLifecycleModifier(
                    validationMode: validationMode,
                    eventPersistenceService: eventPersistenceService,
                    liveActivityService: liveActivityService
                ))
        }
        #if os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }

    @ViewBuilder
    private var rootView: some View {
        if let validationMode {
            MigrationValidationView(mode: validationMode)
        } else {
            ContentView()
        }
    }
}

#if os(iOS)
private struct EventBuddyLifecycleModifier: ViewModifier {
    let validationMode: MigrationValidationMode?
    let eventPersistenceService: EventPersistenceService
    let liveActivityService: LiveActivityService

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                guard validationMode == nil else { return }
                print("🟢 App: Became active - checking for ongoing events")

                Task { @MainActor in
                    liveActivityService.setPersistenceService(eventPersistenceService)
                    await liveActivityService.checkAndStartLiveActivityForOngoingEvents(persistenceService: eventPersistenceService)
                    await liveActivityService.forceUpdate()
                }

                WidgetCenter.shared.reloadEventBuddyTimelines()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                guard validationMode == nil else { return }
                print("🟡 App: Will resign active - checking for ongoing events to start Live Activity")

                Task { @MainActor in
                    liveActivityService.setPersistenceService(eventPersistenceService)
                    await liveActivityService.handleAppEnteringBackground(persistenceService: eventPersistenceService)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                guard validationMode == nil else { return }
                print("🟡 App: Entered background - ensuring Live Activity is active for ongoing events")

                Task { @MainActor in
                    await liveActivityService.handleAppEnteringBackground(persistenceService: eventPersistenceService)
                }

                WidgetCenter.shared.reloadEventBuddyTimelines()
            }
    }
}

private extension WidgetCenter {
    func reloadEventBuddyTimelines() {
        reloadTimelines(ofKind: "EventBuddyWidget")
        reloadTimelines(ofKind: "QRCodeWidget")
    }
}
#else
@MainActor
private final class EventBuddyMacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard UserSettings.isCloudKitSyncFeatureEnabled else { return }
        NSApplication.shared.registerForRemoteNotifications()
    }

    func application(
        _ application: NSApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("Registered for remote notifications")
    }

    func application(
        _ application: NSApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(
        _ application: NSApplication,
        didReceiveRemoteNotification userInfo: [String: Any]
    ) {
        Task { @MainActor in
            await CloudKitSyncPusher.syncAllChanges()
        }
    }
}

private struct EventBuddyLifecycleModifier: ViewModifier {
    init(
        validationMode: MigrationValidationMode?,
        eventPersistenceService: EventPersistenceService,
        liveActivityService: LiveActivityService
    ) {}

    func body(content: Content) -> some View {
        content
    }
}
#endif
