import SwiftUI

struct EventListItem: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(event.dateTime.split(separator: "-").first?.trimmingCharacters(in: CharacterSet.whitespaces) ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(event.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeColor(for: event.type))
                    .clipShape(Capsule())
            }
            .frame(width: 80, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if event.requiresTicket {
                        Image(systemName: "ticket.fill")
                            .foregroundColor(.orange)
                            .symbolEffect(.pulse)
                            .accessibilityLabel("Requires ticket")
                    }
                }
                
                if event.description.localizedCaseInsensitiveContains("registration suggested") {
                    Text("Registration suggested")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if event.description.localizedCaseInsensitiveContains("rsvp requested") {
                    Text("RSVP requested")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(event.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if event.location == "Apple Park" {
                    Text("Apple Park")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if event.location.contains("Infinite Loop") {
                    Text("Infinite Loop")
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if event.description.localizedCaseInsensitiveContains("social") {
                SocialBadge()
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.name), \(event.dateTime), \(event.location)")
        .accessibilityHint("\(event.description). \(event.requiresTicket ? "Requires a ticket." : "No ticket required.")")
        .contentShape(Rectangle())
    }
    
    private func typeColor(for type: EventType) -> Color {
        switch type {
        case .keynote:
            return .red
        case .watchParty:
            return .purple
        case .social:
            return .blue
        case .event:
            return .orange
        case .meetup:
            return .green
        }
    }
}

struct SocialBadge: View {
    var body: some View {
        Text("SOCIAL")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .cornerRadius(4)
    }
} 
