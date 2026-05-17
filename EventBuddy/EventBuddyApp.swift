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

    @State private var appEnvironment: AppEnvironment
    @State private var liveActivityService: LiveActivityService

    init() {
        let validationMode = MigrationValidationMode.current
        self.validationMode = validationMode

        UIDatePicker.appearance().minuteInterval = 5

        if let validationMode {
            try? validationMode.prepareForLaunch()
        }

        _ = try? EventBuddyDatabase.bootstrap(enableSyncEngine: validationMode?.shouldEnableSyncEngine ?? true)
        _appEnvironment = State(initialValue: AppEnvironment())
        _liveActivityService = State(initialValue: LiveActivityService())
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(appEnvironment.store)
                .environment(\.modelContext, appEnvironment.modelContext)
                .environment(liveActivityService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟢 App: Became active - checking for ongoing events")
                    
                    // Check for ongoing events and start Live Activity when app becomes foreground
                    Task { @MainActor in
                        try? appEnvironment.modelContext.reload()
                        liveActivityService.setModelContext(appEnvironment.modelContext)
                        await liveActivityService.checkAndStartLiveActivityForOngoingEvents(modelContext: appEnvironment.modelContext)
                        // Force an immediate update to refresh the display
                        await liveActivityService.forceUpdate()
                    }
                    
                    // Refresh widgets when app becomes active
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟡 App: Will resign active - checking for ongoing events to start Live Activity")
                    
                    // Start Live Activity for ongoing events when app goes to background
                    Task { @MainActor in
                        liveActivityService.setModelContext(appEnvironment.modelContext)
                        await liveActivityService.handleAppEnteringBackground(modelContext: appEnvironment.modelContext)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    guard validationMode == nil else { return }
                    print("🟡 App: Entered background - ensuring Live Activity is active for ongoing events")
                    
                    // Double-check Live Activity is running for ongoing events
                    Task { @MainActor in
                        await liveActivityService.handleAppEnteringBackground(modelContext: appEnvironment.modelContext)
                    }
                    
                    // Refresh widgets when app goes to background
                    WidgetCenter.shared.reloadAllTimelines()
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
