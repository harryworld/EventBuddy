import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry
struct EventBuddyEntry: TimelineEntry {
    let date: Date
    let events: [Event]
    let profile: Profile?
    let configuration: EventBuddyWidgetConfigurationIntent
}

// MARK: - Timeline Provider
struct EventBuddyTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> EventBuddyEntry {
        EventBuddyEntry(
            date: Date(),
            events: [],
            profile: nil,
            configuration: EventBuddyWidgetConfigurationIntent()
        )
    }
    
    func snapshot(for configuration: EventBuddyWidgetConfigurationIntent, in context: Context) async -> EventBuddyEntry {
        await createEntry(for: configuration)
    }
    
    func timeline(for configuration: EventBuddyWidgetConfigurationIntent, in context: Context) async -> Timeline<EventBuddyEntry> {
        let entry = await createEntry(for: configuration)
        
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    @MainActor
    private func createEntry(for configuration: EventBuddyWidgetConfigurationIntent) async -> EventBuddyEntry {
        let provider = WidgetDataProvider.shared
        
        let filter: WidgetEventFilter = configuration.eventFilter == .attending ? .attending : .all
        let timeScope: WidgetTimeScope = configuration.timeScope == .today ? .today : .future
        
        let events = provider.getUpcomingEvents(filter: filter, timeScope: timeScope)
        let profile = provider.getCurrentProfile()
        
        return EventBuddyEntry(
            date: Date(),
            events: events,
            profile: profile,
            configuration: configuration
        )
    }
}

// MARK: - Widget Entry View
struct EventBuddyWidgetEntryView: View {
    var entry: EventBuddyEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallEventWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallEventWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct EventBuddyWidget: Widget {
    let kind: String = "EventBuddyWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: EventBuddyWidgetConfigurationIntent.self,
            provider: EventBuddyTimelineProvider()
        ) { entry in
            EventBuddyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("EventBuddy")
        .description("Stay updated with your upcoming events.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Note: Widget bundle is defined in EventBuddyWidgets.swift 
