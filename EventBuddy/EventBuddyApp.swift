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
    init() {
        UIDatePicker.appearance().minuteInterval = 5
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Refresh widgets when app becomes active
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(setupSwiftDataContainer())
    }

}
