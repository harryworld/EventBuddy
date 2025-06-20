import SwiftUI
import SwiftData

struct FriendListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]
    
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
                    ForEach(filteredFriends) { friend in
                        NavigationLink {
                            FriendDetailView(friend: friend)
                        } label: {
                            FriendRowView(friend: friend)
                                .swipeActions {
                                    NavigationLink(destination: EditFriendView(friend: friend)) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                    
                                    Button(role: .destructive) {
                                        modelContext.delete(friend)
                                        try? modelContext.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        friend.toggleFavorite()
                                        try? modelContext.save()
                                    } label: {
                                        Label(friend.isFavorite ? "Unfavorite" : "Favorite", 
                                              systemImage: friend.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    .tint(.yellow)
                                }
                                .contextMenu {
                                    NavigationLink(destination: EditFriendView(friend: friend)) {
                                        Label("Edit Friend", systemImage: "pencil")
                                    }
                                    
                                    Button {
                                        friend.toggleFavorite()
                                        try? modelContext.save()
                                    } label: {
                                        Label(friend.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                              systemImage: friend.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        modelContext.delete(friend)
                                        try? modelContext.save()
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
                AddFriendView()
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
        .background(Color(uiColor: .systemGray6))
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
                              Color(uiColor: .systemGray5) :
                              Color(uiColor: .systemGray6))
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
                              Color(uiColor: .systemGray5) :
                              Color(uiColor: .systemGray6))
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

    private var filteredFriends: [Friend] {
        let searchFiltered = friends.filter { friend in
            if searchText.isEmpty {
                return true
            } else {
                return friend.name.localizedCaseInsensitiveContains(searchText) ||
                       (friend.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                       (friend.phone?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply filter selection
        let filtered: [Friend]
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
            modelContext.delete(filteredFriends[index])
        }
    }
    
    private func addSampleFriends() {
        // Call FriendService
        do {
            try modelContext.delete(model: Friend.self)
            
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
            
            for friend in friends {
                modelContext.insert(friend)
            }
        } catch {
            print("Error adding sample friends: \(error)")
        }
    }
}

#Preview {
    FriendListView()
        .modelContainer(for: Friend.self, inMemory: true)
} 
