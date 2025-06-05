//
//  EventBuddyApp.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI
import SwiftData
import UIKit
import WidgetKit

@main
struct EventBuddyApp: App {
    @State private var liveActivityService = LiveActivityService()
    
    init() {
        UIDatePicker.appearance().minuteInterval = 5
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(liveActivityService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("🟢 App: Became active - checking for ongoing events")
                    
                    // Check for ongoing events and start Live Activity when app becomes foreground
                    Task { @MainActor in
                        let container = setupSwiftDataContainer()
                        let modelContext = container.mainContext
                        liveActivityService.setModelContext(modelContext)
                        await liveActivityService.checkAndStartLiveActivityForOngoingEvents(modelContext: modelContext)
                        // Force an immediate update to refresh the display
                        await liveActivityService.forceUpdate()
                    }
                    
                    // Refresh widgets when app becomes active
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    print("🟡 App: Will resign active - checking for ongoing events to start Live Activity")
                    
                    // Start Live Activity for ongoing events when app goes to background
                    Task { @MainActor in
                        let container = setupSwiftDataContainer()
                        let modelContext = container.mainContext
                        liveActivityService.setModelContext(modelContext)
                        await liveActivityService.handleAppEnteringBackground(modelContext: modelContext)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    print("🟡 App: Entered background - ensuring Live Activity is active for ongoing events")
                    
                    // Double-check Live Activity is running for ongoing events
                    Task { @MainActor in
                        let container = setupSwiftDataContainer()
                        let modelContext = container.mainContext
                        await liveActivityService.handleAppEnteringBackground(modelContext: modelContext)
                    }
                    
                    // Refresh widgets when app goes to background
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(setupSwiftDataContainer())
    }
}
