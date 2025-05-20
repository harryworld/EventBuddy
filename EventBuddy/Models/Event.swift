import Foundation

enum EventType: String, CaseIterable {
    case keynote = "Keynote"
    case watchParty = "Watch Party"
    case social = "Social"
    case event = "Event"
    case meetup = "Meetup"
}

@Observable class Event: Identifiable {
    let id = UUID()
    var name: String
    var dateTime: String
    var description: String
    var requiresTicket: Bool
    var location: String
    var day: String
    var type: EventType
    var attendingFriends: [UUID] = [] // Store friend IDs for events
    var isCustomEvent: Bool = false
    var isUserAttending: Bool = false // Track if the current user is attending this event
    
    init(name: String, dateTime: String, description: String, requiresTicket: Bool = false, location: String = "Cupertino", day: String, type: EventType = .event, attendingFriends: [UUID] = [], isCustomEvent: Bool = false, isUserAttending: Bool = false) {
        self.name = name
        self.dateTime = dateTime
        self.description = description
        self.requiresTicket = requiresTicket
        self.location = location
        self.day = day
        self.type = type
        self.attendingFriends = attendingFriends
        self.isCustomEvent = isCustomEvent
        self.isUserAttending = isUserAttending
    }
    
    func addFriend(_ friendId: UUID) {
        if !attendingFriends.contains(friendId) {
            attendingFriends.append(friendId)
        }
    }
    
    func removeFriend(_ friendId: UUID) {
        attendingFriends.removeAll { $0 == friendId }
    }
    
    func isFriendAttending(_ friendId: UUID) -> Bool {
        return attendingFriends.contains(friendId)
    }
}

@Observable class EventStore {
    var events: [Event] = []
    
    init() {
        loadWWDCEvents()
    }
    
    // Add a new custom event
    func addCustomEvent(event: Event) {
        var newEvent = event
        newEvent.isCustomEvent = true
        events.append(newEvent)
    }
    
    // Remove a custom event
    func removeCustomEvent(id: UUID) {
        events.removeAll { $0.id == id && $0.isCustomEvent }
    }
    
    // Toggle user attendance for an event
    func toggleUserAttendance(for eventId: UUID) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            events[index].isUserAttending.toggle()
        }
    }
    
    // Get all events the user is attending
    func getAttendingEvents() -> [Event] {
        return events.filter { $0.isUserAttending }
    }
    
    // Friend management methods
    func addFriendToEvent(eventId: UUID, friendId: UUID) {
        if let eventIndex = events.firstIndex(where: { $0.id == eventId }) {
            events[eventIndex].addFriend(friendId)
        }
    }
    
    func removeFriendFromEvent(eventId: UUID, friendId: UUID) {
        if let eventIndex = events.firstIndex(where: { $0.id == eventId }) {
            events[eventIndex].removeFriend(friendId)
        }
    }
    
    func getEventById(_ id: UUID) -> Event? {
        return events.first { $0.id == id }
    }
    
    func getAttendingFriendIds(for eventId: UUID) -> [UUID] {
        if let event = getEventById(eventId) {
            return event.attendingFriends
        }
        return []
    }
    
    func getEventsAttendedByFriend(_ friendId: UUID) -> [Event] {
        return events.filter { $0.attendingFriends.contains(friendId) }
    }
    
    private func loadWWDCEvents() {
        // Saturday
        events.append(Event(name: "One More Thing 2025", dateTime: "9:00am-4:00pm", description: "Conference event", requiresTicket: true, day: "Saturday, June 7th", type: .event))
        events.append(Event(name: "WWDC Run", dateTime: "10:00am-12:00pm", description: "Registration suggested", day: "Saturday, June 7th", type: .social))
        events.append(Event(name: "Informal Pre-WWDC 25 Gathering", dateTime: "5:00pm-8:00pm", description: "Networking event", day: "Saturday, June 7th", type: .social))
        events.append(Event(name: "Apple Park Happy Hour", dateTime: "6:30pm-10:00pm", description: "RSVP requested", day: "Saturday, June 7th", type: .social))
        
        // Sunday
        events.append(Event(name: "One More Thing 2025", dateTime: "9:30am-4:00pm", description: "Conference event", requiresTicket: true, day: "Sunday, June 8th", type: .event))
        events.append(Event(name: "WWDC Check-in", dateTime: "3:00pm-7:00pm", description: "Refreshments and games at Infinite Loop", requiresTicket: true, day: "Sunday, June 8th", type: .event))
        events.append(Event(name: "RevenueCat's Pre-WWDC Bashcade", dateTime: "6:30pm-11:00pm", description: "Social event", requiresTicket: true, day: "Sunday, June 8th", type: .social))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams (free)", day: "Sunday, June 8th", type: .event))
        
        // Monday
        events.append(Event(name: "Special Event at Apple Park", dateTime: "9:00am-4:00pm", description: "Official Apple event", requiresTicket: true, day: "Monday, June 9th", type: .keynote))
        events.append(Event(name: "WWDC25 Keynote & SOTU Watch Party", dateTime: "7:45am-4:00pm", description: "Hosted by iOSDevHappyHour at CommunityKit", day: "Monday, June 9th", type: .watchParty))
        events.append(Event(name: "WWDC25 Keynote & SOTU Watch Party", dateTime: "8:00am-5:30pm", description: "Hosted by One More Thing", day: "Monday, June 9th", type: .watchParty))
        events.append(Event(name: "Students, Swift, St★rs", dateTime: "7:00pm-10:00pm", description: "Student event", day: "Monday, June 9th", type: .social))
        events.append(Event(name: "The French Dinner", dateTime: "7:00pm-10:30pm", description: "🇫🇷🇨🇦🇱🇺🇧🇪 (requires registration)", requiresTicket: true, day: "Monday, June 9th", type: .social))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams (free)", day: "Monday, June 9th", type: .event))
        
        // Tuesday
        events.append(Event(name: "Apple Developer Center Sessions", dateTime: "10:00am-6:00pm", description: "Morning, Afternoon, Evening", requiresTicket: true, day: "Tuesday, June 10th", type: .event))
        events.append(Event(name: "CommunityKit", dateTime: "9:00am-5:00pm", description: "Community event", day: "Tuesday, June 10th", type: .event))
        events.append(Event(name: "One More Thing 2025", dateTime: "8:00am-5:30pm", description: "Conference event", day: "Tuesday, June 10th", type: .event))
        events.append(Event(name: "#WWDCScholars meetup at WWDC25", dateTime: "7:00pm-10:00pm", description: "For WWDC Scholarship and Swift Student Challenge winners", day: "Tuesday, June 10th", type: .meetup))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams (free)", day: "Tuesday, June 10th", type: .event))
        events.append(Event(name: "Beer with Swift @WWDC25", dateTime: "7:00pm-9:00pm", description: "by createwithswift.com (requires registration)", requiresTicket: true, day: "Tuesday, June 10th", type: .social))
        events.append(Event(name: "RocketSim Meetup at CommunityKit", dateTime: "2:00pm-4:00pm", description: "Requires Registration", requiresTicket: true, day: "Tuesday, June 10th", type: .meetup))
        
        // Wednesday
        events.append(Event(name: "CommunityKit", dateTime: "9:00am-5:00pm", description: "Community event", day: "Wednesday, June 11th", type: .event))
        events.append(Event(name: "One More Thing 2025", dateTime: "8:00am-5:30pm", description: "Conference event", day: "Wednesday, June 11th", type: .event))
        events.append(Event(name: "Annual WWDC Women's Lunch", dateTime: "12:00pm-1:30pm", description: "Unofficial, free event", day: "Wednesday, June 11th", type: .meetup))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams (free)", day: "Wednesday, June 11th", type: .event))
        events.append(Event(name: "AiOS Meetup", dateTime: "4:30pm-6:00pm", description: "Free event", day: "Wednesday, June 11th", type: .meetup))
        
        // Thursday
        events.append(Event(name: "One More Thing 2025", dateTime: "8:30am-7:00pm", description: "Conference event", day: "Thursday, June 12th", type: .event))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams (free)", day: "Thursday, June 12th", type: .event))
        
        // Online events - Watch Parties
        events.append(Event(name: "WWDC'25 Watch Party Ahmedabad", dateTime: "June 9th, 7:30pm - 12:30am IST", description: "🇮🇳 Ahmedabad, India", location: "Online", day: "Watch Parties", type: .watchParty))
        events.append(Event(name: "WWDC'25 TLV Watch Party @ monday.com", dateTime: "June 9th, 7:00pm - 11pm IDT", description: "🇮🇱 Tel Aviv, Israel", location: "Online", day: "Watch Parties", type: .watchParty))
        events.append(Event(name: "STL Swift WWDC Watch Event", dateTime: "June 9th, 11:00am - 2pm CDT", description: "🇺🇸 Saint Louis, Missouri, USA", location: "Online", day: "Watch Parties", type: .watchParty))
    }
} 