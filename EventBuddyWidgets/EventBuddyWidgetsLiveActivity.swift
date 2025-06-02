//
//  EventBuddyWidgetsLiveActivity.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

//struct EventBuddyWidgetsAttributes: ActivityAttributes {
//    public struct ContentState: Codable, Hashable {
//        var eventStatus: String
//        var timeRemaining: String
//        var progress: Double
//    }
//    
//    var eventName: String
//    var location: String
//}

struct EventBuddyWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EventBuddyWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.attributes.eventName)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(context.attributes.location)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 8)
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(context.state.eventStatus)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.blue)
                        Text(context.state.timeRemaining)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                    }
                }
                
                // Progress bar with better styling
                VStack(spacing: 4) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 6)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(3)
                    
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.eventName)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .lineLimit(2)
                        HStack(spacing: 2) {
                            Image(systemName: "location")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(context.attributes.location)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.eventStatus)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(.blue)
                        Text(context.state.timeRemaining)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        ProgressView(value: context.state.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                        Text("\(Int(context.state.progress * 100))% complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.timeRemaining)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "eventbuddy://event"))
            .keylineTint(Color.accentColor)
        }
    }
}

extension EventBuddyWidgetsAttributes {
    fileprivate static var preview: EventBuddyWidgetsAttributes {
        EventBuddyWidgetsAttributes(
            eventName: "WWDC25 Keynote",
            location: "Apple Park"
        )
    }
}

extension EventBuddyWidgetsAttributes.ContentState {
    fileprivate static var starting: EventBuddyWidgetsAttributes.ContentState {
        EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Starting Soon",
            timeRemaining: "5 min",
            progress: 0.0
        )
     }
     
     fileprivate static var inProgress: EventBuddyWidgetsAttributes.ContentState {
         EventBuddyWidgetsAttributes.ContentState(
             eventStatus: "In Progress",
             timeRemaining: "45 min left",
             progress: 0.6
         )
     }
}

#Preview("Notification", as: .content, using: EventBuddyWidgetsAttributes.preview) {
   EventBuddyWidgetsLiveActivity()
} contentStates: {
    EventBuddyWidgetsAttributes.ContentState.starting
    EventBuddyWidgetsAttributes.ContentState.inProgress
}
