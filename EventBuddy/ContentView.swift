//
//  ContentView.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    
    // Flag to determine if we're in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(0)

            FriendListView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)

            Text("Profile Tab - Coming Soon")
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(2)

            Text("Settings Tab - Coming Soon")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            // Only load sample data when not in preview
            if !isPreview {
                loadSampleData()
            }
        }
    }
    
    private func loadSampleData() {
        // For demonstration purposes, always load sample data
        Task {
            await MainActor.run {
                EventService.addSampleWWDCEvents(modelContext: modelContext)
                FriendService.addSampleFriends(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, Friend.self, Profile.self], inMemory: true)
}
