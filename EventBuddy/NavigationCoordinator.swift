import SwiftUI
import SwiftData

@Observable
class NavigationCoordinator {
    var selectedTab: Int = 0
    var eventToShow: Event?
    var shouldNavigateToEvent: Bool = false
    var shouldScrollToEvent: Bool = false
    
    func navigateToEvent(with id: UUID, modelContext: ModelContext) {
        // Fetch the event from the database
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                event.id == id
            }
        )
        
        do {
            let events = try modelContext.fetch(descriptor)
            if let event = events.first {
                selectedTab = 0 // Events tab
                eventToShow = event
                shouldScrollToEvent = true
                shouldNavigateToEvent = true
            }
        } catch {
            print("Error fetching event for deep link: \(error)")
        }
    }
    
    func navigateToEventsTab() {
        selectedTab = 0
    }
    
    func navigateToFriendsTab() {
        selectedTab = 1
    }
    
    func navigateToProfileTab() {
        selectedTab = 2
    }
    
    func navigateToSettingsTab() {
        selectedTab = 3
    }
    
    func resetNavigation() {
        eventToShow = nil
        shouldNavigateToEvent = false
        shouldScrollToEvent = false
    }
} 