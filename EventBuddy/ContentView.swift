//
//  ContentView.swift
//  EventBuddy
//
//  Created by Harry Ng on 16/5/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
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
        if #available(iOS 18, *) {
            modernTabContent
        } else {
            legacyTabContent
        }
        #endif
    }

    @available(iOS 18, *)
    private var modernTabContent: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            Tab("Events", systemImage: "calendar", value: .events) {
                EventListView(
                    navigationCoordinator: navigationCoordinator,
                    searchPresentation: eventMainSearchPresentation
                )
            }

            if includesSearchTab {
                Tab("Search", systemImage: "magnifyingglass", value: .eventSearch, role: .search) {
                    contextualSearchContent
                }
            }

            Tab("Friends", systemImage: "person.2", value: .friends) {
                FriendListView(searchPresentation: friendMainSearchPresentation)
            }

            Tab("Profile", systemImage: "person.circle", value: .profile) {
                ProfileView()
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView(settingsStore: settingsStore)
            }
        }
        .eventBuddySearchTabActivation()
    }

    private var legacyTabContent: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            EventListView(
                navigationCoordinator: navigationCoordinator,
                searchPresentation: eventMainSearchPresentation
            )
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(NavigationCoordinator.AppTab.events)

            if includesSearchTab {
                contextualSearchContent
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(NavigationCoordinator.AppTab.eventSearch)
            }

            FriendListView(searchPresentation: friendMainSearchPresentation)
                .tabItem {
                    Label("Friends", systemImage: "person.2")
                }
                .tag(NavigationCoordinator.AppTab.friends)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(NavigationCoordinator.AppTab.profile)

            SettingsView(settingsStore: settingsStore)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(NavigationCoordinator.AppTab.settings)
        }
    }

    private var includesSearchTab: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #elseif os(visionOS)
        false
        #else
        true
        #endif
    }

    private var eventMainSearchPresentation: EventListView.SearchPresentation {
        #if os(iOS)
        includesSearchTab ? .hidden : .toolbar
        #elseif os(visionOS)
        .toolbar
        #else
        .hidden
        #endif
    }

    private var friendMainSearchPresentation: FriendListView.SearchPresentation {
        #if os(iOS)
        includesSearchTab ? .hidden : .toolbar
        #elseif os(visionOS)
        .toolbar
        #else
        .hidden
        #endif
    }

    @ViewBuilder
    private var contextualSearchContent: some View {
        switch navigationCoordinator.searchContext {
        case .events:
            EventListView(searchPresentation: .tab)
        case .friends:
            FriendListView(searchPresentation: .tab)
        }
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

    @ViewBuilder
    func eventBuddySearchTabActivation() -> some View {
        #if os(iOS)
        if #available(iOS 26, *) {
            self
                .tabViewSearchActivation(.searchTabSelection)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
