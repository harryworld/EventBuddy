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
}

// MARK: - Helper Extensions

extension Event {
    static var preview: Event {
        Event(
            title: "WWDC 2025",
            eventDescription: "Apple's Worldwide Developers Conference",
            location: "Apple Park, Cupertino, CA",
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 2, hour: 10))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 6, hour: 18))!,
            category: "Conference",
            eventType: EventType.conference.rawValue,
            notes: "Don't forget to bring MacBook and business cards",
            isWWDCEvent: true,
            countryCode: "US",
            countryFlag: "🇺🇸",
            requiresTicket: true
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