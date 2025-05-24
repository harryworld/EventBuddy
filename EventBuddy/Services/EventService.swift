import Foundation
import SwiftData
import SwiftUI

@MainActor
class EventService {
    
    // Add sample WWDC events based on cross-referenced data from official sources
    static func addSampleWWDCEvents(modelContext: ModelContext) {
        // Clear existing events first
        clearExistingEvents(modelContext: modelContext)
        
        let events = [
            // SATURDAY, June 7th
            Event(
                title: "One More Thing 2025",
                eventDescription: "Conference event for iOS developers",
                location: "Cupertino, California", // Location not specified on official site
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 16, minute: 0),
                category: "Conference",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 9:00am-4:00pm. Requires a ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "WWDC Run",
                eventDescription: "Group run for conference attendees",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                category: "Social",
                eventType: EventType.run.rawValue,
                notes: "Runs from 10:00am-12:00pm. Registration suggested.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            Event(
                title: "Informal Pre-WWDC 25 Gathering",
                eventDescription: "Casual meetup before the conference starts",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 17, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 20, minute: 0),
                category: "Social",
                eventType: EventType.informal.rawValue,
                notes: "Runs from 5:00pm-8:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "Apple Park Happy Hour",
                eventDescription: "Social event at Apple Park",
                location: "1 Apple Park Way, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 6:30pm-10:00pm. RSVP requested.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            // SUNDAY, June 8th
            Event(
                title: "One More Thing 2025 - Day 2",
                eventDescription: "Conference event for iOS developers - Day 2",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 9, minute: 30),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 16, minute: 0),
                category: "Conference",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 9:30am-4:00pm. Requires a ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "WWDC Check-in, refreshments, and games",
                eventDescription: "Official WWDC check-in with refreshments and games at Infinite Loop",
                location: "1 Infinite Loop, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 15, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 19, minute: 0),
                category: "Official",
                eventType: EventType.event.rawValue,
                notes: "Runs from 3:00pm-7:00pm at Infinite Loop. Requires WWDC ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "RevenueCat's Pre-WWDC Bashcade",
                eventDescription: "Fun event before WWDC with games and networking",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 23, minute: 0),
                category: "Social",
                eventType: EventType.party.rawValue,
                notes: "Runs from 6:30pm-11:00pm. Requires a ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "A Vision Pro Spatial Art Experience — Flatland: Mixed Reality Dreams",
                eventDescription: "Vision Pro spatial art experience",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 18, minute: 0),
                category: "Experience",
                eventType: EventType.art.rawValue,
                notes: "Runs from 9:00am-6:00pm. Free admission.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            // MONDAY, June 9th (Keynote Day)
            Event(
                title: "Special Event at Apple Park",
                eventDescription: "Official Apple WWDC Special Event",
                location: "1 Apple Park Way, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                category: "Official",
                eventType: EventType.event.rawValue,
                notes: "Runs from 9:00am-4:00pm. Requires WWDC ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "WWDC25 Keynote & SOTU Watch Party",
                eventDescription: "Watch party hosted by iOSDevHappyHour at CommunityKit",
                location: "10380 Perimeter Rd, Cupertino, CA 95014 (Hyatt House San Jose Cupertino)",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 7, minute: 45),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:45am-4:00pm. Hosted by iOSDevHappyHour at CommunityKit.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "WWDC25 Keynote & SOTU Watch Party by One More Thing",
                eventDescription: "Watch party hosted by One More Thing",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 17, minute: 30),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 8:00am-5:30pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "Students, Swift, St★rs",
                eventDescription: "Event for students and Swift developers",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 7:00pm-10:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "🇫🇷🇨🇦🇱🇺🇧🇪 The French Dinner",
                eventDescription: "French-speaking community dinner",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 30),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-10:30pm. Requires registration.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            // International Watch Parties
            Event(
                title: "WWDC'25 Watch Party Ahmedabad",
                eventDescription: "Watch party for the Apple keynote",
                location: "Ahmedabad, India",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 0, minute: 30),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:30pm-12:30am IST",
                isWWDCEvent: true,
                countryCode: "IN",
                countryFlag: "🇮🇳"
            ),
            
            Event(
                title: "WWDC'25 TLV Watch Party @ monday.com",
                eventDescription: "Watch party at monday.com",
                location: "Tel Aviv, Israel",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 23, minute: 0),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:00pm-11:00pm IDT",
                isWWDCEvent: true,
                countryCode: "IL",
                countryFlag: "🇮🇱"
            ),
            
            Event(
                title: "NSLondon WWDC25 keynote viewing party at Ford",
                eventDescription: "Watch party at Ford",
                location: "London, United Kingdom",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 17, minute: 30),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 20, minute: 30),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 5:30pm-8:30pm BST",
                isWWDCEvent: true,
                countryCode: "GB",
                countryFlag: "🇬🇧"
            ),
            
            Event(
                title: "STL Swift WWDC Watch Event",
                eventDescription: "Watch party for the Apple keynote",
                location: "Saint Louis, Missouri, USA",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 11, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 14, minute: 0),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 11:00am-2:00pm CDT",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            // TUESDAY, June 10th
            Event(
                title: "Apple Developer Center Sessions",
                eventDescription: "Morning, Afternoon, Evening sessions",
                location: "1 Apple Park Way, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                category: "Official",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 10:00am-6:00pm. Requires WWDC ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "CommunityKit",
                eventDescription: "Community meetups, workshops, hackathons, and more",
                location: "10380 Perimeter Rd, Cupertino, CA 95014 (Hyatt House San Jose Cupertino)",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 17, minute: 0),
                category: "Community",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:00am-5:00pm. Free entry.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "#WWDCScholars meetup at WWDC25",
                eventDescription: "Meetup for WWDC Scholarship and Swift Student Challenge winners",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 7:00pm-10:00pm. For WWDC Scholarship and Swift Student Challenge winners.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "Beer with Swift @WWDC25 by createwithswift.com",
                eventDescription: "Social event for Swift developers",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 21, minute: 0),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-9:00pm. Requires registration.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            Event(
                title: "iOSDevHappyHour @ WWDC25 IRL",
                eventDescription: "In-person meetup by iOSDevHappyHour",
                location: "Fuego Sports Bar and Club, Sunnyvale, CA",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-10:00pm. Requires registration.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            Event(
                title: "RocketSim Meetup at CommunityKit",
                eventDescription: "RocketSim developer meetup",
                location: "10380 Perimeter Rd, Cupertino, CA 95014 (Hyatt House San Jose Cupertino)",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                category: "Meetup",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 2:00pm-4:00pm. Requires registration.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true,
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "The Interface: WWDC25",
                eventDescription: "Design-focused event",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                category: "Design",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 2:00pm-6:00pm. Requires registration.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            // WEDNESDAY, June 11th
            Event(
                title: "CommunityKit",
                eventDescription: "Community meetups, workshops, hackathons, and more",
                location: "10380 Perimeter Rd, Cupertino, CA 95014 (Hyatt House San Jose Cupertino)",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 17, minute: 0),
                category: "Community",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:00am-5:00pm. Free entry.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "Annual WWDC Women's Lunch (unofficial)",
                eventDescription: "Unofficial women's networking lunch",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 12, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 13, minute: 30),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 12:00pm-1:30pm. Free.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "AiOS Meetup",
                eventDescription: "AI and iOS development meetup",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 16, minute: 30),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                category: "Meetup",
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 4:30pm-6:00pm. Free.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            // THURSDAY, June 12th
            Event(
                title: "One More Thing 2025 - Final Day",
                eventDescription: "Final day of the One More Thing conference",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 8, minute: 30),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 19, minute: 0),
                category: "Conference",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 8:30am-7:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            // Continue with Vision Pro Spatial Art Experience
            Event(
                title: "A Vision Pro Spatial Art Experience — Flatland: Mixed Reality Dreams",
                eventDescription: "Vision Pro spatial art experience - Final days",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 18, minute: 0),
                category: "Experience",
                eventType: EventType.art.rawValue,
                notes: "Runs from 9:00am-6:00pm daily (June 9-12). Free admission.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            )
        ]
        
        for event in events {
            modelContext.insert(event)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving events: \(error)")
        }
    }
    
    // Helper function to create dates more easily
    private static func dateFrom(month: Int, day: Int, year: Int, hour: Int, minute: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.timeZone = TimeZone(identifier: "America/Los_Angeles")

        return Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    // Clear existing events
    private static func clearExistingEvents(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Event.self)
        } catch {
            print("Error clearing existing events: \(error)")
        }
    }
}
