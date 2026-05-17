import SwiftUI

@MainActor
@Observable
class NavigationCoordinator {
    var selectedTab: Int = 0
    var eventToShow: Event?
    var shouldNavigateToEvent: Bool = false
    var shouldScrollToEvent: Bool = false
    
    func navigateToEvent(with id: UUID, appStore: AppStore) {
        do {
            if let event = try appStore.event(id: id) {
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
