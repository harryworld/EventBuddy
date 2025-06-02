import SwiftData
import WidgetKit
import Foundation

enum WidgetEventFilter: String, CaseIterable {
    case all = "all"
    case attending = "attending"
    
    var displayName: String {
        switch self {
        case .all: return "All Events"
        case .attending: return "Attending Events"
        }
    }
}

enum WidgetTimeRange: String, CaseIterable {
    case week = "week"
    case month = "month"
    
    var displayName: String {
        switch self {
        case .week: return "Next 7 Days"
        case .month: return "Next 30 Days"
        }
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        }
    }
}

@MainActor
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private lazy var modelContainer: ModelContainer = {
        EventBuddySchema.sharedModelContainer
    }()
    
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    func getUpcomingEvents(
        filter: WidgetEventFilter = .all,
        timeRange: WidgetTimeRange = .week,
        limit: Int = 5
    ) -> [Event] {
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: timeRange.days, to: now) ?? now
        
        let predicate = #Predicate<Event> { event in
            event.startDate >= now && event.startDate <= endDate
        }
        
        let descriptor = FetchDescriptor<Event>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        
        do {
            let allEvents = try modelContext.fetch(descriptor)
            
            let filteredEvents: [Event]
            switch filter {
            case .all:
                filteredEvents = allEvents
            case .attending:
                filteredEvents = allEvents.filter { $0.isAttending }
            }
            
            return Array(filteredEvents.prefix(limit))
        } catch {
            print("Error fetching events for widget: \(error)")
            return []
        }
    }
    
    func getNextEvent(filter: WidgetEventFilter = .all) -> Event? {
        return getUpcomingEvents(filter: filter, timeRange: .month, limit: 1).first
    }
    
    func getCurrentProfile() -> Profile? {
        let descriptor = FetchDescriptor<Profile>()
        
        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            print("Error fetching profile for widget: \(error)")
            return nil
        }
    }
} 