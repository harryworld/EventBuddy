import SwiftUI

@MainActor
@Observable
class NavigationCoordinator {
    enum AppTab: Hashable {
        case events
        case friends
        case profile
        case settings
        case eventSearch
    }

    enum SearchContext {
        case events
        case friends
    }

    var selectedTab: AppTab = .events {
        didSet {
            updateSearchContext(from: oldValue)
        }
    }
    var searchContext: SearchContext = .events
    var eventToShowID: UUID?
    var shouldNavigateToEvent: Bool = false
    var shouldScrollToEvent: Bool = false
    
    func navigateToEvent(with id: UUID) {
        selectedTab = .events
        eventToShowID = id
        shouldScrollToEvent = true
        shouldNavigateToEvent = true
    }
    
    func navigateToEventsTab() {
        selectedTab = .events
    }
    
    func navigateToFriendsTab() {
        selectedTab = .friends
    }
    
    func navigateToProfileTab() {
        selectedTab = .profile
    }
    
    func navigateToSettingsTab() {
        selectedTab = .settings
    }
    
    func resetNavigation() {
        eventToShowID = nil
        shouldNavigateToEvent = false
        shouldScrollToEvent = false
    }

    private func updateSearchContext(from previousTab: AppTab) {
        switch selectedTab {
        case .events:
            searchContext = .events
        case .friends:
            searchContext = .friends
        case .eventSearch:
            if previousTab == .friends {
                searchContext = .friends
            } else if previousTab == .events {
                searchContext = .events
            }
        case .profile, .settings:
            break
        }
    }
}
