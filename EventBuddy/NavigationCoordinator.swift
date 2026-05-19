import SwiftUI

@MainActor
@Observable
class NavigationCoordinator {
    var selectedTab: Int = 0
    var eventToShowID: UUID?
    var shouldNavigateToEvent: Bool = false
    var shouldScrollToEvent: Bool = false
    
    func navigateToEvent(with id: UUID) {
        selectedTab = 0 // Events tab
        eventToShowID = id
        shouldScrollToEvent = true
        shouldNavigateToEvent = true
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
        eventToShowID = nil
        shouldNavigateToEvent = false
        shouldScrollToEvent = false
    }
}
