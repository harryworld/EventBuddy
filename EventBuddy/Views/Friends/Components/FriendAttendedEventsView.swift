import SwiftUI

struct FriendAttendedEventsView: View {
    let friend: Friend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Attended Events")
                    .font(.headline)
                
                Spacer()
                
                Text("\(friend.events.count) events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if friend.events.isEmpty {
                Text("No events attended yet")
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(friend.events) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        HStack(alignment: .top, spacing: 12) {
                            // Calendar icon with date
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                VStack(spacing: 2) {
                                    Text(event.startDate, format: .dateTime.month(.abbreviated))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    
                                    Text(event.startDate, format: .dateTime.day())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                HStack {
                                    Image(systemName: "mappin")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(event.location)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Text(event.startDate, format: .dateTime.hour().minute())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
} 