import Foundation
import SwiftData
import SwiftUI

enum EventType: String, Codable, CaseIterable {
    case keynote = "Keynote"
    case watchParty = "Watch Party"
    case social = "Social"
    case event = "Event"
    case meetup = "Meetup"
    case conference = "Conference"
    case informal = "Informal Gathering"
    case party = "Party"
    case art = "Art Experience"
    case run = "Run"
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
    let startDate: String
    let endDate: String
    let category: String
    let eventType: String
    let notes: String?
    let isWWDCEvent: Bool
    let countryCode: String?
    let countryFlag: String?
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
        
        let event = Event(
            id: uuid,
            title: title,
            eventDescription: eventDescription,
            location: location,
            startDate: startDate,
            endDate: endDate,
            category: category,
            eventType: eventType,
            notes: notes,
            isWWDCEvent: isWWDCEvent,
            countryCode: countryCode,
            countryFlag: countryFlag,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url
        )
        
        event.createdAt = createdAt
        event.updatedAt = updatedAt
        
        return event
    }
}

@Model
final class Event {
    var id: UUID
    var title: String
    var eventDescription: String
    var location: String
    var startDate: Date
    var endDate: Date
    var category: String
    var eventType: String
    var notes: String?
    var isWWDCEvent: Bool
    var countryCode: String?
    var countryFlag: String?
    var requiresTicket: Bool
    var requiresRegistration: Bool
    var url: String?
    var createdAt: Date
    var updatedAt: Date
    var isAttending: Bool
    
    @Relationship(deleteRule: .cascade)
    var attendees: [Friend] = []
    
    init(id: UUID = UUID(), 
         title: String, 
         eventDescription: String, 
         location: String,
         startDate: Date, 
         endDate: Date, 
         category: String,
         eventType: String = EventType.event.rawValue,
         notes: String? = nil,
         isWWDCEvent: Bool = false,
         countryCode: String? = nil,
         countryFlag: String? = nil,
         requiresTicket: Bool = false,
         requiresRegistration: Bool = false,
         url: String? = nil,
         isAttending: Bool = false) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.eventType = eventType
        self.notes = notes
        self.isWWDCEvent = isWWDCEvent
        self.countryCode = countryCode
        self.countryFlag = countryFlag
        self.requiresTicket = requiresTicket
        self.requiresRegistration = requiresRegistration
        self.url = url
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isAttending = isAttending
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
    
    // Convert to DTO for JSON serialization
    func toDTO() -> EventDTO {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        return EventDTO(
            id: id.uuidString,
            title: title,
            eventDescription: eventDescription,
            location: location,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            category: category,
            eventType: eventType,
            notes: notes,
            isWWDCEvent: isWWDCEvent,
            countryCode: countryCode,
            countryFlag: countryFlag,
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
        
        return dtoUpdatedAt > updatedAt ||
               title != dto.title ||
               eventDescription != dto.eventDescription ||
               location != dto.location ||
               category != dto.category ||
               eventType != dto.eventType ||
               notes != dto.notes ||
               isWWDCEvent != dto.isWWDCEvent ||
               countryCode != dto.countryCode ||
               countryFlag != dto.countryFlag ||
               requiresTicket != dto.requiresTicket ||
               requiresRegistration != dto.requiresRegistration ||
               url != dto.url
    }
    
    // Update this event from a DTO
    func update(from dto: EventDTO) {
        guard let startDate = parseISO8601Date(dto.startDate),
              let endDate = parseISO8601Date(dto.endDate),
              let updatedAt = parseISO8601Date(dto.updatedAt) else {
            return
        }
        
        self.title = dto.title
        self.eventDescription = dto.eventDescription
        self.location = dto.location
        self.startDate = startDate
        self.endDate = endDate
        self.category = dto.category
        self.eventType = dto.eventType
        self.notes = dto.notes
        self.isWWDCEvent = dto.isWWDCEvent
        self.countryCode = dto.countryCode
        self.countryFlag = dto.countryFlag
        self.requiresTicket = dto.requiresTicket
        self.requiresRegistration = dto.requiresRegistration
        self.url = dto.url
        self.updatedAt = updatedAt
    }
}

// MARK: - Helper Extensions

extension Event {
    static var preview: Event {
        Event(
            title: "WWDC 2025",
            eventDescription: "Apple's Worldwide Developers Conference",
            location: "1 Apple Park Way, Cupertino, CA",
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 2, hour: 10))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 6, hour: 18))!,
            category: "Conference",
            eventType: EventType.conference.rawValue,
            notes: "Don't forget to bring MacBook and business cards",
            isWWDCEvent: true,
            countryCode: "US",
            countryFlag: "🇺🇸",
            requiresTicket: true,
            url: "https://developer.apple.com/wwdc/"
        )
    }
    
    static var wwdcKeynoteWatchParty: Event {
        Event(
            title: "WWDC'25 Watch Party @ London",
            eventDescription: "NSLondon WWDC25 keynote viewing party at Ford",
            location: "London, United Kingdom",
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 9, hour: 17, minute: 30))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 9, hour: 20, minute: 30))!,
            category: "Watch Party",
            eventType: EventType.watchParty.rawValue,
            isWWDCEvent: true,
            countryCode: "GB",
            countryFlag: "🇬🇧"
        )
    }
} 
