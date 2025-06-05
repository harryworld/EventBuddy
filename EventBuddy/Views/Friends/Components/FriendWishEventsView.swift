import SwiftUI

struct FriendWishEventsView: View {
    let friend: Friend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Want to Meet")
                    .font(.headline)
                
                Spacer()
                
                Text("\(friend.wishEvents.count) events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if friend.wishEvents.isEmpty {
                Text("No one wanted to meet at events yet")
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } else {
                ForEach(friend.wishEvents) { event in
                    NavigationLink(value: event) {
                        HStack(alignment: .top, spacing: 12) {
                            // Calendar icon with date (orange theme for wishes)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                VStack(spacing: 2) {
                                    Text(event.startDate, format: .dateTime.month(.abbreviated))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                    
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
                                
                                // Want to meet indicator
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    
                                    Text("Want to meet")
                                        .font(.caption)
                                        .foregroundColor(.orange)
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