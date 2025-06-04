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

enum WidgetTimeScope: String, CaseIterable {
    case today = "today"
    case future = "future"
    
    var displayName: String {
        switch self {
        case .today: return "Today Only"
        case .future: return "Future Days"
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
        timeScope: WidgetTimeScope = .future,
        limit: Int = 5
    ) -> [Event] {
        let now = Date()
        let calendar = Calendar.current
        
        let endDate: Date
        switch timeScope {
        case .today:
            // Get end of today
            endDate = calendar.dateInterval(of: .day, for: now)?.end ?? now
        case .future:
            // Get events for the next 30 days
            endDate = calendar.date(byAdding: .day, value: 30, to: now) ?? now
        }
        
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
        return getUpcomingEvents(filter: filter, timeScope: .future, limit: 1).first
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