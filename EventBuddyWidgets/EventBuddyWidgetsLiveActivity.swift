//
//  EventBuddyWidgetsLiveActivity.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EventBuddyWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct EventBuddyWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EventBuddyWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension EventBuddyWidgetsAttributes {
    fileprivate static var preview: EventBuddyWidgetsAttributes {
        EventBuddyWidgetsAttributes(name: "World")
    }
}

extension EventBuddyWidgetsAttributes.ContentState {
    fileprivate static var smiley: EventBuddyWidgetsAttributes.ContentState {
        EventBuddyWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: EventBuddyWidgetsAttributes.ContentState {
         EventBuddyWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: EventBuddyWidgetsAttributes.preview) {
   EventBuddyWidgetsLiveActivity()
} contentStates: {
    EventBuddyWidgetsAttributes.ContentState.smiley
    EventBuddyWidgetsAttributes.ContentState.starEyes
}
