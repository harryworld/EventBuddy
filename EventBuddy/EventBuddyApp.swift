//
//  EventBuddyApp.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI
import UIKit
import WidgetKit

@main
struct EventBuddyApp: App {
    private let validationMode: MigrationValidationMode?
    private let eventPersistenceService: EventPersistenceService

    @State private var liveActivityService: LiveActivityService

    init() {
        let validationMode = MigrationValidationMode.current
        self.validationMode = validationMode

        UIDatePicker.appearance().minuteInterval = 5

        if let validationMode {
            try? validationMode.prepareForLaunch()
        }

        let shouldConfigureSyncEngine = validationMode?.shouldEnableSyncEngine ?? UserSettings.isCloudKitSyncFeatureEnabled
        let saveDidComplete: @MainActor () -> Void = {
            guard validationMode == nil else { return }
            CloudKitSyncPusher.schedulePushAfterLocalChange()
            WidgetCenter.shared.reloadEventBuddyTimelines()
        }
        _ = try? EventBuddyDatabase.bootstrap(
            configureSyncEngine: shouldConfigureSyncEngine,
            startSyncEngine: false
        )
        eventPersistenceService = EventPersistenceService(
            saveDidComplete: validationMode == nil ? saveDidComplete : {}
        )
        _liveActivityService = State(initialValue: LiveActivityService())
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(eventPersistenceService)
                .environment(liveActivityService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟢 App: Became active - checking for ongoing events")
                    
                    // Check for ongoing events and start Live Activity when app becomes foreground
                    Task { @MainActor in
                        liveActivityService.setPersistenceService(eventPersistenceService)
                        await liveActivityService.checkAndStartLiveActivityForOngoingEvents(persistenceService: eventPersistenceService)
                        // Force an immediate update to refresh the display
                        await liveActivityService.forceUpdate()
                    }
                    
                    // Refresh widgets when app becomes active
                    WidgetCenter.shared.reloadEventBuddyTimelines()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟡 App: Will resign active - checking for ongoing events to start Live Activity")
                    
                    // Start Live Activity for ongoing events when app goes to background
                    Task { @MainActor in
                        liveActivityService.setPersistenceService(eventPersistenceService)
                        await liveActivityService.handleAppEnteringBackground(persistenceService: eventPersistenceService)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟡 App: Entered background - ensuring Live Activity is active for ongoing events")
                    
                    // Double-check Live Activity is running for ongoing events
                    Task { @MainActor in
                        await liveActivityService.handleAppEnteringBackground(persistenceService: eventPersistenceService)
                    }
                    
                    // Refresh widgets when app goes to background
                    WidgetCenter.shared.reloadEventBuddyTimelines()
                }
        }
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

private extension WidgetCenter {
    func reloadEventBuddyTimelines() {
        reloadTimelines(ofKind: "EventBuddyWidget")
        reloadTimelines(ofKind: "QRCodeWidget")
    }
}
