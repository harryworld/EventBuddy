//
//  ContentView.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @State private var eventSyncService: EventSyncService?
    @State private var showingSyncError = false
    @State private var navigationCoordinator = NavigationCoordinator()
    
    @State private var settingsStore = SettingsStore()
    
    // Flag to determine if we're in preview mode
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        Group {
            if let eventSyncService = eventSyncService {
                mainContent
                    .tabBarMinimumEffect()
                    .environment(eventSyncService)
                    .environment(eventPersistenceService)
                    .alert("Sync Error", isPresented: $showingSyncError) {
                        Button("OK") { }
                        Button("Retry") {
                            Task {
                                await eventSyncService.manualSync()
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
        .preferredColorScheme(settingsStore.settings.appTheme.colorScheme)
        .onAppear {
            if eventSyncService != nil {
                loadInitialData()
            }
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        #if os(macOS)
        MacContentView(
            settingsStore: settingsStore,
            navigationCoordinator: navigationCoordinator
        )
        #else
        TabView(selection: $navigationCoordinator.selectedTab) {
            EventListView(navigationCoordinator: navigationCoordinator)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(0)

            FriendListView()
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(1)

            ProfileView()
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
        #endif
    }
    
    private func setupServices() {
        do {
            _ = try LegacySwiftDataMigration.migrateIfNeeded(persistenceService: eventPersistenceService)
        } catch {
            print("Failed to prepare persistence: \(error)")
        }
        eventSyncService = EventSyncService(persistenceService: eventPersistenceService)
        loadInitialData()
    }
    
    private func loadInitialData() {
        guard let eventSyncService = eventSyncService else { return }
        
        Task {
            // Load friends sample data
            await MainActor.run {
                FriendService.addSampleFriends(eventPersistenceService: eventPersistenceService)
                
                // Add sample profile if none exists
                if ProfileService.getCurrentProfile(persistenceService: eventPersistenceService) == nil {
                    ProfileService.addSampleProfile(persistenceService: eventPersistenceService)
                }
            }
            
            // Sync events from remote JSON file
            if !isPreview {
                // Debug persistence before sync
                eventSyncService.debugPersistence()
                
                await eventSyncService.syncEvents()
                
                // Debug persistence after sync
                eventSyncService.debugPersistence()
                
                // Show error alert if sync failed
                if let syncError = eventSyncService.syncError, !syncError.isEmpty {
                    await MainActor.run {
                        showingSyncError = true
                    }
                }

                await settingsStore.syncCloudKitIfEnabled()
            } else {
                // In preview mode, use the old sample data
                await MainActor.run {
                    EventService.addSampleWWDCEvents(persistenceService: eventPersistenceService)
                }
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "eventbuddy" else { return }
        
        switch url.host {
        case "event":
            if let eventId = UUID(uuidString: url.lastPathComponent) {
                navigationCoordinator.navigateToEvent(with: eventId)
            }
        case "events":
            navigationCoordinator.navigateToEventsTab()
        case "profile":
            navigationCoordinator.navigateToProfileTab()
        default:
            break
        }
    }
}

#Preview {
    let persistenceService = EventPersistenceService()
    return ContentView()
        .environment(persistenceService)
}

extension View {
    @ViewBuilder
    func tabBarMinimumEffect() -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            self
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
