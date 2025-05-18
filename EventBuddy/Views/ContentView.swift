import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    private let userStore = UserStore()
    private let settingsStore = SettingsStore()
    private let eventStore = EventStore()
    private let friendStore = FriendStore()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventListView(eventStore: eventStore, friendStore: friendStore)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(0)
                
            FriendsListView(friendStore: friendStore, eventStore: eventStore)
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)
                
            ProfileView(userStore: userStore)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
                
            SettingsView(settingsStore: settingsStore)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
} 
