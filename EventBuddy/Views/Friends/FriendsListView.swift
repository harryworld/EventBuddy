import SwiftUI
import Foundation

@Observable class Friend: Identifiable {
    let id = UUID()
    var name: String
    var phoneNumber: String?
    var email: String?
    var company: String?
    var isFavorite: Bool
    var notes: String?
    var meetLocation: String?
    var meetTime: Date?
    var attendedEventIds: [UUID] = [] // Events the friend has attended
    
    init(name: String, phoneNumber: String? = nil, email: String? = nil, 
         company: String? = nil, isFavorite: Bool = false, notes: String? = nil,
         meetLocation: String? = nil, meetTime: Date? = nil, attendedEventIds: [UUID] = []) {
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.company = company
        self.isFavorite = isFavorite
        self.notes = notes
        self.meetLocation = meetLocation
        self.meetTime = meetTime
        self.attendedEventIds = attendedEventIds
    }
    
    func addAttendedEvent(_ eventId: UUID) {
        if !attendedEventIds.contains(eventId) {
            attendedEventIds.append(eventId)
        }
    }
    
    func removeAttendedEvent(_ eventId: UUID) {
        attendedEventIds.removeAll { $0 == eventId }
    }
    
    func hasAttendedEvent(_ eventId: UUID) -> Bool {
        return attendedEventIds.contains(eventId)
    }
}

@Observable class FriendStore {
    var friends: [Friend] = []
    
    init() {
        loadSampleFriends()
    }
    
    private func loadSampleFriends() {
        friends.append(Friend(name: "John Appleseed", 
                              phoneNumber: "555-123-4567", 
                              email: "john@apple.com", 
                              company: "Apple", 
                              isFavorite: true, 
                              notes: "Met at WWDC Keynote",
                              meetLocation: "Apple Park"))
        
        friends.append(Friend(name: "Sarah Thompson", 
                              phoneNumber: "555-765-4321", 
                              email: "sarah@gmail.com", 
                              company: "Indie Developer"))
        
        friends.append(Friend(name: "Miguel Rodriguez", 
                              email: "miguel@swiftui.dev", 
                              company: "SwiftUI Dev", 
                              isFavorite: true))
        
        friends.append(Friend(name: "Emily Chen", 
                              phoneNumber: "555-987-6543", 
                              company: "Google", 
                              notes: "Interested in Vision Pro development"))
    }
    
    func addFriend(_ friend: Friend) {
        friends.append(friend)
    }
    
    func removeFriend(at indexSet: IndexSet) {
        friends.remove(atOffsets: indexSet)
    }
    
    func toggleFavorite(_ friend: Friend) {
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index].isFavorite.toggle()
        }
    }
    
    // New methods to manage events and friends
    func addFriendToEvent(friendId: UUID, eventId: UUID) {
        if let friendIndex = friends.firstIndex(where: { $0.id == friendId }) {
            friends[friendIndex].addAttendedEvent(eventId)
        }
    }
    
    func removeFriendFromEvent(friendId: UUID, eventId: UUID) {
        if let friendIndex = friends.firstIndex(where: { $0.id == friendId }) {
            friends[friendIndex].removeAttendedEvent(eventId)
        }
    }
    
    func getFriendsForEvent(eventId: UUID) -> [Friend] {
        return friends.filter { $0.hasAttendedEvent(eventId) }
    }
    
    func getFriendById(_ id: UUID) -> Friend? {
        return friends.first { $0.id == id }
    }
}

struct FriendsListView: View {
    let friendStore: FriendStore
    let eventStore: EventStore
    @State private var searchText = ""
    @State private var isAddingFriend = false
    @State private var newFriendName = ""
    @State private var showFavorites = false
    
    init(friendStore: FriendStore = FriendStore(), eventStore: EventStore = EventStore()) {
        self.friendStore = friendStore
        self.eventStore = eventStore
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Friends header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Friends")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("\(friendStore.friends.count) connections")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingFriend = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Quick add friend bar (shows when isAddingFriend is true)
                if isAddingFriend {
                    HStack {
                        TextField("New friend name", text: $newFriendName)
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
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(newFriendName.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Filter controls
                HStack {
                    Button(action: {
                        showFavorites.toggle()
                    }) {
                        HStack {
                            Image(systemName: showFavorites ? "star.fill" : "star")
                                .foregroundColor(showFavorites ? .yellow : .gray)
                            Text(showFavorites ? "Favorites" : "All Friends")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Friends List
                List {
                    ForEach(filteredFriends) { friend in
                        FriendRow(friend: friend, store: friendStore, eventStore: eventStore)
                            .swipeActions {
                                Button(role: .destructive) {
                                    if let index = friendStore.friends.firstIndex(where: { $0.id == friend.id }) {
                                        friendStore.removeFriend(at: IndexSet([index]))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    friendStore.toggleFavorite(friend)
                                } label: {
                                    Label(friend.isFavorite ? "Unfavorite" : "Favorite", 
                                          systemImage: friend.isFavorite ? "star.slash" : "star")
                                }
                                .tint(friend.isFavorite ? .gray : .yellow)
                            }
                    }
                    .onDelete { indexSet in
                        friendStore.removeFriend(at: indexSet)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search friends")
            }
            .animation(.easeInOut(duration: 0.2), value: isAddingFriend)
        }
    }
    
    @FocusState private var isFocused: Bool
    
    private func addNewFriend() {
        guard !newFriendName.isEmpty else { return }
        
        let friend = Friend(name: newFriendName.trimmingCharacters(in: .whitespacesAndNewlines))
        friendStore.addFriend(friend)
        
        // Reset fields
        newFriendName = ""
        isAddingFriend = false
    }
    
    var filteredFriends: [Friend] {
        var friends = friendStore.friends
        
        // Filter by favorites
        if showFavorites {
            friends = friends.filter { $0.isFavorite }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            friends = friends.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) ||
                (friend.company ?? "").localizedCaseInsensitiveContains(searchText) ||
                (friend.email ?? "").localizedCaseInsensitiveContains(searchText) ||
                (friend.phoneNumber ?? "").localizedCaseInsensitiveContains(searchText) ||
                (friend.notes ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort alphabetically by name
        return friends.sorted { $0.name < $1.name }
    }
}

struct FriendRow: View {
    let friend: Friend
    let store: FriendStore
    let eventStore: EventStore
    
    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend, store: store, eventStore: eventStore)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(friend.name)
                            .font(.headline)
                        
                        if friend.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                        }
                    }
                    
                    if let company = friend.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if friend.phoneNumber != nil || friend.email != nil {
                    HStack(spacing: 16) {
                        if friend.phoneNumber != nil {
                            Image(systemName: "phone")
                                .foregroundColor(.blue)
                        }
                        if friend.email != nil {
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    FriendsListView()
} 