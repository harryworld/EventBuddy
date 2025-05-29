import SwiftUI
import SwiftData

struct DataExportTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isCreatingData = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("Test Data Creator")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Create sample events and friends to test the export functionality")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        createSampleData()
                    } label: {
                        HStack {
                            if isCreatingData {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle")
                            }
                            Text("Create Sample Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isCreatingData)
                    
                    Text("This will create:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        testDataRow(icon: "calendar", title: "5 Sample Events", description: "Various event types")
                        testDataRow(icon: "person.2", title: "10 Sample Friends", description: "With contact info")
                        testDataRow(icon: "link", title: "Event-Friend Relationships", description: "Attendees and wishes")
                    }
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func testDataRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func createSampleData() {
        isCreatingData = true
        
        Task {
            // Create sample friends
            let friends = createSampleFriends()
            
            // Create sample events
            let events = createSampleEvents()
            
            // Create relationships
            createRelationships(events: events, friends: friends)
            
            await MainActor.run {
                isCreatingData = false
                dismiss()
            }
        }
    }
    
    private func createSampleFriends() -> [Friend] {
        let sampleFriends = [
            Friend(name: "Alice Johnson", email: "alice@example.com", phone: "+1-555-0101", jobTitle: "iOS Developer", company: "Apple Inc.", socialMediaHandles: ["twitter": "alicecodes", "github": "alicejohnson"], notes: "Met at WWDC 2024"),
            Friend(name: "Bob Smith", email: "bob@example.com", phone: "+1-555-0102", jobTitle: "Product Manager", company: "Google", socialMediaHandles: ["linkedin": "bobsmith"], notes: "Great networking contact"),
            Friend(name: "Carol Davis", email: "carol@example.com", phone: "+1-555-0103", jobTitle: "UX Designer", company: "Meta", socialMediaHandles: ["dribbble": "caroldesigns"], notes: "Amazing design insights", isFavorite: true),
            Friend(name: "David Wilson", email: "david@example.com", phone: "+1-555-0104", jobTitle: "Software Engineer", company: "Microsoft", socialMediaHandles: ["github": "davidwilson"], notes: "Excellent Swift knowledge"),
            Friend(name: "Emma Brown", email: "emma@example.com", phone: "+1-555-0105", jobTitle: "Tech Lead", company: "Netflix", socialMediaHandles: ["twitter": "emmabrown"], notes: "Inspiring leader"),
            Friend(name: "Frank Miller", email: "frank@example.com", phone: "+1-555-0106", jobTitle: "DevOps Engineer", company: "Amazon", socialMediaHandles: ["linkedin": "frankmiller"], notes: "Cloud expert"),
            Friend(name: "Grace Lee", email: "grace@example.com", phone: "+1-555-0107", jobTitle: "Data Scientist", company: "Tesla", socialMediaHandles: ["kaggle": "gracelee"], notes: "ML enthusiast", isFavorite: true),
            Friend(name: "Henry Taylor", email: "henry@example.com", phone: "+1-555-0108", jobTitle: "Security Engineer", company: "Stripe", socialMediaHandles: ["github": "henrytaylor"], notes: "Security expert"),
            Friend(name: "Ivy Chen", email: "ivy@example.com", phone: "+1-555-0109", jobTitle: "Frontend Developer", company: "Airbnb", socialMediaHandles: ["codepen": "ivychen"], notes: "React specialist"),
            Friend(name: "Jack Anderson", email: "jack@example.com", phone: "+1-555-0110", jobTitle: "Backend Developer", company: "Uber", socialMediaHandles: ["stackoverflow": "jackanderson"], notes: "API design guru")
        ]
        
        for friend in sampleFriends {
            modelContext.insert(friend)
        }
        
        return sampleFriends
    }
    
    private func createSampleEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        
        let sampleEvents = [
            Event(
                title: "iOS Dev Meetup",
                eventDescription: "Monthly iOS developers meetup with talks and networking",
                location: "Tech Hub San Francisco",
                address: "123 Market St, San Francisco, CA",
                startDate: calendar.date(byAdding: .day, value: 7, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 7, to: calendar.date(byAdding: .hour, value: 3, to: now)!)!,
                eventType: EventType.meetup.rawValue,
                notes: "Bring business cards",
                requiresRegistration: true,
                url: "https://iosdevmeetup.com"
            ),
            Event(
                title: "SwiftUI Workshop",
                eventDescription: "Hands-on workshop covering advanced SwiftUI techniques",
                location: "Apple Park Visitor Center",
                address: "10600 N Tantau Ave, Cupertino, CA",
                startDate: calendar.date(byAdding: .day, value: 14, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 14, to: calendar.date(byAdding: .hour, value: 6, to: now)!)!,
                eventType: EventType.social.rawValue,
                notes: "Bring MacBook",
                requiresTicket: true,
                url: "https://swiftuiworkshop.com"
            ),
            Event(
                title: "Tech Conference 2025",
                eventDescription: "Annual technology conference with industry leaders",
                location: "Moscone Center",
                address: "747 Howard St, San Francisco, CA",
                startDate: calendar.date(byAdding: .month, value: 1, to: now)!,
                endDate: calendar.date(byAdding: .month, value: 1, to: calendar.date(byAdding: .day, value: 2, to: now)!)!,
                eventType: EventType.keynote.rawValue,
                notes: "Multi-day event",
                requiresTicket: true,
                requiresRegistration: true,
                url: "https://techconf2025.com"
            ),
            Event(
                title: "WWDC Watch Party",
                eventDescription: "Community watch party for WWDC keynote",
                location: "Local Coffee Shop",
                address: "456 Main St, Palo Alto, CA",
                startDate: calendar.date(byAdding: .month, value: 2, to: now)!,
                endDate: calendar.date(byAdding: .month, value: 2, to: calendar.date(byAdding: .hour, value: 4, to: now)!)!,
                eventType: EventType.watchParty.rawValue,
                notes: "Free coffee and snacks",
                url: "https://wwdcwatchparty.com"
            ),
            Event(
                title: "Networking Happy Hour",
                eventDescription: "Casual networking event for tech professionals",
                location: "Rooftop Bar Downtown",
                address: "789 1st St, San Jose, CA",
                startDate: calendar.date(byAdding: .day, value: 21, to: now)!,
                endDate: calendar.date(byAdding: .day, value: 21, to: calendar.date(byAdding: .hour, value: 2, to: now)!)!,
                eventType: EventType.social.rawValue,
                notes: "Casual dress code"
            )
        ]
        
        for event in sampleEvents {
            modelContext.insert(event)
        }
        
        return sampleEvents
    }
    
    private func createRelationships(events: [Event], friends: [Friend]) {
        // Add some friends as attendees to events
        events[0].addFriend(friends[0]) // Alice to iOS Dev Meetup
        events[0].addFriend(friends[1]) // Bob to iOS Dev Meetup
        events[0].addFriend(friends[3]) // David to iOS Dev Meetup
        
        events[1].addFriend(friends[0]) // Alice to SwiftUI Workshop
        events[1].addFriend(friends[2]) // Carol to SwiftUI Workshop
        
        events[2].addFriend(friends[4]) // Emma to Tech Conference
        events[2].addFriend(friends[5]) // Frank to Tech Conference
        events[2].addFriend(friends[6]) // Grace to Tech Conference
        
        events[3].addFriend(friends[7]) // Henry to WWDC Watch Party
        events[3].addFriend(friends[8]) // Ivy to WWDC Watch Party
        
        events[4].addFriend(friends[9]) // Jack to Networking Happy Hour
        events[4].addFriend(friends[2]) // Carol to Networking Happy Hour
        
        // Add some friend wishes
        events[0].addFriendWish(friends[2]) // Want to meet Carol at iOS Dev Meetup
        events[1].addFriendWish(friends[4]) // Want to meet Emma at SwiftUI Workshop
        events[2].addFriendWish(friends[1]) // Want to meet Bob at Tech Conference
        events[3].addFriendWish(friends[3]) // Want to meet David at WWDC Watch Party
        events[4].addFriendWish(friends[6]) // Want to meet Grace at Networking Happy Hour
        
        // Mark some events as attending
        events[0].isAttending = true
        events[1].isAttending = true
        events[3].isAttending = true
    }
}

#Preview {
    DataExportTestView()
        .modelContainer(for: [Event.self, Friend.self])
} 