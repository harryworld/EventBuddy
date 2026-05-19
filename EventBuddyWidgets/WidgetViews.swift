import SwiftUI
import WidgetKit

// MARK: - Small Widget (Next Event)
struct SmallEventWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        if let nextEvent = entry.visibleEvents.first {
            VStack(alignment: .leading, spacing: 4) {
                Text(nextEvent.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                
                Text(relativeTimeString(for: nextEvent.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(nextEvent.location)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    Image(systemName: eventTypeIcon(nextEvent.eventType))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if nextEvent.isAttending {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
            }
            .widgetURL(URL(string: "eventbuddy://event/\(nextEvent.id.uuidString)"))
        } else {
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(entry.emptyEventMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .widgetURL(URL(string: "eventbuddy://events"))
        }
    }
}

// MARK: - Medium Widget (Events List)
struct MediumWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        EventsListWidgetView(
            title: entry.eventListTitle,
            emptyMessage: entry.emptyEventMessage,
            events: Array(entry.visibleEvents.prefix(3))
        )
    }
}

// MARK: - Large Widget (More Events)
struct LargeWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        EventsListWidgetView(
            title: entry.eventListTitle,
            emptyMessage: entry.emptyEventMessage,
            events: Array(entry.visibleEvents.prefix(5)),
            isLarge: true
        )
    }
}

// MARK: - Events List Widget
struct EventsListWidgetView: View {
    let title: String
    let emptyMessage: String
    let events: [Event]
    let isLarge: Bool
    
    init(title: String, emptyMessage: String, events: [Event], isLarge: Bool = false) {
        self.title = title
        self.emptyMessage = emptyMessage
        self.events = events
        self.isLarge = isLarge
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            if events.isEmpty {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text(emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            } else {
                ForEach(events) { event in
                    Link(destination: URL(string: "eventbuddy://event/\(event.id.uuidString)")!) {
                        EventRowView(event: event, isCompact: !isLarge)
                    }
                }
                
                if events.count < (isLarge ? 5 : 3) {
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Event Row
struct EventRowView: View {
    let event: Event
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: isCompact ? 12 : 14, weight: .medium))
                    .lineLimit(1)
                
                Text(relativeTimeString(for: event.startDate))
                    .font(.system(size: isCompact ? 10 : 12))
                    .foregroundColor(.blue)
                
                if !isCompact {
                    Text(event.location)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Image(systemName: eventTypeIcon(event.eventType))
                    .font(.system(size: isCompact ? 10 : 12))
                    .foregroundColor(.secondary)
                
                if event.isAttending {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: isCompact ? 8 : 10))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Helper Functions
private func relativeTimeString(for date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.dateTimeStyle = .named
    formatter.formattingContext = .standalone
    return formatter.localizedString(for: date, relativeTo: Date())
}

private func eventTypeIcon(_ eventType: String) -> String {
    switch eventType.lowercased() {
    case "keynote": return "mic.fill"
    case "watch party": return "tv.fill"
    case "social": return "person.2.fill"
    case "meetup": return "person.3.fill"
    default: return "calendar"
    }
} 

private extension EventBuddyEntry {
    var visibleEvents: [Event] {
        events
    }

    var eventListTitle: String {
        switch configuration.eventFilter {
        case .attending:
            return "Attending Events"
        case .all:
            switch configuration.timeScope {
            case .today:
                return "Today's Events"
            case .future:
                return "Future Events"
            }
        }
    }

    var emptyEventMessage: String {
        switch (configuration.eventFilter, configuration.timeScope) {
        case (.attending, .today):
            return "No attending events today"
        case (.attending, .future):
            return "No attending future events"
        case (.all, .today):
            return "No events today"
        case (.all, .future):
            return "No future events"
        }
    }
}
