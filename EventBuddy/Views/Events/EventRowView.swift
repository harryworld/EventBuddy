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
                
                eventTypeTag
            }
            .frame(width: 80)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                } else {
                    Text(event.eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(event.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: event.startDate).lowercased()
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
            return "Event"
        case EventType.watchParty.rawValue:
            return "Watch Party"
        case EventType.conference.rawValue:
            return "Event"
        case EventType.social.rawValue:
            return "Social"
        case EventType.party.rawValue:
            return "Party"
        case EventType.informal.rawValue:
            return "Social"
        case EventType.art.rawValue:
            return "Art"
        case EventType.run.rawValue:
            return "Social"
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
        case EventType.conference.rawValue:
            return .orange
        case EventType.social.rawValue:
            return .blue
        case EventType.party.rawValue:
            return .pink
        case EventType.informal.rawValue:
            return .blue
        case EventType.art.rawValue:
            return .purple
        case EventType.run.rawValue:
            return .blue
        default:
            return .gray
        }
    }
}

struct EventRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            EventRowView(event: Event.preview)
            
            let watchParty = Event.wwdcKeynoteWatchParty
            watchParty.isAttending = true
            return EventRowView(event: watchParty)
        }
        .listStyle(.insetGrouped)
        .modelContainer(for: Event.self, inMemory: true)
    }
} 
