import WidgetKit
import SwiftUI

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

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func createEntry(for configuration: EventBuddyWidgetConfigurationIntent) async -> EventBuddyEntry {
        let provider = await WidgetDataProvider.shared
        let filter = WidgetEventFilter(configuration.eventFilter)
        let timeScope = WidgetTimeScope(configuration.timeScope)
        let events = await provider.getUpcomingEvents(
            filter: filter,
            timeScope: timeScope,
            limit: 5
        )
        let profile = await provider.getCurrentProfile()

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
    @Environment(\.widgetFamily) private var widgetFamily

    let entry: EventBuddyEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallEventWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

struct WWDC26PlaceholderWidgetView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(.blue)

            Text("WWDC26")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "eventbuddy://events"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WWDC26")
        .accessibilityHint("Opens WWDCBuddy events.")
    }
}

// MARK: - Widget Configuration
struct EventBuddyWidgets: Widget {
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
        .configurationDisplayName("WWDCBuddy")
        .description("Stay updated with your upcoming events.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Note: Widget bundle is defined in EventBuddyWidgets.swift 
