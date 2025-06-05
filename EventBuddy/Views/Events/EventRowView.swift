import SwiftUI
import SwiftData

struct EventRowView: View {
    let event: Event
    
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
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(event.hasEnded)
                    
                    if event.isAttending {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibilityLabel("You're attending")
                    }
                }
                
                if event.requiresTicket {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .symbolEffect(.pulse)

                        Text("Ticket required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if event.requiresRegistration {
                    HStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(event.requiresRegistration ? "Registration suggested" : "RSVP requested")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if !event.eventDescription.isEmpty {
                    Text(event.eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(event.location.isEmpty ? "No location" : event.location)
                    .font(.caption)
                    .foregroundColor(event.location.isEmpty ? .gray : .secondary)
                    .italic(event.location.isEmpty)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .opacity(event.hasEnded ? 0.4 : 1.0)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: event.startDate)
    }

    private var shouldShowDualTimezone: Bool {
        guard let originalTimezone = event.originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            return false
        }
        
        let currentTimezone = TimeZone.current
        return eventTimezone.identifier != currentTimezone.identifier
    }
    
    private var formattedTimeOriginalTimezone: String {
        guard let originalTimezone = event.originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            return formattedTimeWithTimezone
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma zzz"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = eventTimezone
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: event.startDate)
    }
    
    private var formattedTimeWithTimezone: String {
        guard let originalTimezone = event.originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            // Fallback to current timezone
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma zzz"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "en_US")
            return formatter.string(from: event.startDate)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma zzz"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = eventTimezone
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: event.startDate)
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
        switch event.eventType {
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
        switch event.eventType {
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
    .listStyle(.insetGrouped)
    .modelContainer(for: Event.self, inMemory: true)
}
