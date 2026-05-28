import SwiftUI

struct EventRowView: View {
    let title: String
    let eventDescription: String
    let location: String
    let startDate: Date
    let endDate: Date
    let eventType: String
    let requiresTicket: Bool
    let requiresRegistration: Bool
    let isAttending: Bool
    let originalTimezoneIdentifier: String?

    init(event: Event) {
        self.title = event.title
        self.eventDescription = event.eventDescription
        self.location = event.location
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.eventType = event.eventType
        self.requiresTicket = event.requiresTicket
        self.requiresRegistration = event.requiresRegistration
        self.isAttending = event.isAttending
        self.originalTimezoneIdentifier = event.originalTimezoneIdentifier
    }

    init(eventRow: StoredEvent, isAttending: Bool? = nil) {
        self.title = eventRow.title
        self.eventDescription = eventRow.eventDescription
        self.location = eventRow.location
        self.startDate = eventRow.startDate
        self.endDate = eventRow.endDate
        self.eventType = eventRow.eventType
        self.requiresTicket = eventRow.requiresTicket
        self.requiresRegistration = eventRow.requiresRegistration
        self.isAttending = isAttending ?? eventRow.isAttending
        self.originalTimezoneIdentifier = eventRow.originalTimezoneIdentifier
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Time column
            VStack(alignment: .trailing) {
                Text(formattedTime)
                    .font(.headline)
                    .fontWeight(.semibold)

                if shouldShowDualTimezone {
                    Text(formattedTimeOriginalTimezone)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                eventTypeTag
            }
            .frame(width: 80)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(hasEnded)
                    
                    if isAttending {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibilityLabel("You're attending")
                    }
                }
                
                if requiresTicket {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .symbolEffect(.pulse)

                        Text("Ticket required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if requiresRegistration {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(requiresRegistration ? "Registration suggested" : "RSVP requested")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !eventDescription.isEmpty {
                    Text(eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(location.isEmpty ? "No location" : location)
                    .font(.caption)
                    .foregroundColor(location.isEmpty ? .gray : .secondary)
                    .italic(location.isEmpty)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.eventBuddySystemBackground)
        .cornerRadius(8)
        .opacity(hasEnded ? 0.4 : 1.0)
    }

    private var hasEnded: Bool {
        Date() > endDate
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: startDate)
    }

    private var shouldShowDualTimezone: Bool {
        guard let originalTimezone = originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            return false
        }
        
        let currentTimezone = TimeZone.current
        return eventTimezone.identifier != currentTimezone.identifier
    }
    
    private var formattedTimeOriginalTimezone: String {
        guard let originalTimezone = originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            return formattedTimeWithTimezone
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma zzz"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = eventTimezone
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: startDate)
    }
    
    private var formattedTimeWithTimezone: String {
        guard let originalTimezone = originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            // Fallback to current timezone
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma zzz"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: startDate)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma zzz"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = eventTimezone
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: startDate)
    }

    private var eventTypeTag: some View {
        Text(getEventTypeLabel())
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(getEventTypeColor())
            )
            .foregroundColor(.white)
    }
    
    private func getEventTypeLabel() -> String {
        switch eventType {
        case EventType.keynote.rawValue:
            return "Keynote"
        case EventType.watchParty.rawValue:
            return "Watch Party"
        case EventType.social.rawValue:
            return "Social"
        case EventType.meetup.rawValue:
            return "Meetup"
        default:
            return "Event"
        }
    }
    
    private func getEventTypeColor() -> Color {
        switch eventType {
        case EventType.keynote.rawValue:
            return .orange
        case EventType.watchParty.rawValue:
            return .blue
        case EventType.social.rawValue:
            return .blue
        case EventType.meetup.rawValue:
            return .purple
        default:
            return .gray
        }
    }
}

#Preview {
    List {
        EventRowView(event: Event.preview)

        EventRowView(event: Event.wwdcKeynoteWatchParty)
    }
    .eventBuddyInsetGroupedListStyle()
}
