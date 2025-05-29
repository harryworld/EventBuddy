import Foundation
import SwiftData
import SwiftUI

enum EventType: String, Codable, CaseIterable {
    case keynote = "Keynote"
    case watchParty = "Watch Party"
    case social = "Social"
    case meetup = "Meetup"
}

// MARK: - JSON Data Transfer Objects

struct EventsResponse: Codable {
    let events: [EventDTO]
    let lastUpdated: String
    let version: String
}

// MARK: - Date Parsing Helper

private func parseISO8601Date(_ dateString: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    
    // Try with timezone information first
    formatter.formatOptions = [.withInternetDateTime]
    if let date = formatter.date(from: dateString) {
        return date
    }
    
    // Fallback: try with different format options
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    if let date = formatter.date(from: dateString) {
        return date
    }
    
    // Last resort: try with full format options
    formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
    return formatter.date(from: dateString)
}

struct EventDTO: Codable, Identifiable {
    let id: String
    let title: String
    let eventDescription: String
    let location: String
    let address: String?
    let startDate: String
    let endDate: String
    let eventType: String
    let notes: String?
    let requiresTicket: Bool
    let requiresRegistration: Bool
    let url: String?
    let createdAt: String
    let updatedAt: String
    
    // Convert to Event model
    func toEvent() -> Event? {
        guard let uuid = UUID(uuidString: id),
              let startDate = parseISO8601Date(startDate),
              let endDate = parseISO8601Date(endDate),
              let createdAt = parseISO8601Date(createdAt),
              let updatedAt = parseISO8601Date(updatedAt) else {
            return nil
        }
        
        // Extract timezone from the original date string
        let originalTimezone = extractTimezoneFromISO8601(self.startDate)
        
        let event = Event(
            id: uuid,
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
            originalTimezoneIdentifier: originalTimezone,
            isCustomEvent: false
        )
        
        event.createdAt = createdAt
        event.updatedAt = updatedAt
        
        return event
    }
}

// Helper function to extract timezone from ISO8601 string
private func extractTimezoneFromISO8601(_ dateString: String) -> String? {
    // Try to extract timezone from formats like "2025-06-09T17:30:00+01:00" or "2025-06-09T17:30:00-07:00"
    if let range = dateString.range(of: #"[+-]\d{2}:\d{2}$"#, options: .regularExpression) {
        let offsetString = String(dateString[range])
        
        // Convert offset to timezone identifier
        switch offsetString {
        case "+01:00":
            return "Europe/London" // BST
        case "+03:00":
            return "Asia/Jerusalem" // IDT
        case "-07:00":
            return "America/Los_Angeles" // PDT
        case "-05:00":
            return "America/New_York" // EDT
        case "-06:00":
            return "America/Chicago" // CDT
        case "+05:30":
            return "Asia/Kolkata" // IST
        case "+09:00":
            return "Asia/Tokyo" // JST
        case "+10:00":
            return "Australia/Sydney" // AEST
        default:
            // For other offsets, try to determine a reasonable timezone
            if offsetString.hasPrefix("+") {
                return "Europe/London" // Default to London for positive offsets
            } else {
                return "America/Los_Angeles" // Default to LA for negative offsets
            }
        }
    }
    
    // If no timezone info found, default to Pacific Time (WWDC location)
    return "America/Los_Angeles"
}

@Model
final class Event {
    var id: UUID
    var title: String
    var eventDescription: String
    var location: String
    var address: String?
    var startDate: Date
    var endDate: Date
    var eventType: String
    var notes: String?
    var requiresTicket: Bool
    var requiresRegistration: Bool
    var url: String?
    var createdAt: Date
    var updatedAt: Date
    var isAttending: Bool
    var originalTimezoneIdentifier: String?
    var isCustomEvent: Bool = true
    
    @Relationship(deleteRule: .cascade)
    var attendees: [Friend] = []
    
    // New properties for friend wishes
    @Relationship(deleteRule: .nullify)
    var friendWishes: [Friend] = []
    
    init(id: UUID = UUID(), 
         title: String, 
         eventDescription: String, 
         location: String,
         address: String? = nil,
         startDate: Date, 
         endDate: Date, 
         eventType: String = EventType.social.rawValue,
         notes: String? = nil,
         requiresTicket: Bool = false,
         requiresRegistration: Bool = false,
         url: String? = nil,
         isAttending: Bool = false,
         originalTimezoneIdentifier: String? = nil,
         isCustomEvent: Bool = true) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.address = address
        self.startDate = startDate
        self.endDate = endDate
        self.eventType = eventType
        self.notes = notes
        self.requiresTicket = requiresTicket
        self.requiresRegistration = requiresRegistration
        self.url = url
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isAttending = isAttending
        self.originalTimezoneIdentifier = originalTimezoneIdentifier ?? "America/Los_Angeles"
        self.isCustomEvent = isCustomEvent
    }
    
    func addFriend(_ friend: Friend) {
        if !attendees.contains(where: { $0.id == friend.id }) {
            attendees.append(friend)
        }
    }
    
    func removeFriend(_ friendId: UUID) {
        attendees.removeAll { $0.id == friendId }
    }
    
    func isFriendAttending(_ friendId: UUID) -> Bool {
        return attendees.contains(where: { $0.id == friendId })
    }
    
    func toggleAttending() {
        isAttending.toggle()
        updatedAt = Date()
    }
    
    // Check if the event has ended
    var hasEnded: Bool {
        return Date() > endDate
    }
    
    // Convert to DTO for JSON serialization
    func toDTO() -> EventDTO {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        return EventDTO(
            id: id.uuidString,
            title: title,
            eventDescription: eventDescription,
            location: location,
            address: address,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            eventType: eventType,
            notes: notes,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url,
            createdAt: formatter.string(from: createdAt),
            updatedAt: formatter.string(from: updatedAt)
        )
    }
    
    // Check if this event needs updating based on a DTO
    func needsUpdate(from dto: EventDTO) -> Bool {
        guard let dtoUpdatedAt = parseISO8601Date(dto.updatedAt) else {
            return false
        }
        
        let dtoOriginalTimezone = extractTimezoneFromISO8601(dto.startDate)
        
        return dtoUpdatedAt > updatedAt ||
               title != dto.title ||
               eventDescription != dto.eventDescription ||
               location != dto.location ||
               address != dto.address ||
               eventType != dto.eventType ||
               notes != dto.notes ||
               requiresTicket != dto.requiresTicket ||
               requiresRegistration != dto.requiresRegistration ||
               url != dto.url ||
               originalTimezoneIdentifier != dtoOriginalTimezone
    }
    
    // Update this event from a DTO
    func update(from dto: EventDTO) {
        guard let startDate = parseISO8601Date(dto.startDate),
              let endDate = parseISO8601Date(dto.endDate),
              let updatedAt = parseISO8601Date(dto.updatedAt) else {
            return
        }
        
        let dtoOriginalTimezone = extractTimezoneFromISO8601(dto.startDate)
        
        self.title = dto.title
        self.eventDescription = dto.eventDescription
        self.location = dto.location
        self.address = dto.address
        self.startDate = startDate
        self.endDate = endDate
        self.eventType = dto.eventType
        self.notes = dto.notes
        self.requiresTicket = dto.requiresTicket
        self.requiresRegistration = dto.requiresRegistration
        self.url = dto.url
        self.updatedAt = updatedAt
        self.originalTimezoneIdentifier = dtoOriginalTimezone ?? "America/Los_Angeles"
    }
    
    // MARK: - Friend Wishes Management
    
    func addFriendWish(_ friend: Friend) {
        if !friendWishes.contains(where: { $0.id == friend.id }) {
            friendWishes.append(friend)
            updatedAt = Date()
        }
    }
    
    func removeFriendWish(_ friendId: UUID) {
        friendWishes.removeAll { $0.id == friendId }
        updatedAt = Date()
    }
    
    func isFriendWished(_ friendId: UUID) -> Bool {
        return friendWishes.contains(where: { $0.id == friendId })
    }
    
    // MARK: - People Met Management (using attendees)
    
    func markFriendAsMet(_ friend: Friend) {
        // Remove from friend wishes if present
        removeFriendWish(friend.id)
        
        // Add to attendees if not already there
        addFriend(friend)
    }
}

// MARK: - Helper Extensions

extension Event {
    static var preview: Event {
        Event(
            title: "WWDC 2025",
            eventDescription: "Apple's Worldwide Developers Conference",
            location: "Apple Park",
            address: "1 Apple Park Way, Cupertino, CA",
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 10, hour: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 10, hour: 9))!,
            eventType: EventType.keynote.rawValue,
            notes: "Don't forget to bring MacBook and business cards",
            requiresTicket: true,
            url: "https://developer.apple.com/wwdc/",
            originalTimezoneIdentifier: "America/Los_Angeles",
            isCustomEvent: false
        )
    }
    
    static var wwdcKeynoteWatchParty: Event {
        Event(
            title: "WWDC'25 Watch Party @ London",
            eventDescription: "NSLondon WWDC25 keynote viewing party at Ford",
            location: "London, United Kingdom",
            address: "Ford, London",
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 9, hour: 17, minute: 30))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 5, day: 9, hour: 20, minute: 30))!,
            eventType: EventType.watchParty.rawValue,
            requiresTicket: true,
            isAttending: true,
            originalTimezoneIdentifier: "Europe/London",
            isCustomEvent: false
        )
    }
} 
