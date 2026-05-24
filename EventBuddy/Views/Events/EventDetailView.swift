import SwiftUI
import MapKit
import CoreLocation
import SQLiteData

struct EventDetailView: View {
    @Bindable var event: Event
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @Environment(\.dismiss) private var dismiss
    @State private var calendarStore = EventCalendarStore()
    @State private var isAddedToCalendar = false
    @State private var isAddingToCalendar = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCalendarAlert = false
    @State private var showingCalendarErrorAlert = false
    @State private var calendarErrorMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                EventHeaderView(event: event, eventPersistenceService: eventPersistenceService)
                EventDateTimeView(event: event, isAddedToCalendar: isAddedToCalendar)
                EventLocationView(event: event)
                EventAttendeesView(event: event, eventPersistenceService: eventPersistenceService)
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .eventBuddyInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EventToolbarView(
                    event: event,
                    isAddedToCalendar: isAddedToCalendar,
                    isAddingToCalendar: isAddingToCalendar,
                    showingCalendarAlert: $showingCalendarAlert,
                    showingEditSheet: $showingEditSheet,
                    showingDeleteAlert: $showingDeleteAlert
                )
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event)
        }
        .alert("Delete Event", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .alert("Add to Calendar", isPresented: $showingCalendarAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addToCalendar()
            }
        } message: {
            Text("This will add \"\(event.title)\" to your selected calendar if it is not already there and mark you as attending.")
        }
        .alert("Calendar Error", isPresented: $showingCalendarErrorAlert) {
            Button("OK") { }
        } message: {
            Text(calendarErrorMessage)
        }
        .task {
            refreshCalendarAddedState()
        }
    }
    
    private func addToCalendar() {
        Task { @MainActor in
            isAddingToCalendar = true
            defer { isAddingToCalendar = false }

            let outcome = await calendarStore.add(event)
            guard outcome.foundOrAddedEvent else {
                calendarErrorMessage = calendarErrorMessage(for: outcome)
                showingCalendarErrorAlert = true
                return
            }

            if !event.isAttending {
                event.toggleAttending()
                eventPersistenceService?.save(event)
            }
            isAddedToCalendar = true
        }
    }

    private func refreshCalendarAddedState() {
        calendarStore.refreshAuthorizationStatus()
        guard calendarStore.hasFullAccess else { return }
        isAddedToCalendar = calendarStore.eventExists(event)
    }

    private func calendarErrorMessage(for outcome: EventCalendarStore.AddOutcome) -> String {
        switch outcome {
        case .added, .alreadyExists:
            return ""
        case .accessDenied:
            return "Calendar access is required before adding events."
        case .noWritableCalendar:
            return "No writable calendar is available."
        case let .failed(message):
            return message
        }
    }
    
    private func deleteEvent() {
        // Now that we've fixed the circular cascade deletion issue,
        // we can safely delete without manual relationship clearing
        eventPersistenceService?.delete(event)
        // Only dismiss after successful deletion
        dismiss()
    }
}

// MARK: - Event Header Component
struct EventHeaderView: View {
    @Bindable var event: Event
    let eventPersistenceService: EventPersistenceService?
    @State private var showingDescriptionPopover = false
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.largeTitle)
                    .bold()
                
                HStack {
                    Text(event.eventType)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !event.eventDescription.isEmpty {
                        Button {
                            showingDescriptionPopover = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingDescriptionPopover, arrowEdge: .top) {
                            EventDescriptionPopover(description: event.eventDescription)
                        }
                    }
                }
            }
            
            Spacer()
            
    Button(action: {
                event.toggleAttending()
                eventPersistenceService?.save(event)
            }) {
                Image(systemName: event.isAttending ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.title2)
                    .foregroundColor(event.isAttending ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Event Description Popover
struct EventDescriptionPopover: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
            
            Text(description)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(idealWidth: 200, maxWidth: 320, idealHeight: nil, maxHeight: .infinity)
        .padding()
        .presentationCompactAdaptation(.popover)
    }
}

// MARK: - Event Date Time Component
struct EventDateTimeView: View {
    let event: Event
    let isAddedToCalendar: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
            
            Text("\(formattedDate) • \(formattedTimeTimeZone)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if isAddedToCalendar {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Added")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.bottom, 8)
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        if let originalTimezone = event.originalTimezoneIdentifier,
           let eventTimezone = TimeZone(identifier: originalTimezone) {
            dateFormatter.timeZone = eventTimezone
        } else {
            dateFormatter.timeZone = TimeZone.current
        }

        let day = Calendar.current.component(.day, from: event.startDate)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return dateFormatter.string(from: event.startDate) + suffix
    }
    
    private var formattedTimeTimeZone: String {
        guard let originalTimezone = event.originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mma"
            formatter.amSymbol = "AM"
            formatter.pmSymbol = "PM"
            formatter.timeZone = TimeZone.current
            
            let startTime = formatter.string(from: event.startDate)
            
            formatter.dateFormat = "h:mma zzz"
            formatter.locale = Locale(identifier: "en_US")
            let endTime = formatter.string(from: event.endDate)
            
            return "\(startTime)-\(endTime)"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        formatter.timeZone = eventTimezone
        
        let startTime = formatter.string(from: event.startDate)
        
        formatter.dateFormat = "h:mma zzz"
        formatter.locale = Locale(identifier: "en_US")
        let endTime = formatter.string(from: event.endDate)
        
        return "\(startTime)-\(endTime)"
    }
}

// MARK: - Event Location Component
struct EventLocationView: View {
    let event: Event
    
    var body: some View {
        SectionContainer(title: event.location.isEmpty ? "Location" : event.location, icon: "mappin.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if event.location.isEmpty {
                    Text("No location specified")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                } else if let address = event.address, !address.isEmpty {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if !event.location.isEmpty {
                    EventMapView(event: event)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

// MARK: - Event Attendees Component
struct EventAttendeesView: View {
    @Bindable var event: Event
    let eventPersistenceService: EventPersistenceService?
    @State private var selectedFriendForDetailEdit: Friend? = nil
    @State private var selectedTab = 0 // 0 for People Met, 1 for Friend Wishes
    @State private var filterText = ""
    
    var body: some View {
        SectionContainer(title: "People", icon: "person.2.fill", trailingText: "\(event.attendees.count + event.friendWishes.count) total") {
            VStack(spacing: 16) {
                // Segmented Control
                Picker("People Type", selection: $selectedTab) {
                    Text("People Met (\(event.attendees.count))").tag(0)
                    Text("Friend Wishes (\(event.friendWishes.count))").tag(1)
                }
                .pickerStyle(.segmented)
                
                // Content based on selected tab
                if selectedTab == 0 {
                    // People Met (Attendees)
                    SharedAddFriendSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        isWishMode: false
                    )
                    SharedFriendSearchSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        isWishMode: false,
                        filterText: $filterText
                    )
                    SharedFriendsListSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        selectedFriendForDetailEdit: $selectedFriendForDetailEdit,
                        isWishMode: false,
                        filterText: $filterText
                    )
                } else {
                    // Friend Wishes
                    SharedAddFriendSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        isWishMode: true
                    )
                    SharedFriendSearchSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        isWishMode: true,
                        filterText: $filterText
                    )
                    SharedFriendsListSection(
                        event: event,
                        eventPersistenceService: eventPersistenceService,
                        selectedFriendForDetailEdit: $selectedFriendForDetailEdit,
                        isWishMode: true,
                        filterText: $filterText
                    )
                }
            }
        }
        .sheet(item: $selectedFriendForDetailEdit) { friend in
            EditFriendView(friend: friend)
        }
    }
}

// MARK: - Shared Add Friend Section
struct SharedAddFriendSection: View {
    @Bindable var event: Event
    let eventPersistenceService: EventPersistenceService?
    let isWishMode: Bool
    @State private var showingAddFriendSheet = false
    @State private var manualFriendName = ""
    @FocusState private var isAddFriendFieldFocused: Bool
    
    private var buttonColor: Color {
        isWishMode ? .orange : .blue
    }
    
    private var buttonText: String {
        isWishMode ? "Add Friend Wish" : "Add Friend"
    }
    
    var body: some View {
        if showingAddFriendSheet {
            HStack {
                Image(systemName: "person.fill.badge.plus")
                    .foregroundColor(buttonColor)
                
                TextField("Friend name", text: $manualFriendName)
                    .font(.body)
                    .submitLabel(.done)
                    .focused($isAddFriendFieldFocused)
                    .onSubmit {
                        createManualFriend()
                    }
                
                if !manualFriendName.isEmpty {
                    Button {
                        manualFriendName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    createManualFriend()
                } label: {
                    Text("Save")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(manualFriendName.isEmpty ? Color.gray : buttonColor)
                .cornerRadius(8)
                .disabled(manualFriendName.isEmpty)
                
                Button {
                    showingAddFriendSheet = false
                    manualFriendName = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
            )
        } else {
            Button(action: {
                showingAddFriendSheet = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAddFriendFieldFocused = true
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(buttonColor)
                    
                    Text(buttonText)
                        .fontWeight(.medium)
                        .foregroundColor(buttonColor)
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    private func createManualFriend() {
        let trimmedName = manualFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let friend = Friend(name: trimmedName)
        
        if isWishMode {
            event.addFriendWish(friend)
        } else {
            event.addFriend(friend)
        }

        eventPersistenceService?.save(event)
        
        manualFriendName = ""
        showingAddFriendSheet = false
        isAddFriendFieldFocused = false
    }
}

// MARK: - Shared Friend Search Section
struct SharedFriendSearchSection: View {
    @Bindable var event: Event
    let eventPersistenceService: EventPersistenceService?
    let isWishMode: Bool
    @Binding var filterText: String
    @FetchAll(StoredFriend.order(by: \.name), animation: .default)
    private var storedFriends: [StoredFriend]
    
    private var trimmedFilterText: String {
        filterText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var currentFriendIDs: Set<UUID> {
        Set(currentFriendsList.map(\.id))
    }

    private var filteredFriendRows: [StoredFriend] {
        let query = trimmedFilterText
        guard !query.isEmpty else {
            return []
        }

        let excludedIDs = currentFriendIDs
        return storedFriends.filter { friend in
            friend.name.localizedCaseInsensitiveContains(query) &&
            !excludedIDs.contains(friend.id)
        }
    }
    
    private var currentFriendsList: [Friend] {
        isWishMode ? event.friendWishes : event.attendees
    }
    
    private var placeholderText: String {
        isWishMode ? "Search or create new friend wish" : "Search or create new friend"
    }
    
    private var iconColor: Color {
        isWishMode ? .orange : .blue
    }
    
    private var addIconColor: Color {
        isWishMode ? .orange : .green
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholderText, text: $filterText)
                    .font(.body)
                    .submitLabel(.search)
                
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.eventBuddySystemGray6)
            .cornerRadius(8)
            
            if !trimmedFilterText.isEmpty {
                let friendRows = filteredFriendRows

                LazyVStack(alignment: .leading, spacing: 0) {
                    if friendRows.isEmpty {
                        Button {
                            createQuickFriend(name: filterText)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create \"\(trimmedFilterText)\"")
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.eventBuddySystemGray6.opacity(0.5))
                    }
                    
                    ForEach(friendRows) { friendRow in
                        Button {
                            addFriendToEvent(makeFriend(from: friendRow))
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(iconColor)
                                
                                Text(friendRow.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(addIconColor)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.eventBuddySystemGray6.opacity(0.3))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private func addFriendToEvent(_ friend: Friend) {
        if isWishMode {
            event.addFriendWish(friend)
        } else {
            event.addFriend(friend)
        }
        filterText = ""
        eventPersistenceService?.save(event)
    }
    
    private func createQuickFriend(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let friend = Friend(name: trimmedName)
        
        if isWishMode {
            event.addFriendWish(friend)
        } else {
            event.addFriend(friend)
        }
        
        eventPersistenceService?.save(event)
        filterText = ""
    }

    private func makeFriend(from row: StoredFriend) -> Friend {
        let friend = Friend(
            id: row.id,
            name: row.name,
            email: row.email,
            phone: row.phone,
            jobTitle: row.jobTitle,
            company: row.company,
            socialMediaHandles: decodeStringDictionary(row.socialMediaHandlesJSON),
            notes: row.notes,
            isFavorite: row.isFavorite
        )
        friend.createdAt = row.createdAt
        friend.updatedAt = row.updatedAt
        return friend
    }

    private func decodeStringDictionary(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let value = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return value
    }
}

// MARK: - Shared Friends List Section
struct SharedFriendsListSection: View {
    @Bindable var event: Event
    let eventPersistenceService: EventPersistenceService?
    @Binding var selectedFriendForDetailEdit: Friend?
    let isWishMode: Bool
    @Binding var filterText: String
    
    private var friendsList: [Friend] {
        isWishMode ? event.friendWishes : event.attendees
    }
    
    private var filteredFriendsList: [Friend] {
        if filterText.isEmpty {
            return friendsList
        } else {
            return friendsList.filter { friend in
                friend.name.localizedCaseInsensitiveContains(filterText) ||
                (friend.email?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                (friend.phone?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                (friend.company?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                (friend.jobTitle?.localizedCaseInsensitiveContains(filterText) ?? false)
            }
        }
    }
    
    private var sectionTitle: String {
        isWishMode ? "Friend Wishes" : "Attending"
    }
    
    private var iconColor: Color {
        isWishMode ? .orange : .blue
    }
    
    var body: some View {
        if !friendsList.isEmpty {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                
                Spacer()
                
                Text("\(filteredFriendsList.count) of \(friendsList.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
            
            ForEach(filteredFriendsList) { friend in
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(iconColor)
                    
                    Text(friend.name)
                        .font(.body)
                    
                    Spacer()
                    
                    // Show "Mark as Met" button only for friend wishes
                    if isWishMode {
                        Button {
                            event.markFriendAsMet(friend)
                            eventPersistenceService?.save(event)
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        selectedFriendForDetailEdit = friend
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            selectedFriendForDetailEdit = friend
                        } label: {
                            Label("Edit Friend", systemImage: "pencil")
                        }
                        
                        if isWishMode {
                            Button {
                                event.markFriendAsMet(friend)
                                eventPersistenceService?.save(event)
                            } label: {
                                Label("Mark as Met", systemImage: "checkmark.circle")
                            }
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            removeFriendFromEvent(friend)
                        } label: {
                            Label(isWishMode ? "Remove Wish" : "Remove", systemImage: "xmark.circle")
                        }
                    }
                    
                    Button {
                        removeFriendFromEvent(friend)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func removeFriendFromEvent(_ friend: Friend) {
        if isWishMode {
            event.removeFriendWish(friend.id)
        } else {
            event.removeFriend(friend.id)
        }
        eventPersistenceService?.save(event)
    }
}

// MARK: - Event Toolbar Component
struct EventToolbarView: View {
    let event: Event
    let isAddedToCalendar: Bool
    let isAddingToCalendar: Bool
    @Environment(\.openURL) private var openURL
    @Binding var showingCalendarAlert: Bool
    @Binding var showingEditSheet: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        HStack {
            if !isAddedToCalendar {
                Button(action: {
                    showingCalendarAlert = true
                }) {
                    if isAddingToCalendar {
                        ProgressView()
                    } else {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
                .disabled(isAddingToCalendar)
            }
            
            if event.isCustomEvent {
                Menu {
                    Button {
                        openEventWebsite()
                    } label: {
                        Label("Visit Website", systemImage: "globe")
                    }
                    .disabled(event.url == nil)

                    Divider()

                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Event", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Event", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            } else {
                Button {
                    openEventWebsite()
                } label: {
                    Image(systemName: "globe")
                }
                .disabled(event.url == nil)
            }
        }
    }
    
    private func openEventWebsite() {
        guard let urlString = event.url,
              let url = URL(string: urlString) else {
            return
        }
        
        openURL(url)
    }
}

// MARK: - Section Container (unchanged)
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
    .environment(EventPersistenceService())
} 
