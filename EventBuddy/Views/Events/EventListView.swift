import SwiftUI
import SwiftData

struct EventListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(EventSyncService.self) private var eventSyncService: EventSyncService?

    @Query(sort: \Event.startDate) private var events: [Event]
    
    @State private var showingAddEventSheet = false
    @State private var selectedEventFilter: EventFilter = .all
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    
    // Use AppStorage for persistent storage of the attending filter
    @AppStorage("showOnlyAttending") private var showOnlyAttending = false
    
    // Navigation coordinator for deep linking
    var navigationCoordinator: NavigationCoordinator?
    
    enum EventFilter: String, CaseIterable {
        case all = "All"
        case keynote = "Keynote"
        case watchParty = "Watch Party"
        case social = "Social"
        case meetup = "Meetup"
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(alignment: .leading, spacing: 0) {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await eventSyncService?.manualSync()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                            if eventSyncService?.isLoading == true {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(eventSyncService?.isLoading == true)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEventSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
            .onAppear {
                handleDeepLinkNavigation()
            }
            .onChange(of: navigationCoordinator?.shouldNavigateToEvent) { _, shouldNavigate in
                if shouldNavigate == true && navigationCoordinator?.shouldScrollToEvent != true {
                    // Only handle immediate navigation if we're not scrolling first
                    handleDeepLinkNavigation()
                }
            }
            .overlay {
                if eventSyncService?.isLoading == true {
                    ProgressView("Syncing events...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                }
            }
            .overlay(alignment: .top) {
                // Toast notification for blocked manual sync
                if eventSyncService?.isManualSyncBlocked == true {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("Please wait a moment before refreshing again")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        if let timeRemaining = eventSyncService?.formattedTimeUntilNextManualSync() {
                            Text("Try again in \(timeRemaining)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.top, 28)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: eventSyncService?.isManualSyncBlocked)
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
            
            // Sync status
            if let lastSyncDate = eventSyncService?.lastSyncDate {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                        Text("Last synced: \(formatSyncDate(lastSyncDate, relativeTo: context.date))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            } else if let syncError = eventSyncService?.syncError, !syncError.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Sync failed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
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

    // Flag to determine if we're in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var eventListByDate: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Search bar
                searchBar

                LazyVStack(alignment: .leading, spacing: 25) {
                if filteredEvents.isEmpty {
                    ContentUnavailableView {
                        Label("No Events", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("There are no events matching your criteria.")
                    } actions: {
                        // Preview only
                        if isPreview {
                            Button("Add Sample Events") {
                                addSampleEvents()
                            }
                            .buttonStyle(.borderedProminent)
                        }
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
                                    NavigationLink(value: event) {
                                        EventRowView(event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .id(event.id)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .animation(.spring(duration: 0.2), value: showOnlyAttending)
            .animation(.spring(duration: 0.2), value: selectedEventFilter)
            .onChange(of: navigationCoordinator?.shouldScrollToEvent) { _, shouldScroll in
                if shouldScroll == true, let eventToShow = navigationCoordinator?.eventToShow {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(eventToShow.id, anchor: .center)
                    }
                    
                    // After scrolling, wait a moment then navigate to detail
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        navigationPath.append(eventToShow)
                        navigationCoordinator?.resetNavigation()
                    }
                }
            }
        }
        }
    }
    
    private var filteredEvents: [Event] {
        var result = events
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText) ||
                event.eventDescription.localizedCaseInsensitiveContains(searchText)
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
        Task {
            EventService.addSampleWWDCEvents(modelContext: modelContext)
        }
    }
    
    private func refreshEvents() async {
        await eventSyncService?.manualSync()
    }
    
    private func formatSyncDate(_ date: Date, relativeTo: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: relativeTo)
    }
    
    private func handleDeepLinkNavigation() {
        guard let coordinator = navigationCoordinator,
              coordinator.shouldNavigateToEvent,
              let eventToShow = coordinator.eventToShow else {
            return
        }
        
        // Navigate to the specific event
        navigationPath.append(eventToShow)
        
        // Reset the navigation state
        coordinator.resetNavigation()
    }
}

#Preview {
    EventListView()
        .modelContainer(for: Event.self, inMemory: true)
}
