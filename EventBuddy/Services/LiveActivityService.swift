import ActivityKit
import Foundation
import SwiftData
import UIKit

@Observable
class LiveActivityService {
    private var currentActivity: Activity<EventBuddyWidgetsAttributes>?
    private var modelContext: ModelContext?
    private var updateTimer: Timer?
    
    init() {
        setupNotificationObserver()
        startPeriodicUpdates()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        updateTimer?.invalidate()
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: .eventAttendanceChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let modelContext = self.modelContext else { return }
            
            Task {
                await self.checkAndStartLiveActivityForOngoingEvents(modelContext: modelContext)
            }
        }
        
        // Also observe app lifecycle for Live Activity management
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self,
                  let modelContext = self.modelContext else { return }
            
            Task {
                await self.handleAppEnteringBackground(modelContext: modelContext)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self,
                  let modelContext = self.modelContext else { return }
            
            print("🔴 LiveActivityService: App entering foreground - refreshing Live Activity")
            Task {
                await self.forceUpdate()
            }
        }
    }
    
    private func startPeriodicUpdates() {
        // Ensure timer runs on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update every 2 minutes for less frequent updates since timer intervals handle time automatically
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let modelContext = self.modelContext else { return }
                
                Task { @MainActor in
                    await self.updateOngoingActivities(modelContext: modelContext)
                    await self.adjustUpdateFrequencyIfNeeded(modelContext: modelContext)
                }
            }
            
            // Ensure timer is added to run loop
            if let timer = self.updateTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            print("🔴 LiveActivityService: Started periodic updates (every 2 minutes - timer intervals handle time)")
        }
    }
    
    private func updateOngoingActivities(modelContext: ModelContext) async {
        guard let activity = currentActivity else { 
            print("🔴 LiveActivityService: No active Live Activity to update")
            return 
        }
        
        print("🔴 LiveActivityService: Updating Live Activity state...")
        
        // Fetch current events and find ongoing ones
        let descriptor = FetchDescriptor<Event>()
        
        do {
            let events = try modelContext.fetch(descriptor)
            let ongoingEvents = Event.findOngoingAttendingEvents(from: events)
            
            // If there's an ongoing event, update the activity
            if let ongoingEvent = ongoingEvents.first {
                print("🔴 LiveActivityService: Updating for ongoing event: \(ongoingEvent.title)")
                await updateCurrentActivity(for: ongoingEvent)
            }
            // If no ongoing events, check if any events just ended
            else {
                // Check if there are events that just ended (within the last 5 minutes)
                let recentlyEndedEvents = events.filter { event in
                    event.isAttending && 
                    event.hasEnded && 
                    Date().timeIntervalSince(event.endDate) <= 300 // 5 minutes
                }
                
                if let recentlyEndedEvent = recentlyEndedEvents.first {
                    print("🔴 LiveActivityService: Event just ended, showing completion state")
                    await showEventEndedState(for: recentlyEndedEvent)
                    
                    // End the activity after showing the completion state for 30 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                        Task {
                            await self.endCurrentActivity()
                        }
                    }
                } else {
                    print("🔴 LiveActivityService: No ongoing events, ending Live Activity")
                    await endCurrentActivity()
                }
            }
        } catch {
            print("🔴 LiveActivityService: Failed to fetch events for update: \(error)")
        }
    }
    
    // Set the model context for this service
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Immediately update any active Live Activity when model context is set
        if currentActivity != nil {
            Task { @MainActor in
                await checkAndStartLiveActivityForOngoingEvents(modelContext: context)
            }
        }
    }
    
    // Force an immediate update of the Live Activity
    func forceUpdate() async {
        guard let modelContext = self.modelContext else { return }
        
        print("🔴 LiveActivityService: Force updating Live Activity")
        await updateOngoingActivities(modelContext: modelContext)
    }
    
    // Handle app entering background - ensure Live Activity is active for ongoing events
    func handleAppEnteringBackground(modelContext: ModelContext) async {
        print("🔴 LiveActivityService: App entering background - checking ongoing events")
        
        // Fetch all events from the model context
        let descriptor = FetchDescriptor<Event>()
        
        do {
            let events = try modelContext.fetch(descriptor)
            let ongoingEvents = Event.findOngoingAttendingEvents(from: events)
            
            // Also check for events starting soon (within 30 minutes) that user is attending
            let upcomingEvents = events.filter { event in
                let timeUntilStart = event.startDate.timeIntervalSince(Date())
                return event.isAttending && 
                       timeUntilStart > 0 && 
                       timeUntilStart <= 1800 // 30 minutes
            }.sorted { $0.startDate < $1.startDate }
            
            print("🔴 LiveActivityService: Found \(ongoingEvents.count) ongoing events, \(upcomingEvents.count) upcoming events (30min)")
            
            // Prioritize ongoing events, then upcoming events
            let eventToShow = ongoingEvents.first ?? upcomingEvents.first
            
            if let event = eventToShow {
                let isOngoing = ongoingEvents.contains(event)
                print("🔴 LiveActivityService: Selected \(isOngoing ? "ongoing" : "upcoming") event: \(event.title)")
                
                if currentActivity == nil {
                    print("🔴 LiveActivityService: No active Live Activity - starting for background")
                    await startLiveActivity(for: event)
                } else {
                    print("🔴 LiveActivityService: Live Activity already active - updating for background")
                    await updateCurrentActivity(for: event)
                }
                
                // Ensure we have the most up-to-date content for background display
                await forceUpdate()
            } else {
                print("🔴 LiveActivityService: No relevant events - no Live Activity needed for background")
                if currentActivity != nil {
                    print("🔴 LiveActivityService: Ending existing Live Activity as no relevant events found")
                    await endCurrentActivity()
                }
            }
        } catch {
            print("🔴 LiveActivityService: Failed to fetch events for background check: \(error)")
        }
    }
    
    func startLiveActivity(for event: Event) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        // End any existing activity first
        await endCurrentActivity()
        
        let attributes = EventBuddyWidgetsAttributes(
            eventName: event.title,
            location: event.location,
            eventId: event.id.uuidString
        )
        
        let timeRemaining = timeUntilEndString(for: event)
        let eventStatus = getEventStatus(for: event)
        // Progress is now handled by timer intervals in the widget
        let progress = 0.5 // Placeholder value since timer intervals handle actual progress
        let staleDate = calculateStaleDate(for: event)
        
        let initialState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: eventStatus,
            timeRemaining: timeRemaining,
            progress: progress, // Not used by timer-based progress views
            eventStartDate: event.startDate,
            eventEndDate: event.endDate
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: staleDate)
            )
            currentActivity = activity
            print("Live Activity started for event: \(event.title)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    // Check for ongoing events and start Live Activity if needed
    func checkAndStartLiveActivityForOngoingEvents(modelContext: ModelContext) async {
        print("🔴 LiveActivityService: Checking for ongoing events...")
        
        // Fetch all events from the model context
        let descriptor = FetchDescriptor<Event>()
        
        do {
            let events = try modelContext.fetch(descriptor)
            let ongoingEvents = Event.findOngoingAttendingEvents(from: events)
            
            print("🔴 LiveActivityService: Found \(ongoingEvents.count) ongoing events user is attending")
            
            // If there are ongoing events and no current activity, start one
            if let firstOngoingEvent = ongoingEvents.first, currentActivity == nil {
                print("🔴 LiveActivityService: Starting Live Activity for: \(firstOngoingEvent.title)")
                await startLiveActivity(for: firstOngoingEvent)
            }
            // If there are no ongoing events but there's an active activity, end it
            else if ongoingEvents.isEmpty && currentActivity != nil {
                print("🔴 LiveActivityService: No ongoing events, ending Live Activity")
                await endCurrentActivity()
            }
            // If there's already an activity for a different event, update it
            else if let firstOngoingEvent = ongoingEvents.first, currentActivity != nil {
                print("🔴 LiveActivityService: Updating existing Live Activity for: \(firstOngoingEvent.title)")
                await updateCurrentActivity(for: firstOngoingEvent)
            }
            else {
                print("🔴 LiveActivityService: No action needed")
            }
        } catch {
            print("🔴 LiveActivityService: Failed to fetch events: \(error)")
        }
    }
    
    // Check if there's currently an active Live Activity
    var hasActiveLiveActivity: Bool {
        return currentActivity != nil
    }
    
    // Update the current Live Activity state
    func updateCurrentActivity(for event: Event) async {
        guard let activity = currentActivity else { return }
        
        let timeRemaining = timeUntilEndString(for: event)
        let eventStatus = getEventStatus(for: event)
        // Progress is now handled by timer intervals in the widget
        let progress = 0.5 // Placeholder value since timer intervals handle actual progress
        
        print("🔴 LiveActivityService: Status: '\(eventStatus)', Time: '\(timeRemaining)' (progress auto-managed by timer)")
        
        // Calculate when this content will become stale
        let staleDate = calculateStaleDate(for: event)
        
        if let staleDate = staleDate {
            let secondsUntilStale = staleDate.timeIntervalSince(Date())
            print("🔴 LiveActivityService: Content will be stale in \(Int(secondsUntilStale))s")
        }
        
        let updatedState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: eventStatus,
            timeRemaining: timeRemaining,
            progress: progress, // Not used by timer-based progress views
            eventStartDate: event.startDate,
            eventEndDate: event.endDate
        )
        
        await activity.update(.init(state: updatedState, staleDate: staleDate))
    }
    
    // Calculate when the Live Activity content becomes stale
    private func calculateStaleDate(for event: Event) -> Date? {
        let now = Date()
        let timeUntilEnd = event.endDate.timeIntervalSince(now)
        
        // Since timer intervals handle time updates automatically, we only need to mark content
        // as stale when status or progress might change
        if timeUntilEnd > 0 && timeUntilEnd <= 300 { // Final 5 minutes
            return now.addingTimeInterval(60) // Mark stale every minute for status changes
        } else {
            return now.addingTimeInterval(120) // Mark stale every 2 minutes for normal periods
        }
    }
    
    // Show event ended state
    private func showEventEndedState(for event: Event) async {
        guard let activity = currentActivity else { return }
        
        let endedState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Event Ended",
            timeRemaining: "Completed",
            progress: 1.0, // Timer intervals will show 100% for ended events
            eventStartDate: event.startDate,
            eventEndDate: event.endDate
        )
        
        // Event ended state should be stable for 30 seconds
        let staleDate = Date().addingTimeInterval(30)
        
        print("🔴 LiveActivityService: Showing event ended state for: \(event.title)")
        await activity.update(.init(state: endedState, staleDate: staleDate))
    }
    
    // Get event status string
    private func getEventStatus(for event: Event) -> String {
        let now = Date()
        let timeUntilStart = event.startDate.timeIntervalSince(now)
        let timeUntilEnd = event.endDate.timeIntervalSince(now)
        
        if timeUntilStart > 0 {
            // Event hasn't started yet
            if timeUntilStart <= 300 { // Within 5 minutes of start
                return "Starting Soon"
            } else if timeUntilStart <= 3600 { // Within 1 hour of start
                return "Starting in \(Int(timeUntilStart / 60))m"
            } else {
                return "Upcoming Event"
            }
        } else if timeUntilEnd > 0 {
            // Event is ongoing
            if timeUntilEnd <= 120 { // Final 2 minutes
                return "Ending Soon"
            } else if timeUntilEnd <= 600 { // Final 10 minutes
                return "Almost Done"
            } else {
                return "In Progress"
            }
        } else {
            // Event has ended
            return "Event Ended"
        }
    }
    
    // Get time remaining until event ends (or starts if not started yet)
    private func timeUntilEndString(for event: Event) -> String {
        let now = Date()
        
        // If event hasn't started yet, show time until start
        if now < event.startDate {
            return timeUntilStartString(for: event.startDate)
        }
        
        // If event has ended, show "Ended"
        if now > event.endDate {
            return "Ended"
        }
        
        // Show time remaining until event ends
        let timeInterval = event.endDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Ending Now"
        }
        
        return formatTimeRemaining(timeInterval, isCountdown: true)
    }
    
    private func timeUntilStartString(for startDate: Date) -> String {
        let now = Date()
        let timeInterval = startDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Starting Now"
        }
        
        return formatTimeRemaining(timeInterval, isCountdown: false)
    }
    
    // Enhanced time formatting with better relative display
    private func formatTimeRemaining(_ timeInterval: TimeInterval, isCountdown: Bool) -> String {
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        let suffix = isCountdown ? "left" : "to start"
        
        // More than 2 hours: show hours and minutes
        if hours >= 2 {
            return "\(hours)h \(minutes)m \(suffix)"
        }
        // 1-2 hours: show hours and minutes with more precision
        else if hours >= 1 {
            if minutes == 0 {
                return "\(hours)h \(suffix)"
            } else {
                return "\(hours)h \(minutes)m \(suffix)"
            }
        }
        // 10-60 minutes: show minutes only
        else if minutes >= 10 {
            return "\(minutes)m \(suffix)"
        }
        // 2-9 minutes: show minutes and seconds for precision
        else if minutes >= 2 {
            return "\(minutes)m \(seconds)s \(suffix)"
        }
        // 1 minute: show "1m Xs left" for final countdown feel
        else if minutes == 1 {
            return "1m \(seconds)s \(suffix)"
        }
        // Under 1 minute: show seconds only with urgency
        else if totalSeconds > 30 {
            return "\(totalSeconds)s \(suffix)"
        }
        // Final 30 seconds: more urgent messaging
        else if totalSeconds > 10 {
            return isCountdown ? "Ending in \(totalSeconds)s" : "Starting in \(totalSeconds)s"
        }
        // Final 10 seconds: most urgent
        else if totalSeconds > 0 {
            return isCountdown ? "Ending in \(totalSeconds)s!" : "Starting in \(totalSeconds)s!"
        }
        // Time's up
        else {
            return isCountdown ? "Ending Now!" : "Starting Now!"
        }
    }
    
    // Handle attendance status change - check if Live Activity should be started or stopped
    func handleAttendanceChange(modelContext: ModelContext) async {
        await checkAndStartLiveActivityForOngoingEvents(modelContext: modelContext)
    }
    
    func endCurrentActivity() async {
        guard let activity = currentActivity else { return }
        
        print("🔴 LiveActivityService: Ending Live Activity")
        
        // Use dates from the current activity's state for the final state
        let finalState = EventBuddyWidgetsAttributes.ContentState(
            eventStatus: "Event Completed",
            timeRemaining: "Finished",
            progress: 1.0, // Timer intervals will show 100% for completed events
            eventStartDate: activity.content.state.eventStartDate,
            eventEndDate: activity.content.state.eventEndDate
        )
        
        await activity.end(.init(state: finalState, staleDate: Date()), dismissalPolicy: .immediate)
        currentActivity = nil
    }
    
    // Adjust update frequency based on how close we are to event ending
    private func adjustUpdateFrequencyIfNeeded(modelContext: ModelContext) async {
        guard currentActivity != nil else { return }
        
        let descriptor = FetchDescriptor<Event>()
        
        do {
            let events = try modelContext.fetch(descriptor)
            let ongoingEvents = Event.findOngoingAttendingEvents(from: events)
            
            if let ongoingEvent = ongoingEvents.first {
                let timeUntilEnd = ongoingEvent.endDate.timeIntervalSince(Date())
                let timeUntilStart = ongoingEvent.startDate.timeIntervalSince(Date())
                
                // Check if we need more frequent updates (only for status/progress changes)
                if timeUntilEnd > 0 && timeUntilEnd <= 300 { // Final 5 minutes
                    scheduleFrequentUpdates()
                } else {
                    // Reset to normal frequency if we're outside critical periods
                    scheduleNormalUpdates()
                }
            }
        } catch {
            print("🔴 LiveActivityService: Failed to check event timing: \(error)")
        }
    }
    
    // Schedule more frequent updates for events ending soon (for status changes)
    private func scheduleFrequentUpdates() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel existing timer
            self.updateTimer?.invalidate()
            
            // Update every 60 seconds when event is ending soon (for status changes)
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let modelContext = self.modelContext else { return }
                
                Task { @MainActor in
                    await self.updateOngoingActivities(modelContext: modelContext)
                    await self.adjustUpdateFrequencyIfNeeded(modelContext: modelContext)
                }
            }
            
            // Ensure timer is added to run loop
            if let timer = self.updateTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            print("🔴 LiveActivityService: Switched to frequent updates (every 60 seconds)")
        }
    }
    
    // Schedule normal updates for events not in critical periods
    private func scheduleNormalUpdates() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Cancel existing timer
            self.updateTimer?.invalidate()
            
            // Update every 2 minutes for normal frequency
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
                guard let self = self,
                      let modelContext = self.modelContext else { return }
                
                Task { @MainActor in
                    await self.updateOngoingActivities(modelContext: modelContext)
                    await self.adjustUpdateFrequencyIfNeeded(modelContext: modelContext)
                }
            }
            
            // Ensure timer is added to run loop
            if let timer = self.updateTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            print("🔴 LiveActivityService: Switched to normal updates (every 2 minutes)")
        }
    }
} 