import Foundation
import SwiftData

@MainActor
@Observable
class EventSyncService {
    private let modelContext: ModelContext
    private let jsonFileName = "events.json"
    
    var isLoading = false
    var lastSyncDate: Date?
    var syncError: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Fetches events from the JSON file and synchronizes with local storage
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
        }
        
        isLoading = false
    }
    
    /// Forces a complete refresh by clearing local events and re-fetching
    func forceRefresh() async {
        isLoading = true
        syncError = nil
        
        do {
            // Clear existing events
            try modelContext.delete(model: Event.self)
            
            // Fetch and add new events
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
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func fetchEventsFromJSON() async throws -> EventsResponse {
        guard let url = Bundle.main.url(forResource: jsonFileName.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            throw EventSyncError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
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
}

// MARK: - Error Types

enum EventSyncError: LocalizedError {
    case fileNotFound
    case invalidData
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Events JSON file not found in app bundle"
        case .invalidData:
            return "Invalid data format in events JSON file"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
} 
