import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import EventKit

struct EventDetailView: View {
    @Bindable var event: Event
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isAddedToCalendar = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCalendarAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                EventHeaderView(event: event, modelContext: modelContext)
                EventDateTimeView(event: event, isAddedToCalendar: isAddedToCalendar)
                EventLocationView(event: event)
                EventAttendeesView(event: event, modelContext: modelContext)
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EventToolbarView(
                    event: event,
                    isAddedToCalendar: isAddedToCalendar,
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
                event.toggleAttending()
                try? modelContext.save()
                isAddedToCalendar = true
            }
        } message: {
            Text("This will add \"\(event.title)\" to your calendar and mark you as attending.")
        }
    }
    
    private func addToCalendar() {
        let eventStore = EKEventStore()
        
        Task {
            do {
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                if granted {
                    let calendarEvent = EKEvent(eventStore: eventStore)
                    calendarEvent.title = event.title
                    calendarEvent.notes = event.eventDescription
                    calendarEvent.location = event.location
                    calendarEvent.startDate = event.startDate
                    calendarEvent.endDate = event.endDate
                    calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
                    
                    try eventStore.save(calendarEvent, span: .thisEvent)
                } else {
                    print("Calendar access denied")
                }
            } catch {
                print("Error saving event to calendar: \(error)")
            }
        }
    }
    
    private func deleteEvent() {
        // Now that we've fixed the circular cascade deletion issue,
        // we can safely delete without manual relationship clearing
        modelContext.delete(event)
        
        do {
            try modelContext.save()
            // Only dismiss after successful deletion
            dismiss()
        } catch {
            print("Error deleting event: \(error)")
            // If deletion fails, we don't dismiss
        }
    }
}

// MARK: - Event Header Component
struct EventHeaderView: View {
    @Bindable var event: Event
    let modelContext: ModelContext
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
                try? modelContext.save()
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
    let modelContext: ModelContext
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
                        modelContext: modelContext,
                        isWishMode: false
                    )
                    SharedFriendSearchSection(
                        event: event,
                        modelContext: modelContext,
                        isWishMode: false,
                        filterText: $filterText
                    )
                    SharedFriendsListSection(
                        event: event,
                        modelContext: modelContext,
                        selectedFriendForDetailEdit: $selectedFriendForDetailEdit,
                        isWishMode: false,
                        filterText: $filterText
                    )
                } else {
                    // Friend Wishes
                    SharedAddFriendSection(
                        event: event,
                        modelContext: modelContext,
                        isWishMode: true
                    )
                    SharedFriendSearchSection(
                        event: event,
                        modelContext: modelContext,
                        isWishMode: true,
                        filterText: $filterText
                    )
                    SharedFriendsListSection(
                        event: event,
                        modelContext: modelContext,
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
    let modelContext: ModelContext
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
        modelContext.insert(friend)
        
        if isWishMode {
            event.addFriendWish(friend)
        } else {
            event.addFriend(friend)
        }
        
        try? modelContext.save()
        
        manualFriendName = ""
        showingAddFriendSheet = false
        isAddFriendFieldFocused = false
    }
}

// MARK: - Shared Friend Search Section
struct SharedFriendSearchSection: View {
    @Bindable var event: Event
    let modelContext: ModelContext
    let isWishMode: Bool
    @Query private var allFriends: [Friend]
    @Binding var filterText: String
    
    private var filteredFriends: [Friend] {
        if filterText.isEmpty {
            return []
        } else {
            return allFriends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(filterText) &&
                !currentFriendsList.contains { $0.id == friend.id }
            }
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
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if !filterText.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    if filteredFriends.isEmpty {
                        Button {
                            createQuickFriend(name: filterText)
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Create \"\(filterText)\"")
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color(.systemGray6).opacity(0.5))
                    }
                    
                    ForEach(filteredFriends) { friend in
                        Button {
                            addFriendToEvent(friend)
                        } label: {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(iconColor)
                                
                                Text(friend.name)
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
                        .background(Color(.systemGray6).opacity(0.3))
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
        try? modelContext.save()
    }
    
    private func createQuickFriend(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let friend = Friend(name: trimmedName)
        modelContext.insert(friend)
        
        if isWishMode {
            event.addFriendWish(friend)
        } else {
            event.addFriend(friend)
        }
        
        try? modelContext.save()
        filterText = ""
    }
}

// MARK: - Shared Friends List Section
struct SharedFriendsListSection: View {
    @Bindable var event: Event
    let modelContext: ModelContext
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
                            try? modelContext.save()
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
                                try? modelContext.save()
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
        try? modelContext.save()
    }
}

// MARK: - Event Toolbar Component
struct EventToolbarView: View {
    let event: Event
    let isAddedToCalendar: Bool
    @Binding var showingCalendarAlert: Bool
    @Binding var showingEditSheet: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        HStack {
            if !isAddedToCalendar {
                Button(action: {
                    showingCalendarAlert = true
                }) {
                    Image(systemName: "calendar.badge.plus")
                }
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
        
        UIApplication.shared.open(url)
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
    .modelContainer(for: [Event.self, Friend.self], inMemory: true)
} 

