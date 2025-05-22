import Foundation
import SwiftData
import SwiftUI

enum EventType: String, Codable, CaseIterable {
    case keynote = "Keynote"
    case watchParty = "Watch Party"
    case social = "Social"
    case event = "Event"
    case meetup = "Meetup"
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
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var attendees: [Friend] = []
    
    init(id: UUID = UUID(), 
         title: String, 
         eventDescription: String, 
         location: String, 
         startDate: Date, 
         endDate: Date, 
         category: String, 
         notes: String? = nil) {
        self.id = id
        self.title = title
        self.eventDescription = eventDescription
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
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
            notes: "Don't forget to bring MacBook and business cards"
        )
    }
} 