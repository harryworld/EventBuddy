import Foundation

@Observable class Event: Identifiable {
    let id = UUID()
    var name: String
    var dateTime: String
    var description: String
    var requiresTicket: Bool
    var location: String
    var day: String
    
    init(name: String, dateTime: String, description: String, requiresTicket: Bool = false, location: String = "Cupertino", day: String) {
        self.name = name
        self.dateTime = dateTime
        self.description = description
        self.requiresTicket = requiresTicket
        self.location = location
        self.day = day
    }
}

@Observable class EventStore {
    var events: [Event] = []
    
    init() {
        loadWWDCEvents()
    }
    
    private func loadWWDCEvents() {
        // Saturday
        events.append(Event(name: "One More Thing 2025", dateTime: "9:00am-4:00pm", description: "Conference event", requiresTicket: true, day: "Saturday, June 7th"))
        events.append(Event(name: "WWDC Run", dateTime: "10:00am-12:00pm", description: "Registration suggested", day: "Saturday, June 7th"))
        events.append(Event(name: "Informal Pre-WWDC 25 Gathering", dateTime: "5:00pm-8:00pm", description: "Networking event", day: "Saturday, June 7th"))
        events.append(Event(name: "Apple Park Happy Hour", dateTime: "6:30pm-10:00pm", description: "RSVP requested", day: "Saturday, June 7th"))
        
        // Sunday
        events.append(Event(name: "One More Thing 2025", dateTime: "9:30am-4:00pm", description: "Conference event", requiresTicket: true, day: "Sunday, June 8th"))
        events.append(Event(name: "WWDC Check-in", dateTime: "3:00pm-7:00pm", description: "Refreshments and games at Infinite Loop", requiresTicket: true, day: "Sunday, June 8th"))
        events.append(Event(name: "RevenueCat's Pre-WWDC Bashcade", dateTime: "6:30pm-11:00pm", description: "Social event", requiresTicket: true, day: "Sunday, June 8th"))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams", day: "Sunday, June 8th"))
        
        // Monday
        events.append(Event(name: "Special Event at Apple Park", dateTime: "9:00am-4:00pm", description: "Official Apple event", requiresTicket: true, day: "Monday, June 9th"))
        events.append(Event(name: "WWDC25 Keynote & SOTU Watch Party", dateTime: "7:45am-4:00pm", description: "Hosted by iOSDevHappyHour at CommunityKit", day: "Monday, June 9th"))
        events.append(Event(name: "WWDC25 Keynote & SOTU Watch Party", dateTime: "8:00am-5:30pm", description: "Hosted by One More Thing", day: "Monday, June 9th"))
        events.append(Event(name: "Students, Swift, St★rs", dateTime: "7:00pm-10:00pm", description: "Student event", day: "Monday, June 9th"))
        events.append(Event(name: "The French Dinner", dateTime: "7:00pm-10:30pm", description: "🇫🇷🇨🇦🇱🇺🇧🇪 (requires registration)", day: "Monday, June 9th"))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams", day: "Monday, June 9th"))
        
        // Tuesday
        events.append(Event(name: "Apple Developer Center Sessions", dateTime: "10:00am-6:00pm", description: "Morning, Afternoon, Evening", requiresTicket: true, day: "Tuesday, June 10th"))
        events.append(Event(name: "CommunityKit", dateTime: "9:00am-5:00pm", description: "Community event", day: "Tuesday, June 10th"))
        events.append(Event(name: "One More Thing 2025", dateTime: "8:00am-5:30pm", description: "Conference event", day: "Tuesday, June 10th"))
        events.append(Event(name: "#WWDCScholars meetup at WWDC25", dateTime: "7:00pm-10:00pm", description: "For WWDC Scholarship and Swift Student Challenge winners", day: "Tuesday, June 10th"))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams", day: "Tuesday, June 10th"))
        
        // Wednesday
        events.append(Event(name: "CommunityKit", dateTime: "9:00am-5:00pm", description: "Community event", day: "Wednesday, June 11th"))
        events.append(Event(name: "One More Thing 2025", dateTime: "8:00am-5:30pm", description: "Conference event", day: "Wednesday, June 11th"))
        events.append(Event(name: "Annual WWDC Women's Lunch", dateTime: "12:00pm-1:30pm", description: "Unofficial, free event", day: "Wednesday, June 11th"))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams", day: "Wednesday, June 11th"))
        events.append(Event(name: "AiOS Meetup", dateTime: "4:30pm-6:00pm", description: "Free event", day: "Wednesday, June 11th"))
        
        // Thursday
        events.append(Event(name: "One More Thing 2025", dateTime: "8:30am-7:00pm", description: "Conference event", day: "Thursday, June 12th"))
        events.append(Event(name: "A Vision Pro Spatial Art Experience", dateTime: "9:00am-18:00pm", description: "Flatland: Mixed Reality Dreams", day: "Thursday, June 12th"))
        
        // Online events
        events.append(Event(name: "WWDC'25 Watch Party Ahmedabad", dateTime: "June 9th, 7:30pm - 12:30am IST", description: "🇮🇳 Ahmedabad, India", location: "Online", day: "Watch Parties"))
        events.append(Event(name: "WWDC'25 TLV Watch Party @ monday.com", dateTime: "June 9th, 7:00pm - 11pm IDT", description: "🇮🇱 Tel Aviv, Israel", location: "Online", day: "Watch Parties"))
    }
} 