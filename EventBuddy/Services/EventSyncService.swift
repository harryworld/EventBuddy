import Foundation
import SwiftData

@MainActor
@Observable
class EventSyncService {
    private let modelContext: ModelContext
    private let eventsURL = "https://eventbuddy.buildwithharry.com/events.json"
    
    // Sync frequency control
    private let automaticSyncThreshold: TimeInterval = 3600 // 1 hour in seconds
    private let minimumSyncInterval: TimeInterval = 300 // 5 minutes minimum between any syncs
    
    // UserDefaults key for persisting last sync date
    private let lastSyncDateKey = "EventSyncService.lastSyncDate"
    
    var isLoading = false
    var lastSyncDate: Date? {
        didSet {
            // Persist the last sync date to UserDefaults
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: lastSyncDateKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSyncDateKey)
            }
        }
    }
    var syncError: String?
    var isManualSyncBlocked = false // New property to track when manual sync is blocked
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Restore last sync date from UserDefaults
        self.lastSyncDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
        print("Restored last sync date: \(lastSyncDate?.description ?? "None")")
    }
    
    // MARK: - Public Methods
    
    /// Fetches events from the remote JSON file and synchronizes with local storage
    /// This method respects the automatic sync threshold
    func syncEvents() async {
        await syncEvents(forceSync: false)
    }
    
    /// Manually triggered sync that bypasses the automatic threshold but respects minimum interval
    func manualSync() async {
        // Clear any previous blocked state
        isManualSyncBlocked = false
        
        // Check minimum interval for manual syncs
        if !shouldRespectMinimumInterval() {
            print("⏭️ Manual sync blocked - minimum interval not met. Last sync: \(formatLastSyncTime())")
            isManualSyncBlocked = true
            
            // Clear the blocked state after a short delay to show the indicator briefly
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                isManualSyncBlocked = false
            }
            return
        }
        
        await syncEvents(forceSync: true)
    }
    
    /// Internal sync method with force option
    private func syncEvents(forceSync: Bool) async {
        print("🔄 Sync requested - Force: \(forceSync), Last sync: \(formatLastSyncTime())")
        
        // Check if we should skip this sync
        if !forceSync && !shouldPerformAutomaticSync() {
            print("⏭️ Skipping automatic sync - threshold not met. Last sync: \(formatLastSyncTime())")
            return
        }
        
        // Check minimum interval for all syncs (including manual)
        if !shouldRespectMinimumInterval() {
            print("⏭️ Skipping sync - minimum interval not met. Last sync: \(formatLastSyncTime())")
            return
        }
        
        print("✅ Proceeding with sync...")
        
        isLoading = true
        syncError = nil
        
        do {
            let eventsResponse = try await fetchEventsFromJSON()
            try await synchronizeEvents(from: eventsResponse.events)
            lastSyncDate = Date()
            print("Sync completed successfully at \(formatCurrentTime())")
        } catch {
            syncError = "Failed to sync events: \(error.localizedDescription)"
            print("Error syncing events: \(error)")
            
            // If this is the first time and we have no local events, try to load from bundle as fallback
            if await hasNoLocalEvents() {
                await loadFallbackEvents()
            }
        }
        
        isLoading = false
    }
    
    /// Tests the connection to the remote events URL
    func testConnection() async -> Bool {
        guard let url = URL(string: eventsURL) else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                let success = (200...299).contains(httpResponse.statusCode)
                print("Connection test result: \(success ? "SUCCESS" : "FAILED") - Status: \(httpResponse.statusCode)")
                return success
            }
            return false
        } catch {
            print("Connection test failed: \(error)")
            return false
        }
    }
    
    /// Simple test method to verify remote connection
    func performConnectionTest() async {
        print("Testing connection to: \(eventsURL)")
        let isConnected = await testConnection()
        print("Connection test completed: \(isConnected ? "✅ SUCCESS" : "❌ FAILED")")
    }
    
    /// Test method to verify sync frequency functionality
    func testSyncFrequency() async {
        print("🧪 Testing sync frequency functionality...")
        
        // Test 1: First sync should always work
        print("Test 1: First sync (should work)")
        await syncEvents(forceSync: false)
        
        // Test 2: Immediate second sync should be skipped due to threshold
        print("Test 2: Immediate second sync (should be skipped)")
        await syncEvents(forceSync: false)
        
        // Test 3: Manual sync should work despite threshold
        print("Test 3: Manual sync (should work)")
        await manualSync()
        
        // Test 4: Another manual sync should be blocked by minimum interval
        print("Test 4: Another manual sync (should be blocked by minimum interval)")
        await manualSync()
        
        print("🧪 Sync frequency test completed!")
    }
    
    /// Debug method to check persistence
    func debugPersistence() {
        let storedDate = UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
        print("🔍 Debug Persistence:")
        print("  - Current lastSyncDate: \(lastSyncDate?.description ?? "nil")")
        print("  - Stored in UserDefaults: \(storedDate?.description ?? "nil")")
        print("  - Should perform automatic sync: \(shouldPerformAutomaticSync())")
        
        if let lastSync = lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            print("  - Time since last sync: \(Int(timeSinceLastSync)) seconds")
            print("  - Automatic threshold: \(Int(automaticSyncThreshold)) seconds")
            print("  - Threshold met: \(timeSinceLastSync >= automaticSyncThreshold)")
        }
    }
    
    /// Forces a complete refresh by clearing local events and re-fetching from remote
    func forceRefresh() async {
        isLoading = true
        syncError = nil
        
        do {
            // Clear existing events
            try modelContext.delete(model: Event.self)
            
            // Fetch and add new events from remote
            let eventsResponse = try await fetchEventsFromJSON()
            for eventDTO in eventsResponse.events {
                if let event = eventDTO.toEvent() {
                    modelContext.insert(event)
                }
            }
            
            try modelContext.save()
            lastSyncDate = Date()
        } catch {
            syncError = "Failed to refresh events: \(error.localizedDescription)"
            print("Error refreshing events: \(error)")
            
            // If refresh fails, try to restore from bundle
            await loadFallbackEvents()
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func fetchEventsFromJSON() async throws -> EventsResponse {
        guard let url = URL(string: eventsURL) else {
            throw EventSyncError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw EventSyncError.networkError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(EventsResponse.self, from: data)
    }
    
    private func synchronizeEvents(from eventDTOs: [EventDTO]) async throws {
        // Get existing events from local storage
        let descriptor = FetchDescriptor<Event>()
        let existingEvents = try modelContext.fetch(descriptor)
        
        // Create a dictionary for quick lookup
        var existingEventsDict: [UUID: Event] = [:]
        for event in existingEvents {
            existingEventsDict[event.id] = event
        }
        
        var eventsToAdd: [Event] = []
        var eventsToUpdate: [Event] = []
        var processedEventIds: Set<UUID> = []
        
        // Process each event from JSON
        for eventDTO in eventDTOs {
            guard let eventId = UUID(uuidString: eventDTO.id) else {
                print("Invalid UUID for event: \(eventDTO.title)")
                continue
            }
            
            processedEventIds.insert(eventId)
            
            if let existingEvent = existingEventsDict[eventId] {
                // Event exists, check if it needs updating
                if existingEvent.needsUpdate(from: eventDTO) {
                    existingEvent.update(from: eventDTO)
                    eventsToUpdate.append(existingEvent)
                }
            } else {
                // New event, add it
                if let newEvent = eventDTO.toEvent() {
                    eventsToAdd.append(newEvent)
                }
            }
        }
        
        // Add new events
        for event in eventsToAdd {
            modelContext.insert(event)
        }
        
        // Save changes
        try modelContext.save()
        
        print("Sync completed: \(eventsToAdd.count) added, \(eventsToUpdate.count) updated")
    }
    
    private func hasNoLocalEvents() async -> Bool {
        do {
            let descriptor = FetchDescriptor<Event>()
            let existingEvents = try modelContext.fetch(descriptor)
            return existingEvents.isEmpty
        } catch {
            return true
        }
    }
    
    private func loadFallbackEvents() async {
        // Try to load from local bundle as fallback
        guard let url = Bundle.main.url(forResource: "events", withExtension: "json") else {
            print("No fallback events file found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let eventsResponse = try decoder.decode(EventsResponse.self, from: data)
            
            for eventDTO in eventsResponse.events {
                if let event = eventDTO.toEvent() {
                    modelContext.insert(event)
                }
            }
            
            try modelContext.save()
            print("Loaded \(eventsResponse.events.count) fallback events from bundle")
        } catch {
            print("Failed to load fallback events: \(error)")
        }
    }
    
    /// Checks if automatic sync should be performed based on threshold
    private func shouldPerformAutomaticSync() -> Bool {
        guard let lastSync = lastSyncDate else {
            // No previous sync, allow it
            print("📅 No previous sync found - allowing automatic sync")
            return true
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let thresholdMet = timeSinceLastSync >= automaticSyncThreshold
        
        print("📊 Threshold check: \(Int(timeSinceLastSync))s since last sync, threshold: \(Int(automaticSyncThreshold))s, met: \(thresholdMet)")
        
        return thresholdMet
    }
    
    /// Checks if minimum interval has passed since last sync
    private func shouldRespectMinimumInterval() -> Bool {
        guard let lastSync = lastSyncDate else {
            // No previous sync, allow it
            return true
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        return timeSinceLastSync >= minimumSyncInterval
    }
    
    /// Formats the last sync time for logging
    private func formatLastSyncTime() -> String {
        guard let lastSync = lastSyncDate else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: lastSync)
    }
    
    /// Formats the current time for logging
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
    
    /// Gets time until next automatic sync is allowed
    func timeUntilNextAutomaticSync() -> TimeInterval? {
        guard let lastSync = lastSyncDate else {
            return nil // Can sync immediately
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let timeRemaining = automaticSyncThreshold - timeSinceLastSync
        
        return timeRemaining > 0 ? timeRemaining : nil
    }
    
    /// Gets time until next manual sync is allowed
    func timeUntilNextManualSync() -> TimeInterval? {
        guard let lastSync = lastSyncDate else {
            return nil // Can sync immediately
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let timeRemaining = minimumSyncInterval - timeSinceLastSync
        
        return timeRemaining > 0 ? timeRemaining : nil
    }
    
    /// Gets formatted string for time until next sync
    func formattedTimeUntilNextSync() -> String? {
        guard let timeRemaining = timeUntilNextAutomaticSync() else {
            return nil
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Gets formatted string for time until next manual sync is allowed
    func formattedTimeUntilNextManualSync() -> String? {
        guard let timeRemaining = timeUntilNextManualSync() else {
            return nil
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    /// Gets a user-friendly sync status message
    var syncStatusMessage: String {
        if isLoading {
            return "Syncing events..."
        }
        
        if let syncError = syncError, !syncError.isEmpty {
            return "Sync failed - tap refresh to retry"
        }
        
        guard let lastSync = lastSyncDate else {
            return "Events not synced yet"
        }
        
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        if timeSinceLastSync < automaticSyncThreshold {
            return "Events up to date"
        } else {
            return "Events may be outdated - tap refresh"
        }
    }
}

// MARK: - Error Types

enum EventSyncError: LocalizedError {
    case invalidURL
    case networkError(Int)
    case invalidData
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid events URL"
        case .networkError(let statusCode):
            return "Network error: HTTP \(statusCode)"
        case .invalidData:
            return "Invalid data format in events JSON"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
} 
