import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Bindable var event: Event
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title and event type tag
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.largeTitle)
                        .bold()
                    
                    Text(event.eventType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
                
                // Attendance Toggle Button
                Button(action: {
                    event.toggleAttending()
                    try? modelContext.save()
                }) {
                    HStack {
                        Image(systemName: event.isAttending ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(event.isAttending ? .green : .gray)
                        Text(event.isAttending ? "I'm attending" : "Mark as attending")
                            .fontWeight(event.isAttending ? .bold : .medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Date & Time Section
                SectionContainer(title: "Date & Time", icon: "calendar") {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formattedDate)
                                .font(.headline)
                            
                            Text(formattedTime)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            addToCalendar()
                        }) {
                            Text("Add")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                }
                
                // Location Section
                SectionContainer(title: "Location", icon: "mappin.circle.fill") {
                    HStack {
                        Text(event.location)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            openMap()
                        }) {
                            Text("Map")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                }
                
                // Description Section
                SectionContainer(title: "Description", icon: "doc.text") {
                    Text(event.eventDescription)
                        .font(.body)
                }
                
                // Attendees Section
                SectionContainer(title: "Attendees", icon: "person.2.fill", trailingText: "\(event.attendees.count) friends") {
                    // Add Friend Button
                    Button(action: {
                        // Add friend action
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text("Add Friend")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search friends", text: $searchText)
                            .font(.body)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if !event.attendees.isEmpty {
                        ForEach(event.attendees) { friend in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(friend.name)
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    share()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        // Get the day number
        let day = Calendar.current.component(.day, from: event.startDate)
        
        // Add the appropriate suffix
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        // Format the date without the day, then add the day with suffix
        return dateFormatter.string(from: event.startDate) + suffix
    }
    
    private var formattedTime: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mma"
        
        let startTime = timeFormatter.string(from: event.startDate).lowercased()
        let endTime = timeFormatter.string(from: event.endDate).lowercased()
        
        return "\(startTime)-\(endTime)"
    }
    
    private func addToCalendar() {
        // Logic to add to calendar would go here
    }
    
    private func openMap() {
        // Logic to open map would go here
    }
    
    private func share() {
        // Logic to share event would go here
    }
}

struct SectionContainer<Content: View>: View {
    let title: String
    let icon: String
    var trailingText: String? = nil
    let content: Content
    
    init(title: String, icon: String, trailingText: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.trailingText = trailingText
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                Spacer()
                
                if let trailingText = trailingText {
                    Text(trailingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            content
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event.preview)
    }
    .modelContainer(for: Event.self, inMemory: true)
} 
