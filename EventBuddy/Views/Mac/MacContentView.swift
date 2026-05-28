#if os(macOS)
import SQLiteData
import SwiftUI

struct MacContentView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @Environment(EventSyncService.self) private var eventSyncService

    let settingsStore: SettingsStore
    let navigationCoordinator: NavigationCoordinator

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selection: MacSidebarSelection? = .events
    @State private var selectedEventID: UUID?
    @State private var selectedFriendID: UUID?
    @State private var showingAddEventSheet = false
    @State private var showingAddFriendSheet = false

    private var activeSelection: MacSidebarSelection {
        selection ?? .events
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            MacSidebar(selection: $selection)
                .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 260)
        } detail: {
            detailContent
                .macFlexibleDetailSurface()
                .navigationTitle(activeSelection.title)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        toolbarItems
                    }
                }
        }
        .frame(minWidth: MacWorkspaceLayout.windowMinimumWidth, minHeight: 640)
        .sheet(isPresented: $showingAddEventSheet) {
            AddEventView()
        }
        .sheet(isPresented: $showingAddFriendSheet) {
            AddFriendView(eventPersistenceService: eventPersistenceService)
        }
        .onChange(of: navigationCoordinator.selectedTab) { _, selectedTab in
            if let sidebarSelection = MacSidebarSelection(tabIndex: selectedTab) {
                selection = sidebarSelection
            }
        }
        .onChange(of: navigationCoordinator.shouldNavigateToEvent) { _, shouldNavigate in
            guard shouldNavigate, let eventID = navigationCoordinator.eventToShowID else { return }
            selection = .events
            selectedEventID = eventID
            navigationCoordinator.resetNavigation()
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch activeSelection {
        case .events:
            MacEventsWorkspace(selectedEventID: $selectedEventID)
        case .friends:
            MacFriendsWorkspace(selectedFriendID: $selectedFriendID)
        case .profile:
            MacProfileWorkspace()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .settings:
            MacSettingsWorkspace(settingsStore: settingsStore)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var toolbarItems: some View {
        switch activeSelection {
        case .events:
            Button {
                Task { await eventSyncService.manualSync() }
            } label: {
                Label("Sync Events", systemImage: "arrow.clockwise")
            }
            .disabled(eventSyncService.isLoading)
            .help("Sync events")

            Button {
                showingAddEventSheet = true
            } label: {
                Label("New Event", systemImage: "plus")
            }
            .help("Create a new event")
        case .friends:
            Button {
                showingAddFriendSheet = true
            } label: {
                Label("New Friend", systemImage: "plus")
            }
            .help("Create a new friend")
        case .profile, .settings:
            EmptyView()
        }
    }
}

private enum MacSidebarSelection: String, CaseIterable, Identifiable, Hashable {
    case events
    case friends
    case profile
    case settings

    var id: String { rawValue }

    init?(tabIndex: Int) {
        switch tabIndex {
        case 0: self = .events
        case 1: self = .friends
        case 2: self = .profile
        case 3: self = .settings
        default: return nil
        }
    }

    var title: String {
        switch self {
        case .events:
            return "Events"
        case .friends:
            return "Friends"
        case .profile:
            return "Profile"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .events:
            return "calendar"
        case .friends:
            return "person.2"
        case .profile:
            return "person.crop.circle"
        case .settings:
            return "gearshape"
        }
    }
}

private struct MacSidebar: View {
    @Binding var selection: MacSidebarSelection?

    var body: some View {
        List(selection: $selection) {
            Section("WWDCBuddy") {
                sidebarRow(.events)
                sidebarRow(.friends)
            }

            Section("Personal") {
                sidebarRow(.profile)
                sidebarRow(.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("WWDCBuddy")
    }

    private func sidebarRow(_ item: MacSidebarSelection) -> some View {
        Label(item.title, systemImage: item.systemImage)
            .tag(item)
    }
}

private enum MacWorkspaceLayout {
    static let windowMinimumWidth: CGFloat = 1_330
    static let listColumnWidth: CGFloat = 380
    static let detailMinimumWidth: CGFloat = 500
}

private extension View {
    func macWorkspaceListColumn() -> some View {
        frame(
            minWidth: MacWorkspaceLayout.listColumnWidth,
            idealWidth: MacWorkspaceLayout.listColumnWidth,
            maxWidth: MacWorkspaceLayout.listColumnWidth,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }

    func macWorkspaceContentList() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.eventBuddySystemBackground)
    }

    func macFlexibleDetailSurface() -> some View {
        frame(
            minWidth: MacWorkspaceLayout.detailMinimumWidth,
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .layoutPriority(1)
    }
}

private struct MacEventsWorkspace: View {
    @Environment(EventSyncService.self) private var eventSyncService
    @FetchAll(StoredEvent.order(by: \.startDate), animation: .default)
    private var storedEvents: [StoredEvent]
    @FetchAll(StoredEventAttendance.all, animation: .default)
    private var storedEventAttendances: [StoredEventAttendance]

    @Binding var selectedEventID: UUID?
    @State private var selectedFilter: MacEventFilter = .all
    @State private var searchText = ""
    @AppStorage("showOnlyAttending") private var showOnlyAttending = false
    @State private var showHistoricalEvents = false

    var body: some View {
        HSplitView {
            EventBuddyDebouncedSearchable(text: $searchText, prompt: "Search events") {
                VStack(spacing: 0) {
                    MacEventFilterBar(
                        selectedFilter: $selectedFilter,
                        showOnlyAttending: $showOnlyAttending,
                        showHistoricalEvents: $showHistoricalEvents,
                        eventCount: filteredEvents.count,
                        isLoading: eventSyncService.isLoading,
                        lastSyncDate: eventSyncService.lastSyncDate
                    )

                    Divider()

                    if filteredEvents.isEmpty {
                        ContentUnavailableView {
                            Label("No Events", systemImage: "calendar.badge.exclamationmark")
                        } description: {
                            Text("No WWDC events match the current filters.")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(selection: $selectedEventID) {
                            ForEach(groupedEventSections) { section in
                                MacEventDaySection(
                                    section: section,
                                    attendanceByEventID: attendanceByEventID
                                )
                            }
                        }
                        .macWorkspaceContentList()
                        .frame(maxWidth: .infinity)
                    }
                }
                .macWorkspaceListColumn()
            }

            MacEventDetailPane(selectedEventID: selectedEventID)
                .macFlexibleDetailSurface()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear(perform: selectFirstEventIfNeeded)
        .onChange(of: filteredEvents.map(\.id)) { _, _ in
            selectFirstEventIfNeeded()
        }
    }

    private var filteredEvents: [StoredEvent] {
        var result = storedEvents

        if !showHistoricalEvents {
            let startOfToday = Calendar.current.startOfDay(for: Date())
            result = result.filter { $0.startDate >= startOfToday }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { event in
                event.title.localizedCaseInsensitiveContains(query) ||
                event.location.localizedCaseInsensitiveContains(query) ||
                event.eventDescription.localizedCaseInsensitiveContains(query)
            }
        }

        if showOnlyAttending {
            result = result.filter { isAttending($0) }
        }

        switch selectedFilter {
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

    private var groupedEventsByDate: [Date: [StoredEvent]] {
        Dictionary(grouping: filteredEvents) { event in
            Calendar.current.startOfDay(for: event.startDate)
        }
    }

    private var groupedEventSections: [MacEventDayGroup] {
        groupedEventsByDate.keys.sorted().compactMap { date in
            guard let events = groupedEventsByDate[date] else { return nil }
            return MacEventDayGroup(date: date, events: events)
        }
    }

    private var attendanceByEventID: [UUID: Bool] {
        Dictionary(uniqueKeysWithValues: storedEventAttendances.map { ($0.eventID, $0.isAttending) })
    }

    private func isAttending(_ eventRow: StoredEvent) -> Bool {
        attendanceByEventID[eventRow.id] ?? eventRow.isAttending
    }

    private func selectFirstEventIfNeeded() {
        guard !filteredEvents.contains(where: { $0.id == selectedEventID }) else { return }
        selectedEventID = filteredEvents.first?.id
    }
}

private struct MacEventDayGroup: Identifiable {
    let date: Date
    let events: [StoredEvent]

    var id: Date { date }
}

private struct MacEventDaySection: View {
    let section: MacEventDayGroup
    let attendanceByEventID: [UUID: Bool]

    var body: some View {
        Section(formatDateHeader(section.date)) {
            ForEach(section.events) { eventRow in
                MacEventRow(
                    eventRow: eventRow,
                    isAttending: attendanceByEventID[eventRow.id] ?? eventRow.isAttending
                )
                    .tag(eventRow.id)
            }
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

private enum MacEventFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case keynote = "Keynote"
    case watchParty = "Watch Party"
    case social = "Social"
    case meetup = "Meetup"

    var id: String { rawValue }
}

private struct MacEventFilterBar: View {
    @Binding var selectedFilter: MacEventFilter
    @Binding var showOnlyAttending: Bool
    @Binding var showHistoricalEvents: Bool
    let eventCount: Int
    let isLoading: Bool
    let lastSyncDate: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("WWDC26")
                        .font(.title2.weight(.semibold))

                    Text(summaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Picker("Event Type", selection: $selectedFilter) {
                ForEach(MacEventFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                Toggle("Attending", isOn: $showOnlyAttending)
                Toggle("History", isOn: $showHistoricalEvents)
            }
            .toggleStyle(.checkbox)
            .font(.callout)
        }
        .padding(16)
    }

    private var summaryText: String {
        let syncText: String
        if let lastSyncDate {
            syncText = "Synced \(relativeDateFormatter.localizedString(for: lastSyncDate, relativeTo: Date()))"
        } else {
            syncText = "Not synced yet"
        }
        return "\(eventCount) events - \(syncText)"
    }

    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

private struct MacEventRow: View {
    let eventRow: StoredEvent
    let isAttending: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime)
                    .font(.callout.monospacedDigit().weight(.medium))

                Text(formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58, alignment: .trailing)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(eventRow.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)

                    if isAttending {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                HStack(spacing: 6) {
                    Label(eventRow.location.isEmpty ? "No location" : eventRow.location, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)

                    Text(eventRow.eventType)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
        .opacity(eventRow.endDate < Date() ? 0.48 : 1)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: eventRow.startDate)
    }

    private var formattedDuration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: eventRow.endDate)
    }
}

private struct MacEventDetailPane: View {
    let selectedEventID: UUID?

    var body: some View {
        Group {
            if let selectedEventID {
                EventDetailByIDView(eventID: selectedEventID)
            } else {
                ContentUnavailableView {
                    Label("Select an Event", systemImage: "calendar")
                } description: {
                    Text("Choose an event from the list to see its details.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.eventBuddySystemBackground)
    }
}

private struct MacFriendsWorkspace: View {
    @FetchAll(StoredFriend.order(by: \.name), animation: .default)
    private var storedFriends: [StoredFriend]

    @Binding var selectedFriendID: UUID?
    @State private var selectedFilter: MacFriendFilter = .all
    @State private var searchText = ""
    @FocusState private var focusedPane: MacFriendWorkspaceFocus?

    var body: some View {
        HSplitView {
            EventBuddyDebouncedSearchable(text: $searchText, prompt: "Search friends") {
                VStack(spacing: 0) {
                    MacFriendFilterBar(
                        selectedFilter: $selectedFilter,
                        friendCount: filteredFriends.count
                    )

                    Divider()

                    if filteredFriends.isEmpty {
                        ContentUnavailableView {
                            Label("No Friends", systemImage: "person.2.slash")
                        } description: {
                            Text("No contacts match the current filters.")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(selection: $selectedFriendID) {
                            ForEach(filteredFriends) { friendRow in
                                MacFriendRow(friendRow: friendRow)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedFriendID = friendRow.id
                                        focusFriendList()
                                    }
                                    .tag(friendRow.id)
                            }
                        }
                        .macWorkspaceContentList()
                        .focusable()
                        .focused($focusedPane, equals: .friendList)
                        .onMoveCommand(perform: moveFriendSelection)
                        .frame(maxWidth: .infinity)
                    }
                }
                .macWorkspaceListColumn()
            }

            MacFriendDetailPane(selectedFriendID: selectedFriendID)
                .macFlexibleDetailSurface()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            selectFirstFriendIfNeeded()
            focusFriendList()
        }
        .onChange(of: filteredFriends.map(\.id)) { _, _ in
            selectFirstFriendIfNeeded()
        }
    }

    private var filteredFriends: [StoredFriend] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = storedFriends.filter { friend in
            guard !query.isEmpty else { return true }
            return friend.name.localizedCaseInsensitiveContains(query) ||
                (friend.email?.localizedCaseInsensitiveContains(query) ?? false) ||
                (friend.phone?.localizedCaseInsensitiveContains(query) ?? false) ||
                (friend.company?.localizedCaseInsensitiveContains(query) ?? false)
        }

        switch selectedFilter {
        case .all:
            return searched
        case .favorites:
            return searched.filter { $0.isFavorite }
        }
    }

    private func selectFirstFriendIfNeeded() {
        guard !filteredFriends.contains(where: { $0.id == selectedFriendID }) else { return }
        selectedFriendID = filteredFriends.first?.id
    }

    private func focusFriendList() {
        guard !filteredFriends.isEmpty else { return }
        focusedPane = .friendList
    }

    private func moveFriendSelection(_ direction: MoveCommandDirection) {
        guard focusedPane == .friendList, !filteredFriends.isEmpty else { return }

        let currentIndex = selectedFriendID.flatMap { selectedID in
            filteredFriends.firstIndex { $0.id == selectedID }
        }
        let nextIndex: Int

        switch direction {
        case .up:
            nextIndex = currentIndex.map { max($0 - 1, 0) } ?? filteredFriends.count - 1
        case .down:
            nextIndex = currentIndex.map { min($0 + 1, filteredFriends.count - 1) } ?? 0
        default:
            return
        }

        selectedFriendID = filteredFriends[nextIndex].id
    }
}

private enum MacFriendWorkspaceFocus: Hashable {
    case friendList
}

private enum MacFriendFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"

    var id: String { rawValue }
}

private struct MacFriendFilterBar: View {
    @Binding var selectedFilter: MacFriendFilter
    let friendCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Friends")
                        .font(.title2.weight(.semibold))

                    Text("\(friendCount) connections")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Picker("Friend Filter", selection: $selectedFilter) {
                ForEach(MacFriendFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
        .padding(16)
    }
}

private struct MacFriendRow: View {
    let friendRow: StoredFriend

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: friendRow.isFavorite ? "star.circle.fill" : "person.crop.circle")
                .symbolRenderingMode(friendRow.isFavorite ? .multicolor : .hierarchical)
                .font(.title3)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(friendRow.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                if !professionalInfo.isEmpty {
                    Text(professionalInfo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let email = friendRow.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var professionalInfo: String {
        switch (friendRow.jobTitle, friendRow.company) {
        case let (jobTitle?, company?) where !jobTitle.isEmpty && !company.isEmpty:
            return "\(jobTitle) at \(company)"
        case let (jobTitle?, _) where !jobTitle.isEmpty:
            return jobTitle
        case let (_, company?) where !company.isEmpty:
            return company
        default:
            return ""
        }
    }
}

private struct MacFriendDetailPane: View {
    let selectedFriendID: UUID?

    var body: some View {
        Group {
            if let selectedFriendID {
                FriendDetailByIDView(friendID: selectedFriendID)
            } else {
                ContentUnavailableView {
                    Label("Select a Friend", systemImage: "person.crop.circle")
                } description: {
                    Text("Choose a contact from the list to see their details.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.eventBuddySystemBackground)
    }
}
#endif
