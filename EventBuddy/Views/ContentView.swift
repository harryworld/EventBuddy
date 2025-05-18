import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Events Tab
                if selectedTab == 0 {
                    EventListView(selectedTab: $selectedTab)
                }
                
                // Friends Tab
                if selectedTab == 1 {
                    FriendsListView(selectedTab: $selectedTab)
                }
                
                // Profile Tab (placeholder)
                if selectedTab == 2 {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                // Settings Tab (placeholder)
                if selectedTab == 3 {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
            
            TabBarView(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    ContentView()
} 