import SwiftUI
import WidgetKit

// MARK: - Small Widget (Next Event)
struct SmallEventWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        if let nextEvent = entry.events.first {
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
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("No upcoming events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .widgetURL(URL(string: "eventbuddy://events"))
        }
    }
}

// MARK: - Medium Widget (Events List or QR Code)
struct MediumWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        if entry.configuration.widgetType == .qrCode {
            QRCodeWidgetView(profile: entry.profile)
        } else {
            EventsListWidgetView(events: Array(entry.events.prefix(3)))
        }
    }
}

// MARK: - Large Widget (More Events or Large QR Code)
struct LargeWidgetView: View {
    let entry: EventBuddyEntry
    
    var body: some View {
        if entry.configuration.widgetType == .qrCode {
            QRCodeWidgetView(profile: entry.profile, isLarge: true)
        } else {
            EventsListWidgetView(events: Array(entry.events.prefix(5)), isLarge: true)
        }
    }
}

// MARK: - Events List Widget
struct EventsListWidgetView: View {
    let events: [Event]
    let isLarge: Bool
    
    init(events: [Event], isLarge: Bool = false) {
        self.events = events
        self.isLarge = isLarge
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            if events.isEmpty {
                Spacer()
                VStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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

// MARK: - QR Code Widget
struct QRCodeWidgetView: View {
    let profile: Profile?
    let isLarge: Bool
    
    init(profile: Profile?, isLarge: Bool = false) {
        self.profile = profile
        self.isLarge = isLarge
    }
    
    var body: some View {
        if let profile = profile {
            VStack(spacing: isLarge ? 12 : 8) {
                HStack {
                    Text("My Contact")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "qrcode")
                        .foregroundColor(.blue)
                }
                
                QRCodeView(
                    contact: profile.createContact(),
                    size: isLarge ? 120 : 80
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                
                VStack(spacing: 2) {
                    Text(profile.name)
                        .font(.system(size: isLarge ? 14 : 12, weight: .medium))
                        .lineLimit(1)
                    
                    if !profile.title.isEmpty || !profile.company.isEmpty {
                        Text("\(profile.title)\(profile.title.isEmpty || profile.company.isEmpty ? "" : " at ")\(profile.company)")
                            .font(.system(size: isLarge ? 12 : 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                if !isLarge {
                    Spacer()
                }
            }
            .widgetURL(URL(string: "eventbuddy://profile"))
        } else {
            VStack {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text("Profile not found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
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