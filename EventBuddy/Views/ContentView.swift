import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(0)
                
            FriendsListView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)
                
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
                
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .tabItem {
                    Label("Settings", systemImage: "clock")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
} 