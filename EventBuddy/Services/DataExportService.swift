import Foundation
import SwiftData
import UniformTypeIdentifiers
import Compression

@MainActor
@Observable
class DataExportService {
    private let modelContext: ModelContext
    
    var isExporting = false
    var exportError: String?
    var exportProgress: Double = 0.0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Export Function
    
    func exportAllData() async -> URL? {
        isExporting = true
        exportError = nil
        exportProgress = 0.0
        
        defer {
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            // Create temporary directory for export files
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("EventBuddyExport_\(Date().timeIntervalSince1970)")
            
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            exportProgress = 0.1
            
            // Export JSON backup
            let jsonURL = try await exportJSONBackup(to: tempDir)
            exportProgress = 0.4
            
            // Export CSV files
            let eventsCSVURL = try await exportEventsCSV(to: tempDir)
            exportProgress = 0.6
            
            let friendsCSVURL = try await exportFriendsCSV(to: tempDir)
            exportProgress = 0.8
            
            // Create archive
            let archiveURL = try createArchive(
                files: [jsonURL, eventsCSVURL, friendsCSVURL],
                in: tempDir
            )
            exportProgress = 1.0
            
            return archiveURL
            
        } catch {
            exportError = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - JSON Export
    
    private func exportJSONBackup(to directory: URL) async throws -> URL {
        let fileURL = directory.appendingPathComponent("eventbuddy_backup.json")
        
        // Fetch all data
        let eventDescriptor = FetchDescriptor<Event>()
        let events = try modelContext.fetch(eventDescriptor)
        
        let friendDescriptor = FetchDescriptor<Friend>()
        let friends = try modelContext.fetch(friendDescriptor)
        
        // Create backup structure
        let backup = DataBackup(
            exportDate: Date(),
            version: "1.0",
            events: events.map { $0.toExportDTO() },
            friends: friends.map { $0.toExportDTO() },
            relationships: createRelationshipData(events: events, friends: friends)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(backup)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - CSV Export
    
    private func exportEventsCSV(to directory: URL) async throws -> URL {
        let fileURL = directory.appendingPathComponent("events.csv")
        
        let eventDescriptor = FetchDescriptor<Event>()
        let events = try modelContext.fetch(eventDescriptor)
        
        var csvContent = "ID,Title,Description,Location,Address,Start Date,End Date,Event Type,Notes,Requires Ticket,Requires Registration,URL,Is Attending,Is Custom Event,Created At,Updated At,Attendee Count,Wish Count\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for event in events {
            let row = [
                event.id.uuidString,
                csvEscape(event.title),
                csvEscape(event.eventDescription),
                csvEscape(event.location),
                csvEscape(event.address ?? ""),
                dateFormatter.string(from: event.startDate),
                dateFormatter.string(from: event.endDate),
                csvEscape(event.eventType),
                csvEscape(event.notes ?? ""),
                event.requiresTicket ? "Yes" : "No",
                event.requiresRegistration ? "Yes" : "No",
                csvEscape(event.url ?? ""),
                event.isAttending ? "Yes" : "No",
                event.isCustomEvent ? "Yes" : "No",
                dateFormatter.string(from: event.createdAt),
                dateFormatter.string(from: event.updatedAt),
                "\(event.attendees.count)",
                "\(event.friendWishes.count)"
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func exportFriendsCSV(to directory: URL) async throws -> URL {
        let fileURL = directory.appendingPathComponent("friends.csv")
        
        let friendDescriptor = FetchDescriptor<Friend>()
        let friends = try modelContext.fetch(friendDescriptor)
        
        var csvContent = "ID,Name,Email,Phone,Job Title,Company,Notes,Is Favorite,Created At,Updated At,Events Count,Wish Events Count,Social Media\n"
        
        let dateFormatter = ISO8601DateFormatter()
        
        for friend in friends {
            let socialMediaString = friend.socialMediaHandles.map { "\($0.key):\($0.value)" }.joined(separator: "; ")
            
            let row = [
                friend.id.uuidString,
                csvEscape(friend.name),
                csvEscape(friend.email ?? ""),
                csvEscape(friend.phone ?? ""),
                csvEscape(friend.jobTitle ?? ""),
                csvEscape(friend.company ?? ""),
                csvEscape(friend.notes ?? ""),
                friend.isFavorite ? "Yes" : "No",
                dateFormatter.string(from: friend.createdAt),
                dateFormatter.string(from: friend.updatedAt),
                "\(friend.events.count)",
                "\(friend.wishEvents.count)",
                csvEscape(socialMediaString)
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    // MARK: - Archive Creation
    
    private func createArchive(files: [URL], in directory: URL) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let archiveURL = directory.appendingPathComponent("EventBuddy_Export_\(timestamp).zip")
        
        // Create a simple tar-like archive by concatenating files with headers
        // For iOS sharing, we'll create a folder structure instead of a zip
        let exportFolderURL = directory.appendingPathComponent("EventBuddy_Export_\(timestamp)")
        try FileManager.default.createDirectory(at: exportFolderURL, withIntermediateDirectories: true)
        
        // Copy files to the export folder
        for fileURL in files {
            let destinationURL = exportFolderURL.appendingPathComponent(fileURL.lastPathComponent)
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
        }
        
        // Create a README file
        let readmeContent = """
        EventBuddy Data Export
        =====================
        
        Export Date: \(ISO8601DateFormatter().string(from: Date()))
        Version: 1.0
        
        Files included:
        - eventbuddy_backup.json: Complete backup in JSON format
        - events.csv: All events in CSV format
        - friends.csv: All friends in CSV format
        
        The JSON file contains all data including relationships between events and friends.
        The CSV files are provided for easy import into spreadsheet applications.
        """
        
        let readmeURL = exportFolderURL.appendingPathComponent("README.txt")
        try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
        
        return exportFolderURL
    }
    
    // MARK: - Helper Functions
    
    private func csvEscape(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    private func createRelationshipData(events: [Event], friends: [Friend]) -> RelationshipData {
        var eventAttendees: [EventAttendeeRelation] = []
        var eventWishes: [EventWishRelation] = []
        
        for event in events {
            for attendee in event.attendees {
                eventAttendees.append(EventAttendeeRelation(
                    eventId: event.id.uuidString,
                    friendId: attendee.id.uuidString
                ))
            }
            
            for wish in event.friendWishes {
                eventWishes.append(EventWishRelation(
                    eventId: event.id.uuidString,
                    friendId: wish.id.uuidString
                ))
            }
        }
        
        return RelationshipData(
            eventAttendees: eventAttendees,
            eventWishes: eventWishes
        )
    }
}

// MARK: - Data Transfer Objects

struct DataBackup: Codable {
    let exportDate: Date
    let version: String
    let events: [EventExportDTO]
    let friends: [FriendExportDTO]
    let relationships: RelationshipData
}

struct EventExportDTO: Codable {
    let id: String
    let title: String
    let eventDescription: String
    let location: String
    let address: String?
    let startDate: Date
    let endDate: Date
    let eventType: String
    let notes: String?
    let requiresTicket: Bool
    let requiresRegistration: Bool
    let url: String?
    let isAttending: Bool
    let isCustomEvent: Bool
    let originalTimezoneIdentifier: String?
    let createdAt: Date
    let updatedAt: Date
}

struct FriendExportDTO: Codable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let jobTitle: String?
    let company: String?
    let socialMediaHandles: [String: String]
    let notes: String?
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct RelationshipData: Codable {
    let eventAttendees: [EventAttendeeRelation]
    let eventWishes: [EventWishRelation]
}

struct EventAttendeeRelation: Codable {
    let eventId: String
    let friendId: String
}

struct EventWishRelation: Codable {
    let eventId: String
    let friendId: String
}

// MARK: - Extensions

extension Event {
    func toExportDTO() -> EventExportDTO {
        return EventExportDTO(
            id: id.uuidString,
            title: title,
            eventDescription: eventDescription,
            location: location,
            address: address,
            startDate: startDate,
            endDate: endDate,
            eventType: eventType,
            notes: notes,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url,
            isAttending: isAttending,
            isCustomEvent: isCustomEvent,
            originalTimezoneIdentifier: originalTimezoneIdentifier,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension Friend {
    func toExportDTO() -> FriendExportDTO {
        return FriendExportDTO(
            id: id.uuidString,
            name: name,
            email: email,
            phone: phone,
            jobTitle: jobTitle,
            company: company,
            socialMediaHandles: socialMediaHandles,
            notes: notes,
            isFavorite: isFavorite,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Error Types

enum ExportError: LocalizedError {
    case archiveCreationFailed
    case noDataToExport
    case fileWriteError
    
    var errorDescription: String? {
        switch self {
        case .archiveCreationFailed:
            return "Failed to create archive file"
        case .noDataToExport:
            return "No data available to export"
        case .fileWriteError:
            return "Failed to write export files"
        }
    }
} 