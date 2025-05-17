import SwiftUI

struct EventListView: View {
    let eventStore = EventStore()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedEvents.keys.sorted(), id: \.self) { day in
                    Section(header: Text(day)) {
                        ForEach(groupedEvents[day] ?? []) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventListItem(event: event)
                            }
                        }
                    }
                }
            }
            .navigationTitle("WWDC25 Events")
            .searchable(text: $searchText, prompt: "Search events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("All Events") {
                            searchText = ""
                        }
                        Button("Events Requiring Tickets") {
                            searchText = "ticket"
                        }
                        Button("Free Events") {
                            searchText = "free"
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return eventStore.events
        } else {
            return eventStore.events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                (searchText.localizedCaseInsensitiveContains("ticket") && event.requiresTicket) ||
                (searchText.localizedCaseInsensitiveContains("free") && !event.requiresTicket)
            }
        }
    }
    
    var groupedEvents: [String: [Event]] {
        Dictionary(grouping: filteredEvents) { $0.day }
    }
}

struct EventDetailView: View {
    let event: Event
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(event.day.replacingOccurrences(of: ", ", with: "\n"))
                    }
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text(event.dateTime)
                    }
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text(event.location)
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                if event.requiresTicket {
                    Label("This event requires a ticket", systemImage: "ticket.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this event")
                        .font(.headline)
                    
                    Text(event.description)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Add to calendar functionality would go here
                }) {
                    Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EventListView()
} 