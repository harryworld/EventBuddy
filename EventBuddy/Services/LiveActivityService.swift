import ActivityKit
import Foundation

@Observable
class LiveActivityService {
    private var currentActivity: Activity<EventBuddyWidgetsAttributes>?
    
    func startLiveActivity(for event: Event) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        await endCurrentActivity()
        
        let attributes = EventBuddyWidgetsAttributes(
            eventName: event.title,
            location: event.location
        )
        
        let timeRemaining = timeUntilStartString(for: event.startDate)
        let eventStatus = event.startDate > Date() ? "Starting Soon" : "In Progress"
        let progress = calculateProgress(for: event)
        
        let initialState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: eventStatus,
            timeRemaining: timeRemaining,
            progress: progress
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            currentActivity = activity
            print("Live Activity started for event: \(event.title)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Event Started",
            timeRemaining: "Now",
            progress: 1.0
        )
        
        await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        currentActivity = nil
    }
    
    private func timeUntilStartString(for startDate: Date) -> String {
        let now = Date()
        let timeInterval = startDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculateProgress(for event: Event) -> Double {
        let now = Date()
        
        // If event hasn't started yet, progress is 0
        if now < event.startDate {
            return 0.0
        }
        
        // If event has ended, progress is 1
        if now > event.endDate {
            return 1.0
        }
        
        // Calculate progress based on how much of the event has elapsed
        let totalDuration = event.endDate.timeIntervalSince(event.startDate)
        let elapsed = now.timeIntervalSince(event.startDate)
        
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
} 