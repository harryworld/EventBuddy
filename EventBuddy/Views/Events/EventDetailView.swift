import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import EventKit

struct EventDetailView: View {
    @Bindable var event: Event
    @State private var searchText = ""
    @State private var showingAddFriendSheet = false
    @State private var newFriendName = ""
    @State private var isAddingQuickFriend = false
    @State private var selectedFriendForDetailEdit: Friend? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAddFriendFieldFocused: Bool
    @State private var isAddedToCalendar = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingDescriptionPopover = false
    @State private var showingCalendarAlert = false

    @Query private var allFriends: [Friend]
    
    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return []
        } else {
            return allFriends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) &&
                !event.attendees.contains { $0.id == friend.id }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title with attending button
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.largeTitle)
                            .bold()
                        
                        HStack {
                            Text(event.eventType)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                showingDescriptionPopover = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showingDescriptionPopover, arrowEdge: .top) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Description")
                                        .font(.headline)
                                    
                                    Text(event.eventDescription)
                                        .font(.body)
                                }
                                .padding()
                                .frame(maxWidth: 300)
                                .presentationCompactAdaptation(.none)
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
                
                // Date & Time in one line
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
                
                // Location Section
                SectionContainer(title: event.location, icon: "mappin.circle.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading) {
                            if let address = event.address, !address.isEmpty {
                                Text(address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Embedded Map with reduced height
                        EventMapView(event: event)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Attendees Section
                SectionContainer(title: "Attendees", icon: "person.2.fill", trailingText: "\(event.attendees.count) friends") {
                    // Quick Add Friend Button/Field
                    if showingAddFriendSheet {
                        HStack {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundColor(.blue)
                            
                            TextField("Friend name", text: $newFriendName)
                                .font(.body)
                                .submitLabel(.done)
                                .focused($isAddFriendFieldFocused)
                                .onSubmit {
                                    addQuickFriend()
                                }
                            
                            Button {
                                addQuickFriend()
                            } label: {
                                Text("Save")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(newFriendName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                            .disabled(newFriendName.isEmpty)
                            
                            Button {
                                showingAddFriendSheet = false
                                newFriendName = ""
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
                        // Add Friend Button
                        Button(action: {
                            showingAddFriendSheet = true
                            // Set focus after a short delay to allow the view to update
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isAddFriendFieldFocused = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                
                                Text("Add Friend")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Search field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search or create new friend", text: $searchText)
                                .font(.body)
                                .submitLabel(.search)
                                .onChange(of: searchText) { _, newValue in
                                    // Reset quick add state if search changes
                                    if isAddingQuickFriend && newValue != newFriendName {
                                        isAddingQuickFriend = false
                                    }
                                }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        // Search results
                        if !searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                if filteredFriends.isEmpty && !isAddingQuickFriend {
                                    Button {
                                        isAddingQuickFriend = true
                                        newFriendName = searchText
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                            Text("Create \"\(searchText)\"")
                                            Spacer()
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.plain)
                                    .background(Color(.systemGray6).opacity(0.5))
                                }
                                
                                if isAddingQuickFriend {
                                    HStack {
                                        Image(systemName: "person.fill.badge.plus")
                                        TextField("Confirm name", text: $newFriendName)
                                            .submitLabel(.done)
                                            .onSubmit {
                                                addQuickFriend()
                                            }
                                        
                                        Button("Save") {
                                            addQuickFriend()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                }
                                
                                ForEach(filteredFriends) { friend in
                                    Button {
                                        addFriendToEvent(friend)
                                    } label: {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                            
                                            Text(friend.name)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "plus.circle")
                                                .foregroundColor(.green)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
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
                    
                    if !event.attendees.isEmpty {
                        HStack {
                            Text("Attending")
                                .font(.headline)
                            
                            Spacer()
                        }
                        .padding(.top, 12)
                        
                        ForEach(event.attendees) { friend in
                            // Normal display mode
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(friend.name)
                                    .font(.body)
                                
                                Spacer()
                                
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
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        removeFriendFromEvent(friend)
                                    } label: {
                                        Label("Remove", systemImage: "xmark.circle")
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
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    // Add to Calendar button
                    if !isAddedToCalendar {
                        Button(action: {
                            showingCalendarAlert = true
                        }) {
                            Image(systemName: "calendar.badge.plus")
                        }
                    }
                    
                    // Event menu or website button
                    if event.isCustomEvent {
                        Menu {
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
        }
        .sheet(item: $selectedFriendForDetailEdit) { friend in
            EditFriendView(friend: friend)
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
    
    private func addFriendToEvent(_ friend: Friend) {
        event.addFriend(friend)
        searchText = ""
        try? modelContext.save()
    }
    
    private func removeFriendFromEvent(_ friend: Friend) {
        event.removeFriend(friend.id)
        try? modelContext.save()
    }
    
    private func addQuickFriend() {
        guard !newFriendName.isEmpty else { return }
        
        // Create new friend with trimmed name
        let trimmedName = newFriendName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let friend = Friend(name: trimmedName)
        modelContext.insert(friend)
        
        // Add to event
        event.addFriend(friend)
        try? modelContext.save()
        
        // Reset UI state
        newFriendName = ""
        showingAddFriendSheet = false
        isAddingQuickFriend = false
        isAddFriendFieldFocused = false
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        
        // Use the event's original timezone if available, otherwise current timezone
        if let originalTimezone = event.originalTimezoneIdentifier,
           let eventTimezone = TimeZone(identifier: originalTimezone) {
            dateFormatter.timeZone = eventTimezone
        } else {
            dateFormatter.timeZone = TimeZone.current
        }

        // Get the day number
        let day = Calendar.current.component(.day, from: event.startDate)
        
        // Add the appropriate suffix
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        // Format the date without the day, then add the day with suffix
        return dateFormatter.string(from: event.startDate) + suffix
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        // Use the event's original timezone if available
        if let originalTimezone = event.originalTimezoneIdentifier,
           let eventTimezone = TimeZone(identifier: originalTimezone) {
            formatter.timeZone = eventTimezone
        }

        let startTime = formatter.string(from: event.startDate)
        let endTime = formatter.string(from: event.endDate)
        
        return "\(startTime)-\(endTime)"
    }

    private var formattedTimeTimeZone: String {
        guard let originalTimezone = event.originalTimezoneIdentifier,
              let eventTimezone = TimeZone(identifier: originalTimezone) else {
            // Fallback to current timezone
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
        
        // Always show only the original timezone
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

    private func addToCalendar() {
        let eventStore = EKEventStore()
        
        Task {
            do {
                // Request calendar access
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                if granted {
                    // Create calendar event
                    let calendarEvent = EKEvent(eventStore: eventStore)
                    calendarEvent.title = event.title
                    calendarEvent.notes = event.eventDescription
                    calendarEvent.location = event.location
                    calendarEvent.startDate = event.startDate
                    calendarEvent.endDate = event.endDate
                    
                    // Set calendar to default
                    calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
                    
                    // Save event
                    try eventStore.save(calendarEvent, span: .thisEvent)
                    // Show success feedback
                    await MainActor.run {
                        // You might want to add a success alert or haptic feedback here
                    }
                } else {
                    print("Calendar access denied")
                }
            } catch {
                print("Error saving event to calendar: \(error)")
            }
        }
    }
    
    private func openMap() {
        // Use geocoding to find the location and open in Maps
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(event.location) { placemarks, error in
            if let placemark = placemarks?.first,
               let _ = placemark.location {
                let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                mapItem.name = event.title
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ])
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
    
    private func deleteEvent() {
        modelContext.delete(event)
        try? modelContext.save()
        dismiss()
    }
}

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
