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

    // Helper function for lock screen/banner (standard font)
    @ViewBuilder
    private func createTimerText(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> some View {
        let now = currentDate
        
        if now < eventStartDate {
            Text(timerInterval: now...eventStartDate, countsDown: true)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else if now <= eventEndDate {
            Text(timerInterval: now...eventEndDate, countsDown: true)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else {
            Text("Ended")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
    
    // Helper function for Dynamic Island expanded region (medium font)
    @ViewBuilder
    private func createTimerTextExpanded(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> some View {
        let now = currentDate
        
        if now < eventStartDate {
            Text(timerInterval: now...eventStartDate, countsDown: true)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else if now <= eventEndDate {
            Text(timerInterval: now...eventEndDate, countsDown: true)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else {
            Text("Ended")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
    
    // Helper function for Dynamic Island compact region (smallest font)
    @ViewBuilder
    private func createTimerTextCompact(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> some View {
        let now = currentDate
        
        if now < eventStartDate {
            Text(timerInterval: now...eventStartDate, countsDown: true)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else if now <= eventEndDate {
            Text(timerInterval: now...eventEndDate, countsDown: true)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .monospacedDigit()
        } else {
            Text("Ended")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .monospacedDigit()
        }
    }
    
    // Helper function to create timer-based progress view
    @ViewBuilder
    private func createTimerProgressView(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> some View {
        let now = currentDate
        
        if now < eventStartDate {
            // Event hasn't started - show minimal progress
            ProgressView(value: 0.05)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 6)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(3)
        } else if now <= eventEndDate {
            // Event is in progress - use timer interval for automatic progress countdown
            ProgressView(timerInterval: eventStartDate...eventEndDate, countsDown: true) {
                // No label
            } currentValueLabel: {
                // No current value label - we'll show percentage separately
            }
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            .frame(height: 6)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(3)
        } else {
            // Event has ended - show full progress
            ProgressView(value: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 6)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(3)
        }
    }
    
    // Helper function to create timer-based progress view for Dynamic Island (smaller)
    @ViewBuilder
    private func createTimerProgressViewCompact(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> some View {
        let now = currentDate
        
        if now < eventStartDate {
            // Event hasn't started - show minimal progress
            ProgressView(value: 0.05)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 4)
        } else if now <= eventEndDate {
            // Event is in progress - use timer interval for automatic progress countdown
            ProgressView(timerInterval: eventStartDate...eventEndDate, countsDown: true) {
                // No label
            } currentValueLabel: {
                // No current value label
            }
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            .frame(height: 4)
        } else {
            // Event has ended - show full progress
            ProgressView(value: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(height: 4)
        }
    }
    
    // Helper function to calculate current progress percentage for display
    private func calculateCurrentProgress(currentDate: Date = Date(), eventStartDate: Date, eventEndDate: Date) -> Int {
        let now = currentDate
        
        if now < eventStartDate {
            return 5 // Show 5% before event starts
        } else if now <= eventEndDate {
            let totalDuration = eventEndDate.timeIntervalSince(eventStartDate)
            let elapsed = now.timeIntervalSince(eventStartDate)
            let progress = elapsed / totalDuration
            return Int(min(max(progress * 100, 5), 100))
        } else {
            return 100 // Event completed
        }
    }
    
    // Helper function to create deep link URL for event detail
    private func createEventURL(from attributes: EventBuddyWidgetsAttributes) -> URL {
        // Use the event ID for accurate deep linking
        return URL(string: "eventbuddy://event/\(attributes.eventId)") ?? URL(string: "eventbuddy://events")!
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EventBuddyWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack(spacing: 12) {
                // Main content with icon and event info
                HStack(spacing: 12) {
                    // Event icon
                    Image(systemName: "calendar.badge.clock")
                        .font(.title2)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        // Event title
                        Text(context.attributes.eventName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Location
                        Text(context.attributes.location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        // Status
                        Text(context.state.eventStatus)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Countdown timer on far right
                    createTimerText(eventStartDate: context.state.eventStartDate,
                                   eventEndDate: context.state.eventEndDate)
                }
                
                // Progress bar with better styling
                VStack(spacing: 4) {
                    createTimerProgressView(eventStartDate: context.state.eventStartDate,
                                           eventEndDate: context.state.eventEndDate)
                    
                    HStack {
                        Text("Progress")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(calculateCurrentProgress(eventStartDate: context.state.eventStartDate, eventEndDate: context.state.eventEndDate))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .padding()
            .activityBackgroundTint(.clear)
            .activitySystemActionForegroundColor(.primary)
            .contentTransition(.numericText())
            .widgetURL(createEventURL(from: context.attributes))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.eventName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(context.state.eventStatus)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        // Countdown timer prominently displayed
                        createTimerTextExpanded(eventStartDate: context.state.eventStartDate,
                                              eventEndDate: context.state.eventEndDate)
                        
                        // Location below timer
                        Text(context.attributes.location)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        createTimerProgressViewCompact(eventStartDate: context.state.eventStartDate,
                                                      eventEndDate: context.state.eventEndDate)
                        Text("\(calculateCurrentProgress(eventStartDate: context.state.eventStartDate, eventEndDate: context.state.eventEndDate))% complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            } compactTrailing: {
                createTimerTextCompact(eventStartDate: context.state.eventStartDate,
                                      eventEndDate: context.state.eventEndDate)
            } minimal: {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            .widgetURL(createEventURL(from: context.attributes))
            .keylineTint(Color.accentColor)
        }
    }
}

extension EventBuddyWidgetsAttributes {
    fileprivate static var preview: EventBuddyWidgetsAttributes {
        EventBuddyWidgetsAttributes(
            eventName: "WWDC25 Keynote",
            location: "Apple Park",
            eventId: UUID().uuidString
        )
    }
}

extension EventBuddyWidgetsAttributes.ContentState {
    fileprivate static var ساعتين_قبل_البدء: Date { Date().addingTimeInterval(-7200) }
    fileprivate static var ساعة_قبل_البدء: Date { Date().addingTimeInterval(-3600) }
    fileprivate static var الآن: Date { Date() }
    fileprivate static var بعد_ساعة: Date { Date().addingTimeInterval(3600) }
    fileprivate static var بعد_ساعتين: Date { Date().addingTimeInterval(7200) }

    fileprivate static var starting: EventBuddyWidgetsAttributes.ContentState {
        EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Starting Soon",
            timeRemaining: "5 min to start", // Example, will be replaced by TimelineView
            progress: 0.05,
            eventStartDate: الآن.addingTimeInterval(300), // Event starts in 5 minutes
            eventEndDate: الآن.addingTimeInterval(300 + 3600) // Event ends 1 hour after starting
        )
     }
     
     fileprivate static var inProgress: EventBuddyWidgetsAttributes.ContentState {
         EventBuddyWidgetsAttributes.ContentState(
             eventStatus: "In Progress",
             timeRemaining: "45 min left", // Example, will be replaced by TimelineView
             progress: 0.25, // Example: 15 mins into a 1-hour event
             eventStartDate: الآن.addingTimeInterval(-900), // Event started 15 minutes ago
             eventEndDate: الآن.addingTimeInterval(-900 + 3600) // Event ends in 45 minutes
         )
     }

    fileprivate static var endingSoon: EventBuddyWidgetsAttributes.ContentState {
        EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Ending Soon",
            timeRemaining: "2m 30s left", // Example
            progress: 0.95,
            eventStartDate: الآن.addingTimeInterval(-3600 + 150), // Event started ~57m ago, ends in 2.5m
            eventEndDate: الآن.addingTimeInterval(150) // Event ends in 2.5 minutes
        )
    }

    fileprivate static var ended: EventBuddyWidgetsAttributes.ContentState {
        EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Event Ended",
            timeRemaining: "Completed",
            progress: 1.0,
            eventStartDate: ساعة_قبل_البدء, // Event was 1 hour ago
            eventEndDate: الآن // Event just ended
        )
    }
}

#Preview("Notification", as: .content, using: EventBuddyWidgetsAttributes.preview) {
   EventBuddyWidgetsLiveActivity()
} contentStates: {
    EventBuddyWidgetsAttributes.ContentState.starting
    EventBuddyWidgetsAttributes.ContentState.inProgress
    EventBuddyWidgetsAttributes.ContentState.endingSoon
    EventBuddyWidgetsAttributes.ContentState.ended
}
