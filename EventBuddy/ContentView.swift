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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EventListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(0)

            Text("Friends Tab - Coming Soon")
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
            // Always add sample data for demonstration purposes
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // For demonstration purposes, always load sample data
        Task {
            await MainActor.run {
                EventService.addSampleWWDCEvents(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, Friend.self, Profile.self])
}
