import SwiftUI

struct EventListView: View {
    let eventStore = EventStore()
    @State private var searchText = ""
    @State private var selectedCategory: EventCategory = .all
    @State private var selectedTab = 0
    
    enum EventCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case keynote = "Keynote"
        case watchParty = "Watch Party"
        case social = "Social"
        
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
                        // Add new event action
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Category buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(EventCategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category
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
                    ForEach(sortedDays, id: \.self) { day in
                        Section(header: Text(day.contains("June") ? day : day.uppercased())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(nil)
                        ) {
                            ForEach(groupedEvents[day] ?? []) { event in
                                NavigationLink(destination: EventDetailView(event: event)) {
                                    EventListItem(event: event)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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
                
                // Tab bar
                HStack(spacing: 0) {
                    TabButton(
                        title: "Events",
                        iconName: "calendar",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        title: "Friends",
                        iconName: "person.2",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                    
                    TabButton(
                        title: "Profile",
                        iconName: "person.crop.circle",
                        isSelected: selectedTab == 2
                    ) {
                        selectedTab = 2
                    }
                    
                    TabButton(
                        title: "Settings",
                        iconName: "gear",
                        isSelected: selectedTab == 3
                    ) {
                        selectedTab = 3
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.systemGray4)),
                    alignment: .top
                )
            }
        }
    }
    
    var filteredEvents: [Event] {
        var events = eventStore.events
        
        // Filter by category
        if selectedCategory != .all {
            events = events.filter { event in
                switch selectedCategory {
                case .keynote:
                    return event.name.localizedCaseInsensitiveContains("Keynote")
                case .watchParty:
                    return event.name.localizedCaseInsensitiveContains("Watch Party")
                case .social:
                    return event.name.localizedCaseInsensitiveContains("Social") || 
                           event.description.localizedCaseInsensitiveContains("Social")
                default:
                    return true
                }
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

struct TabButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
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
