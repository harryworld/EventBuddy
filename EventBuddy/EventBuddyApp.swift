//
//  EventBuddyApp.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct EventBuddyApp: App {
    init() {
        UIDatePicker.appearance().minuteInterval = 5
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(setupSwiftDataContainer())
    }
}
