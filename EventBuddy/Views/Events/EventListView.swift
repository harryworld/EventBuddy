import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Event> { event in event.isWWDCEvent == true },
           sort: \Event.startDate) private var events: [Event]
    
    @State private var showingAddEventSheet = false
    @State private var selectedEventFilter: EventFilter = .all
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showOnlyAttending = false
    
    enum EventFilter: String, CaseIterable {
        case all = "All"
        case keynote = "Keynote"
        case watchParty = "Watch Party"
        case social = "Social"
        case meetup = "Meetup"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Search bar
                searchBar
                
                // Title and dates
                eventHeaderInfo
                
                // Attending toggle
                attendingToggle
                
                // Filter view
                filterView
                
                // Event list
                eventListByDate
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEventSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Menu button action
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading events...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search events", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var eventHeaderInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("WWDC25")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Text("June 7-13, 2025 • Cupertino")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }
    
    private var attendingToggle: some View {
        HStack {
            Text("Show only events I'm attending")
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: $showOnlyAttending)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }
    
    private var filterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EventFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            selectedEventFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedEventFilter == filter ? .semibold : .regular)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                Capsule()
                                    .fill(selectedEventFilter == filter ? Color.blue : Color(.systemGray6))
                            )
                            .foregroundStyle(selectedEventFilter == filter ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
    }
    
    private var eventListByDate: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 25) {
                if filteredEvents.isEmpty {
                    ContentUnavailableView {
                        Label("No Events", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("There are no events matching your criteria.")
                    } actions: {
                        Button("Add Sample Events") {
                            addSampleEvents()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(groupedEventsByDate.keys.sorted(), id: \.self) { date in
                        if let dayEvents = groupedEventsByDate[date] {
                            VStack(alignment: .leading, spacing: 15) {
                                Text(formatDateHeader(date))
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                
                                ForEach(dayEvents) { event in
                                    NavigationLink(destination: EventDetailView(event: event)) {
                                        EventRowView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .animation(.spring(duration: 0.2), value: showOnlyAttending)
            .animation(.spring(duration: 0.2), value: selectedEventFilter)
        }
    }
    
    private var filteredEvents: [Event] {
        var result = events
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText) ||
                (event.countryFlag?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter attending events
        if showOnlyAttending {
            // In a real app, this would filter based on user's attending status
            // For now, let's use requiresTicket as a stand-in for attending
            result = result.filter { $0.isAttending }
        }
        
        // Apply category filter
        switch selectedEventFilter {
        case .all:
            return result
        case .keynote:
            return result.filter { $0.eventType == EventType.keynote.rawValue }
        case .watchParty:
            return result.filter { $0.eventType == EventType.watchParty.rawValue }
        case .social:
            return result.filter { $0.eventType == EventType.social.rawValue }
        case .meetup:
            return result.filter { $0.eventType == EventType.meetup.rawValue }
        }
    }
    
    // Group events by date
    private var groupedEventsByDate: [Date: [Event]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: filteredEvents) { event in
            let components = calendar.dateComponents([.year, .month, .day], from: event.startDate)
            return calendar.date(from: components) ?? event.startDate
        }
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private func deleteEvent(_ event: Event) {
        modelContext.delete(event)
    }
    
    private func addSampleEvents() {
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            EventService.addSampleWWDCEvents(modelContext: modelContext)
            isLoading = false
        }
    }
    
    private func refreshEvents() async {
        isLoading = true
        // Simulate network fetch
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isLoading = false
    }
}

#Preview {
    EventListView()
        .modelContainer(for: Event.self, inMemory: true)
} 
