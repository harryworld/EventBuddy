import Foundation
import SwiftData

@MainActor
@Observable
class EventSyncService {
    private let modelContext: ModelContext
    private let eventsURL = "https://eventbuddy.buildwithharry.com/events.json"
    
    var isLoading = false
    var lastSyncDate: Date?
    var syncError: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Fetches events from the remote JSON file and synchronizes with local storage
    func syncEvents() async {
        isLoading = true
        syncError = nil
        
        do {
            let eventsResponse = try await fetchEventsFromJSON()
            try await synchronizeEvents(from: eventsResponse.events)
            lastSyncDate = Date()
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
