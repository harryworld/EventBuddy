import SQLiteData
import SwiftUI

struct EventListView: View {
    @Environment(EventSyncService.self) private var eventSyncService: EventSyncService?
    @Environment(LiveActivityService.self) private var liveActivityService: LiveActivityService
    @FetchAll(StoredEvent.order(by: \.startDate), animation: .default)
    private var storedEvents: [StoredEvent]
    @FetchAll(StoredEventAttendance.all, animation: .default)
    private var storedEventAttendances: [StoredEventAttendance]
    
    @State private var showingAddEventSheet = false
    @State private var selectedEventFilter: EventFilter = .all
    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    @State private var showHistoricalEvents = false
    
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
            .eventBuddyInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .navigation) {
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
            .navigationDestination(for: UUID.self) { eventID in
                EventDetailByIDView(eventID: eventID)
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
        EventBuddyDebouncedSearchField(
            text: $searchText,
            prompt: "Search events",
            cornerRadius: 20
        )
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    private var eventHeaderInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("WWDC26")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(duration: 0.3)) {
                        showHistoricalEvents.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showHistoricalEvents ? "clock.fill" : "clock")
                        Text("History")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(showHistoricalEvents ? .white : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(showHistoricalEvents ? Color.blue : Color.blue.opacity(0.1))
                    )
                }
            }
            
            Text("June 6-12, 2026 • San Jose & Cupertino")
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
                            .eventBuddyFilterChip(isSelected: selectedEventFilter == filter, selectedFill: .blue)
                            .foregroundStyle(selectedEventFilter == filter ? .white : .primary)
                    }
                    .buttonStyle(.plain)
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
                        // No fallback actions in non-preview environments
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
                                
                                ForEach(dayEvents) { eventRow in
                                    NavigationLink(value: eventRow.id) {
                                        EventNavigationRow(
                                            eventRow: eventRow,
                                            isAttending: isAttending(eventRow)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id(eventRow.id)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .animation(.spring(duration: 0.2), value: showOnlyAttending)
            .animation(.spring(duration: 0.2), value: selectedEventFilter)
            .animation(.spring(duration: 0.2), value: showHistoricalEvents)
            .onChange(of: navigationCoordinator?.shouldScrollToEvent) { _, shouldScroll in
                if shouldScroll == true, let eventToShowID = navigationCoordinator?.eventToShowID {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(eventToShowID, anchor: .center)
                    }
                    
                    // After scrolling, wait a moment then navigate to detail
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        navigationPath.append(eventToShowID)
                        navigationCoordinator?.resetNavigation()
                    }
                }
            }
        }
        }
    }
    
    private var filteredEvents: [StoredEvent] {
        var result = storedEvents
        
        // Filter by time (hide past events unless showing historical events)
        if !showHistoricalEvents {
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            
            result = result.filter { event in
                // Show events from today onwards (including past events of today)
                event.startDate >= startOfToday
            }
        }
        
        // Filter by search text
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(query) ||
                event.location.localizedCaseInsensitiveContains(query) ||
                event.eventDescription.localizedCaseInsensitiveContains(query)
            }
        }
        
        // Filter attending events
        if showOnlyAttending {
            result = result.filter { isAttending($0) }
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
    private var groupedEventsByDate: [Date: [StoredEvent]] {
        let calendar = Calendar.current

        var grouped: [Date: [StoredEvent]] = [:]
        for event in filteredEvents {
            let components = calendar.dateComponents([.year, .month, .day], from: event.startDate)
            let date = calendar.date(from: components) ?? event.startDate
            grouped[date, default: []].append(event)
        }
        return grouped
    }

    private var attendanceByEventID: [UUID: Bool] {
        Dictionary(uniqueKeysWithValues: storedEventAttendances.map { ($0.eventID, $0.isAttending) })
    }

    private func isAttending(_ eventRow: StoredEvent) -> Bool {
        attendanceByEventID[eventRow.id] ?? eventRow.isAttending
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
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
              let eventToShowID = coordinator.eventToShowID else {
            return
        }
        
        // Navigate to the specific event
        navigationPath.append(eventToShowID)
        
        // Reset the navigation state
        coordinator.resetNavigation()
    }
}

private struct EventNavigationRow: View {
    let eventRow: StoredEvent
    let isAttending: Bool

    var body: some View {
        EventRowView(eventRow: eventRow, isAttending: isAttending)
    }
}

struct EventDetailByIDView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @FetchAll(StoredEvent.order(by: \.startDate), animation: .default)
    private var storedEvents: [StoredEvent]
    @FetchAll(StoredEventAttendee.all, animation: .default)
    private var storedEventAttendees: [StoredEventAttendee]
    @FetchAll(StoredEventWish.all, animation: .default)
    private var storedEventWishes: [StoredEventWish]
    @FetchAll(StoredEventAttendance.all, animation: .default)
    private var storedEventAttendances: [StoredEventAttendance]
    let eventID: UUID
    @State private var event: Event?
    @State private var checkedEventID: UUID?

    var body: some View {
        Group {
            if let event, event.id == eventID {
                EventDetailView(event: event)
            } else if checkedEventID != eventID {
                ProgressView("Loading event...")
                    .progressViewStyle(.circular)
                    .padding()
            } else {
                ContentUnavailableView("Event Not Found", systemImage: "calendar.badge.exclamationmark")
            }
        }
        .task(id: eventID) {
            refreshEvent()
        }
        .onChange(of: storedEvents.map { "\($0.id.uuidString):\($0.updatedAt.timeIntervalSinceReferenceDate)" }) { _, _ in
            refreshEvent()
        }
        .onChange(of: storedEventAttendees.map(\.id)) { _, _ in
            refreshEvent()
        }
        .onChange(of: storedEventWishes.map(\.id)) { _, _ in
            refreshEvent()
        }
        .onChange(of: storedEventAttendances.map { "\($0.id):\($0.isAttending):\($0.updatedAt.timeIntervalSinceReferenceDate)" }) { _, _ in
            refreshEvent()
        }
        .onAppear {
            refreshEvent()
        }
    }

    private func refreshEvent() {
        if let persistedEvent = eventPersistenceService?.event(for: eventID) {
            event = persistedEvent
            checkedEventID = eventID
            return
        }

        if let storedEventRow = storedEvents.first(where: { $0.id == eventID }) {
            let storedEvent = StoredEvent.initEventFromStored(
                storedEventRow,
                attendance: storedEventAttendances.first { $0.eventID == eventID }
            )
            event = storedEvent
            checkedEventID = eventID
            return
        }

        event = nil
        checkedEventID = eventID
    }
}

private extension StoredEvent {
    static func initEventFromStored(
        _ storedEvent: StoredEvent,
        attendance: StoredEventAttendance? = nil
    ) -> Event {
        let event = Event(
            id: storedEvent.id,
            title: storedEvent.title,
            eventDescription: storedEvent.eventDescription,
            location: storedEvent.location,
            address: storedEvent.address,
            startDate: storedEvent.startDate,
            endDate: storedEvent.endDate,
            eventType: storedEvent.eventType,
            notes: storedEvent.notes,
            requiresTicket: storedEvent.requiresTicket,
            requiresRegistration: storedEvent.requiresRegistration,
            url: storedEvent.url,
            isAttending: attendance?.isAttending ?? storedEvent.isAttending,
            originalTimezoneIdentifier: storedEvent.originalTimezoneIdentifier,
            isCustomEvent: storedEvent.isCustomEvent
        )
        event.createdAt = storedEvent.createdAt
        event.updatedAt = Swift.max(storedEvent.updatedAt, attendance?.updatedAt ?? storedEvent.updatedAt)
        return event
    }
}

#Preview {
    EventListView()
}
