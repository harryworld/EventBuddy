import SwiftUI

struct EventListView: View {
    let eventStore: EventStore
    let friendStore: FriendStore
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory = .all
    @State private var showingAddEvent = false
    @State private var showOnlyAttendingEvents = false
    
    init(eventStore: EventStore = EventStore(), friendStore: FriendStore = FriendStore()) {
        self.eventStore = eventStore
        self.friendStore = friendStore
    }
    
    enum EventCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case keynote = "Keynote"
        case watchParty = "Watch Party"
        case social = "Social"
        case myEvents = "My Events"
        case attending = "Attending"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Event header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WWDC25")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("June 7-12, 2025 • Cupertino")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Add Event")
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Toggle for attending events
                if selectedCategory != .attending {
                    HStack {
                        Toggle("Show only events I'm attending", isOn: $showOnlyAttendingEvents)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                            .onChange(of: showOnlyAttendingEvents) { _, isOn in
                                if isOn {
                                    selectedCategory = .all
                                }
                            }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Category buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventCategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category
                                if category == .attending {
                                    showOnlyAttendingEvents = false
                                }
                            }) {
                                Text(category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.blue : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Events List
                List {
                    if filteredEvents.isEmpty {
                        ContentUnavailableView(
                            "No Events Found",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Try changing your filters")
                        )
                    } else {
                        ForEach(sortedDays, id: \.self) { day in
                            if let dayEvents = groupedEvents[day], !dayEvents.isEmpty {
                                Section(header: Text(day.contains("June") ? day : day.uppercased())
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .textCase(nil)
                                ) {
                                    ForEach(dayEvents) { event in
                                        NavigationLink(destination: EventDetailView(event: event, eventStore: eventStore, friendStore: friendStore)) {
                                            EventListItem(event: event)
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            if event.isCustomEvent {
                                                Button(role: .destructive) {
                                                    eventStore.removeCustomEvent(id: event.id)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search events")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("All Events") {
                                searchText = ""
                                selectedCategory = .all
                                showOnlyAttendingEvents = false
                            }
                            Button("Events I'm Attending") {
                                selectedCategory = .attending
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
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(eventStore: eventStore)
            }
        }
    }
    
    var filteredEvents: [Event] {
        var events = eventStore.events
        
        // Filter for attending events if toggle is on
        if showOnlyAttendingEvents {
            events = events.filter { $0.isUserAttending }
        }
        
        // Filter by category
        if selectedCategory != .all {
            switch selectedCategory {
            case .keynote:
                events = events.filter { event in 
                    event.type == .keynote
                }
            case .watchParty:
                events = events.filter { event in 
                    event.type == .watchParty
                }
            case .social:
                events = events.filter { event in 
                    event.type == .social
                }
            case .myEvents:
                events = events.filter { event in
                    event.isCustomEvent
                }
            case .attending:
                events = events.filter { event in
                    event.isUserAttending
                }
            default:
                break
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            events = events.filter { event in
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                (searchText.localizedCaseInsensitiveContains("ticket") && event.requiresTicket) ||
                (searchText.localizedCaseInsensitiveContains("free") && !event.requiresTicket)
            }
        }
        
        return events
    }
    
    var groupedEvents: [String: [Event]] {
        Dictionary(grouping: filteredEvents) { $0.day }
    }
    
    var sortedDays: [String] {
        let dayOrder = [
            "Saturday, June 7th",
            "Sunday, June 8th", 
            "Monday, June 9th",
            "Tuesday, June 10th", 
            "Wednesday, June 11th",
            "Thursday, June 12th",
            "Watch Parties" // Keep "Watch Parties" at the end
        ]
        
        return groupedEvents.keys.sorted { day1, day2 in
            if let index1 = dayOrder.firstIndex(of: day1), 
               let index2 = dayOrder.firstIndex(of: day2) {
                return index1 < index2
            } else if dayOrder.contains(day1) {
                return true
            } else if dayOrder.contains(day2) {
                return false
            } else {
                return day1 < day2
            }
        }
    }
}

#Preview {
    EventListView()
} 
