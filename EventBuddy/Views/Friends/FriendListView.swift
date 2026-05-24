import SQLiteData
import SwiftUI

struct FriendListView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @FetchAll(StoredFriend.order(by: \.name), animation: .default)
    private var storedFriends: [StoredFriend]
    
    @State private var searchText = ""
    @State private var selectedFilter: FriendFilter = .all
    @State private var showingAddFriendSheet = false
    
    enum FriendFilter: String, CaseIterable {
        case all = "All Friends"
        case favorites = "Favorites"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Friends count and filter
                friendsCount

                // Filter buttons
                filterView

                // Search bar
                searchBar

                // Friends list
                List {
                    ForEach(filteredFriends) { friendRow in
                        NavigationLink {
                            FriendDetailByIDView(friendID: friendRow.id)
                        } label: {
                            FriendRowView(friendRow: friendRow)
                            .swipeActions {
                                NavigationLink(destination: EditFriendView(friend: friendFromRow(friendRow))) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                    
                                    Button(role: .destructive) {
                                        deleteFriend(friendRow)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        toggleFavorite(friendRow)
                                    } label: {
                                        Label(friendRow.isFavorite ? "Unfavorite" : "Favorite",
                                              systemImage: friendRow.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                                .contextMenu {
                                    NavigationLink(destination: EditFriendView(friend: friendFromRow(friendRow))) {
                                        Label("Edit Friend", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        toggleFavorite(friendRow)
                                    } label: {
                                        Label(friendRow.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                              systemImage: friendRow.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        deleteFriend(friendRow)
                                    } label: {
                                        Label("Delete Friend", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .onDelete(perform: deleteFriends)
                }
                .listStyle(.plain)
                .overlay {
                    if filteredFriends.isEmpty {
                        noFriends
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Add friend action
                        showingAddFriendSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddFriendSheet) {
                if let eventPersistenceService {
                    AddFriendView(eventPersistenceService: eventPersistenceService)
                } else {
                    AddFriendView(eventPersistenceService: nil)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search friends", text: $searchText)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.eventBuddySystemGray6)
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var friendsCount: some View {
        HStack {
            Text("Friends")
                .font(.largeTitle)
                .bold()
            Spacer()
            Text("\(filteredFriends.count) connections")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var filterView: some View {
        HStack(spacing: 10) {
            // All Friends filter
            Button {
                selectedFilter = .all
                searchText = ""
            } label: {
                HStack {
                    Image(systemName: selectedFilter == .all ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedFilter == .all ? .blue : .gray)
                    Text(FriendFilter.all.rawValue)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(selectedFilter == .all ?
                              Color.eventBuddySystemGray5 :
                              Color.eventBuddySystemGray6)
                )
            }

            // Favorites filter
            Button {
                selectedFilter = .favorites
                searchText = ""
            } label: {
                HStack {
                    Image(systemName: selectedFilter == .favorites ? "star.fill" : "star")
                        .foregroundColor(selectedFilter == .favorites ? .yellow : .gray)
                    Text(FriendFilter.favorites.rawValue)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(selectedFilter == .favorites ?
                              Color.eventBuddySystemGray5 :
                              Color.eventBuddySystemGray6)
                )
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    // Flag to determine if we're in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var noFriends: some View {
        ContentUnavailableView {
            Label(emptyStateLabel, systemImage: emptyStateIcon)
        } description: {
            Text(emptyStateDescription)
        } actions: {
            if selectedFilter == .all {
                if isPreview {
                    Button("Add Sample Friends") {
                        addSampleFriends()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button("View All Friends") {
                    selectedFilter = .all
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var filteredFriends: [StoredFriend] {
        let searchFiltered = storedFriends.filter { friend in
            if searchText.isEmpty {
                return true
            } else {
                return friend.name.localizedCaseInsensitiveContains(searchText) ||
                       (friend.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                       (friend.phone?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply filter selection
        let filtered: [StoredFriend]
        switch selectedFilter {
        case .all:
            filtered = searchFiltered
        case .favorites:
            filtered = searchFiltered.filter { $0.isFavorite }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private var emptyStateIcon: String {
        selectedFilter == .all ? "person.2.slash" : "star.slash"
    }
    
    private var emptyStateLabel: String {
        selectedFilter == .all ? "No Friends" : "No Favorite Friends"
    }
    
    private var emptyStateDescription: String {
        selectedFilter == .all ? 
        "You don't have any friends in your list yet." : 
        "You don't have any favorite friends yet."
    }
    
    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            deleteFriend(filteredFriends[index])
        }
    }

    private func deleteFriend(_ friendRow: StoredFriend) {
        eventPersistenceService?.deleteFriend(id: friendRow.id)
    }

    private func toggleFavorite(_ friendRow: StoredFriend) {
        let friend = friendFromRow(friendRow)
        friend.toggleFavorite()
        eventPersistenceService?.save(friend)
    }
    
    private func addSampleFriends() {
        // Call FriendService
        eventPersistenceService?.deleteFriends()
        
        let friends = [
            Friend(
                name: "Emily Chen",
                email: "emily@google.com",
                phone: "+1 (555) 123-4567",
                socialMediaHandles: [
                    "linkedin": "emilychen",
                    "github": "emilychen"
                ],
                notes: "Works at Google"
            ),
            
            Friend(
                name: "John Appleseed",
                email: "john@apple.com",
                phone: "+1 (555) 234-5678",
                socialMediaHandles: [
                    "twitter": "johnapple",
                    "linkedin": "johnapple",
                    "github": "johnapple"
                ],
                notes: "Works at Apple"
            ),
            
            Friend(
                name: "Miguel Rodriguez",
                email: "miguel@swiftui.dev",
                phone: "+1 (555) 345-6789",
                socialMediaHandles: [
                    "twitter": "migueldev",
                    "github": "migueldev"
                ],
                notes: "SwiftUI Dev"
            ),
            
            Friend(
                name: "Sarah Thompson",
                email: "sarah@indie.dev",
                phone: "+1 (555) 456-7890",
                socialMediaHandles: [
                    "twitter": "sarahdev",
                    "github": "sarahdev",
                    "linkedin": "saraht"
                ],
                notes: "Indie Developer"
            )
        ]
        
        // Set John and Miguel as favorites
        friends[1].isFavorite = true
        friends[2].isFavorite = true
        
        eventPersistenceService?.save(friends: friends)
    }

    private func friendFromRow(_ friendRow: StoredFriend) -> Friend {
        if let friend = eventPersistenceService?.friend(for: friendRow) {
            return friend
        }

        let friend = Friend(
            id: friendRow.id,
            name: friendRow.name,
            email: friendRow.email,
            phone: friendRow.phone,
            jobTitle: friendRow.jobTitle,
            company: friendRow.company,
            socialMediaHandles: decodeStringDictionary(friendRow.socialMediaHandlesJSON),
            notes: friendRow.notes,
            isFavorite: friendRow.isFavorite
        )
        friend.createdAt = friendRow.createdAt
        friend.updatedAt = friendRow.updatedAt
        return friend
    }

    private func decodeStringDictionary(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let value = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return value
    }
}

private struct FriendDetailByIDView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @FetchAll(StoredFriend.order(by: \.name), animation: .default)
    private var storedFriends: [StoredFriend]
    @FetchAll(StoredEventAttendee.all, animation: .default)
    private var storedEventAttendees: [StoredEventAttendee]
    @FetchAll(StoredEventWish.all, animation: .default)
    private var storedEventWishes: [StoredEventWish]
    @State private var friend: Friend?
    @State private var hasCheckedPersistence = false
    let friendID: UUID

    var body: some View {
        Group {
            if let friend {
                FriendDetailView(friend: friend)
            } else if !hasCheckedPersistence {
                ProgressView("Loading friend...")
                    .progressViewStyle(.circular)
                    .padding()
            } else {
                ContentUnavailableView("Friend Not Found", systemImage: "person.crop.circle.badge.exclamationmark")
            }
        }
        .task { refreshFriend() }
        .onAppear {
            refreshFriend()
        }
        .onChange(of: storedFriends.map { "\($0.id.uuidString):\($0.updatedAt.timeIntervalSinceReferenceDate)" }) { _, _ in
            refreshFriend()
        }
        .onChange(of: storedEventAttendees.map(\.id)) { _, _ in
            refreshFriend()
        }
        .onChange(of: storedEventWishes.map(\.id)) { _, _ in
            refreshFriend()
        }
    }

    private func refreshFriend() {
        if let storedFriend = storedFriends.first(where: { $0.id == friendID }) {
            let mappedFriend = eventPersistenceService?.friend(for: storedFriend) ?? Friend.initFromStored(storedFriend)
            friend = mappedFriend
            hasCheckedPersistence = true
            return
        }

        if let persistedFriend = eventPersistenceService?.friend(for: friendID) {
            friend = persistedFriend
            hasCheckedPersistence = true
            return
        }

        friend = nil
        hasCheckedPersistence = true
    }
}

private extension Friend {
    static func initFromStored(_ storedFriend: StoredFriend) -> Friend {
        let friend = Friend(
            id: storedFriend.id,
            name: storedFriend.name,
            email: storedFriend.email,
            phone: storedFriend.phone,
            jobTitle: storedFriend.jobTitle,
            company: storedFriend.company,
            socialMediaHandles: decodeStoredFriendSocialMedia(storedFriend.socialMediaHandlesJSON),
            notes: storedFriend.notes,
            isFavorite: storedFriend.isFavorite
        )
        friend.createdAt = storedFriend.createdAt
        friend.updatedAt = storedFriend.updatedAt
        return friend
    }

    private static func decodeStoredFriendSocialMedia(_ json: String) -> [String: String] {
        guard let data = json.data(using: .utf8),
              let value = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return value
    }
}

#Preview {
    return FriendListView()
        .environment(EventPersistenceService())
}
