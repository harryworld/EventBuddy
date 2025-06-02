//
//  EventBuddyWidgetsAttributes.swift
//  EventBuddy
//
//  Created by Harry Ng on 2/6/2025.
//

import ActivityKit

struct EventBuddyWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var eventStatus: String
        var timeRemaining: String
        var progress: Double // 0.0 to 1.0
    }

    // Fixed non-changing properties about your activity go here!
    var eventName: String
    var location: String
}

