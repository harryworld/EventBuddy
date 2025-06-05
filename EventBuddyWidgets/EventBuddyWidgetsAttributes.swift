//
//  EventBuddyWidgetsAttributes.swift
//  EventBuddy
//
//  Created by Harry Ng on 2/6/2025.
//

import ActivityKit
import Foundation // Added for Date type

struct EventBuddyWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var eventStatus: String
        var timeRemaining: String // This can be a fallback or supplementary
        var progress: Double // 0.0 to 1.0
        var eventStartDate: Date
        var eventEndDate: Date
    }

    // Fixed non-changing properties about your activity go here!
    var eventName: String
    var location: String
    var eventId: String // UUID string for deep linking
}

