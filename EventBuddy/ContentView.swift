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
    @State private var eventSyncService: EventSyncService?
    @State private var showingSyncError = false
    
    private let userStore = UserStore()
    private let settingsStore = SettingsStore()
    
    // Flag to determine if we're in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        Group {
            if let eventSyncService = eventSyncService {
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

                    ProfileView(userStore: userStore)
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                        .tag(2)

                    SettingsView(settingsStore: settingsStore)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(3)
                }
                .environment(eventSyncService)
                .alert("Sync Error", isPresented: $showingSyncError) {
                    Button("OK") { }
                    Button("Retry") {
                        Task {
                            await eventSyncService.syncEvents()
                        }
                    }
                } message: {
                    Text(eventSyncService.syncError ?? "Unknown error occurred")
                }
            } else {
                ProgressView("Loading...")
                    .onAppear {
                        setupServices()
                    }
            }
        }
        .onAppear {
            if eventSyncService != nil {
                loadInitialData()
            }
        }
    }
    
    private func setupServices() {
        eventSyncService = EventSyncService(modelContext: modelContext)
        loadInitialData()
    }
    
    private func loadInitialData() {
        guard let eventSyncService = eventSyncService else { return }
        
        Task {
            // Load friends sample data
            await MainActor.run {
                FriendService.addSampleFriends(modelContext: modelContext)
            }
            
            // Sync events from remote JSON file
            if !isPreview {
                await eventSyncService.syncEvents()
                
                // Show error alert if sync failed
                if let syncError = eventSyncService.syncError, !syncError.isEmpty {
                    await MainActor.run {
                        showingSyncError = true
                    }
                }
            } else {
                // In preview mode, use the old sample data
                await MainActor.run {
                    EventService.addSampleWWDCEvents(modelContext: modelContext)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Event.self, Friend.self], inMemory: true)
}

