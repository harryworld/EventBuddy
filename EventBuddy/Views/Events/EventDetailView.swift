import SwiftUI

struct EventDetailView: View {
    let event: Event
    let eventStore: EventStore
    let friendStore: FriendStore
    @State private var eventFriendService: EventFriendService
    @State private var isAddingFriend = false
    @State private var newFriendName = ""
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @State private var selectedFriend: Friend?
    @State private var showFriendDetail = false
    @State private var showingEditEvent = false
    
    init(event: Event, eventStore: EventStore = EventStore(), friendStore: FriendStore = FriendStore()) {
        self.event = event
        self.eventStore = eventStore
        self.friendStore = friendStore
        self._eventFriendService = State(initialValue: EventFriendService(eventStore: eventStore, friendStore: friendStore))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if event.isCustomEvent {
                            Menu {
                                Button(role: .destructive) {
                                    eventStore.removeCustomEvent(id: event.id)
                                } label: {
                                    Label("Delete Event", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title3)
                            }
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(event.type.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if event.isCustomEvent {
                            Text("(Custom Event)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.bottom, 10)
                
                // Date & Time section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Date & Time")
                        .font(.headline)
                    
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.blue)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            VStack(alignment: .leading) {
                                Text("\(formatDay(event.day)), \(formatYear(event.day))")
                                    .fontWeight(.medium)
                                Text(event.dateTime)
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Add") {
                            // Add to calendar
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 10)
                
                // Location section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.headline)
                    
                    HStack {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                            
                            Text(event.location)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        Button("Map") {
                            // Open map
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 10)
                
                // Description section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(event.description)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 10)
                
                Divider()
                    .padding(.vertical, 5)
                
                // Friends/Attendees section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Attendees")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(eventFriendService.getFriendsForEvent(event: event).count) friends")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !isAddingFriend {
                        Button(action: {
                            isAddingFriend = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                
                                Text("Add Friend")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.vertical, 5)
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Friend name", text: $newFriendName)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .submitLabel(.done)
                                    .focused($isFocused)
                                    .onSubmit {
                                        addNewFriend()
                                    }
                                
                                Button(action: addNewFriend) {
                                    Text("Add")
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(newFriendName.isEmpty)
                            }
                            
                            Button("Cancel") {
                                isAddingFriend = false
                                newFriendName = ""
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.vertical, 5)
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search friends", text: $searchText)
                            .submitLabel(.search)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.vertical, 5)
                    
                    // List of attending friends
                    if eventFriendService.getFriendsForEvent(event: event).isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            
                            Text("No friends added yet")
                                .font(.headline)
                            
                            Text("Tap the 'Add Friend' button to add friends you met at this event.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filteredAttendingFriends) { friend in
                                Button(action: {
                                    navigateToEditFriend(friend)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(friend.name)
                                                .font(.headline)
                                            
                                            if let company = friend.company {
                                                Text(company)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                navigateToEditFriend(friend)
                                            }) {
                                                Image(systemName: "pencil")
                                                    .foregroundStyle(.blue)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Button(action: {
                                                eventFriendService.removeFriendFromEvent(friend: friend, event: event)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.red.opacity(0.7))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Suggestion list based on the search
                    if !searchText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggestions")
                                .font(.headline)
                                .padding(.top)
                            
                            if searchSuggestions.isEmpty {
                                Button(action: {
                                    let newFriend = eventFriendService.addNewFriendToEvent(name: searchText, event: event)
                                    searchText = ""
                                    navigateToEditFriend(newFriend)
                                }) {
                                    HStack {
                                        Text("Create new friend \"\(searchText)\"")
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                            } else {
                                ForEach(searchSuggestions) { friend in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(friend.name)
                                                .font(.headline)
                                            
                                            if let company = friend.company {
                                                Text(company)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            eventFriendService.addFriendToEvent(friend: friend, event: event)
                                            searchText = ""
                                        }) {
                                            Text("Add")
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(Color.blue)
                                                .foregroundStyle(.white)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Divider()
                    .padding(.vertical, 5)
                
                // Related Events section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Related Events")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Events similar to this one")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                    
                    // Placeholder for related events
                    Text("No related events found")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                .padding(.vertical, 5)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Event Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAddingFriend)
        .sheet(isPresented: $showFriendDetail, onDismiss: {
            // Reset the selection
            selectedFriend = nil
        }) {
            if let friend = selectedFriend {
                NavigationStack {
                    EditFriendView(
                        friend: friend,
                        store: friendStore,
                        onSave: {
                            if let index = friendStore.friends.firstIndex(where: { $0.id == friend.id }) {
                                friendStore.friends[index] = friend
                            }
                            showFriendDetail = false
                        },
                        onCancel: {
                            showFriendDetail = false
                        }
                    )
                    .navigationTitle("Edit Friend")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showFriendDetail = false
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                if let index = friendStore.friends.firstIndex(where: { $0.id == friend.id }) {
                                    friendStore.friends[index] = friend
                                }
                                showFriendDetail = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper functions for filtering
    private var filteredAttendingFriends: [Friend] {
        let attendingFriends = eventFriendService.getFriendsForEvent(event: event)
        
        if searchText.isEmpty {
            return attendingFriends.sorted { $0.name < $1.name }
        } else {
            return attendingFriends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) ||
                (friend.company ?? "").localizedCaseInsensitiveContains(searchText)
            }
            .sorted { $0.name < $1.name }
        }
    }
    
    private var searchSuggestions: [Friend] {
        guard !searchText.isEmpty else { return [] }
        
        // Filter friends by search query, but exclude those already attending
        return friendStore.friends.filter { friend in
            (friend.name.localizedCaseInsensitiveContains(searchText) ||
             (friend.company ?? "").localizedCaseInsensitiveContains(searchText)) &&
            !eventFriendService.isFriendAttendingEvent(friend: friend, event: event)
        }
        .sorted { $0.name < $1.name }
    }
    
    private func addNewFriend() {
        guard !newFriendName.isEmpty else { return }
        
        // Check if a friend with this name already exists
        if let existingFriend = eventFriendService.findExistingFriend(name: newFriendName) {
            // If exists, add to event
            eventFriendService.addFriendToEvent(friend: existingFriend, event: event)
            
            // Reset fields
            newFriendName = ""
            isAddingFriend = false
        } else {
            // Create new friend and add to event
            let newFriend = eventFriendService.addNewFriendToEvent(name: newFriendName, event: event)
            
            // Reset fields
            newFriendName = ""
            isAddingFriend = false
            
            // Navigate to edit the new friend's details
            navigateToEditFriend(newFriend)
        }
    }
    
    // New function to directly edit a friend's details
    private func navigateToEditFriend(_ friend: Friend) {
        // Set the selected friend and show the edit sheet directly
        selectedFriend = friend
        showFriendDetail = true
    }
    
    // Helper functions to format date strings
    private func formatDay(_ fullDay: String) -> String {
        if let commaIndex = fullDay.firstIndex(of: ",") {
            let dayName = fullDay[..<commaIndex]
            return String(dayName)
        }
        return fullDay
    }
    
    private func formatYear(_ fullDay: String) -> String {
        if let startIndex = fullDay.range(of: "June")?.lowerBound {
            return String(fullDay[startIndex...])
        }
        return ""
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: EventStore().events.first!)
    }
} 
