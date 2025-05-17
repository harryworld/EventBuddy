import SwiftUI

struct EventListItem: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.name)
                    .font(.headline)
                
                Spacer()
                
                if event.requiresTicket {
                    Image(systemName: "ticket.fill")
                        .foregroundColor(.orange)
                        .symbolEffect(.pulse)
                        .accessibilityLabel("Requires ticket")
                }
            }
            
            Text(event.dateTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(event.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.name), \(event.dateTime), \(event.location)")
        .accessibilityHint("\(event.description). \(event.requiresTicket ? "Requires a ticket." : "No ticket required.")")
        .contentShape(Rectangle())
    }
} 