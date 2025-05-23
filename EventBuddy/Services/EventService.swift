import Foundation
import SwiftData
import SwiftUI

@MainActor
class EventService {
    
    // Add sample WWDC events based on the GitHub repo data
    static func addSampleWWDCEvents(modelContext: ModelContext) {
        // Clear existing events first
        clearExistingEvents(modelContext: modelContext)
        
        let events = [
            // SATURDAY, June 7th
            Event(
                title: "One More Thing 2025",
                eventDescription: "Conference event for iOS developers",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 16, minute: 0),
                category: "Conference",
                eventType: EventType.conference.rawValue,
                notes: "Runs from 9:00am-4:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "WWDC Run",
                eventDescription: "Group run for conference attendees",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                category: "Social",
                eventType: EventType.run.rawValue,
                notes: "Runs from 10:00am-12:00pm",
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
                location: "Apple Park, Cupertino, California",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Runs from 6:30pm-10:00pm",
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
                notes: "Runs from 9:30am-4:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "WWDC Check-in",
                eventDescription: "Official WWDC check-in with refreshments and games",
                location: "Infinite Loop, Cupertino, California",
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
                notes: "Runs from 6:30pm-11:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "A Vision Pro Spatial Art Experience",
                eventDescription: "Flatland: Mixed Reality Dreams",
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
                location: "Apple Park, Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                category: "Official",
                eventType: EventType.event.rawValue,
                notes: "Runs from 9:00am-4:00pm. Requires WWDC ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "WWDC25 Keynote & SOTU Watch Party",
                eventDescription: "Watch party hosted by iOSDevHappyHour at CommunityKit",
                location: "CommunityKit, Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 7, minute: 45),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:45am-4:00pm",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
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
                title: "WWDC'25 TLV Watch Party",
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
                title: "NSLondon WWDC25 keynote viewing party",
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
            
            Event(
                title: "WWDC25 After Party",
                eventDescription: "Official WWDC after party celebration",
                location: "Apple Park, Cupertino, California",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 0),
                category: "Social",
                eventType: EventType.party.rawValue,
                notes: "Runs from 6:00pm-10:00pm. Requires WWDC ticket.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            // TUESDAY, June 10th
            Event(
                title: "SwiftUI Workshop",
                eventDescription: "Hands-on SwiftUI workshop with Apple engineers",
                location: "Apple Developer Academy, Cupertino",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 12, minute: 0),
                category: "Workshop",
                eventType: EventType.conference.rawValue,
                notes: "Limited capacity. Bring your MacBook.",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            Event(
                title: "Vision Pro Dev Meetup",
                eventDescription: "Meetup for Vision Pro developers to share experiences",
                location: "Infinite Loop, Cupertino",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                category: "Meetup",
                eventType: EventType.meetup.rawValue,
                notes: "Informal gathering for Vision Pro developers",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "Swift Concurrency Deep Dive",
                eventDescription: "Technical session on Swift Concurrency advancements",
                location: "Apple Park, Cupertino",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 12, minute: 0),
                category: "Session",
                eventType: EventType.conference.rawValue,
                notes: "Technical session for advanced Swift developers",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "Women in Tech Networking",
                eventDescription: "Networking event for women in technology",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 17, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 30),
                category: "Networking",
                eventType: EventType.social.rawValue,
                notes: "Empowering event with guest speakers and networking",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            // WEDNESDAY, June 11th
            Event(
                title: "Accessibility in iOS Apps",
                eventDescription: "Workshop on building more accessible iOS applications",
                location: "Apple Developer Academy, Cupertino",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 11, minute: 30),
                category: "Workshop",
                eventType: EventType.conference.rawValue,
                notes: "Practical workshop on implementing accessibility features",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "Independent Developer Lunch",
                eventDescription: "Casual lunch meetup for indie developers",
                location: "Caffè Macs, Apple Park",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 12, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 14, minute: 0),
                category: "Social",
                eventType: EventType.informal.rawValue,
                notes: "No registration required, just show up!",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "WWDC Berlin Remote Viewing",
                eventDescription: "Remote session viewing with Berlin Swift community",
                location: "Berlin, Germany",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 16, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 20, minute: 0),
                category: "Watch Party",
                eventType: EventType.watchParty.rawValue,
                notes: "Join fellow developers to watch session recordings",
                isWWDCEvent: true,
                countryCode: "DE",
                countryFlag: "🇩🇪"
            ),
            
            Event(
                title: "Apple Gaming Night",
                eventDescription: "Gaming tournament and networking for game developers",
                location: "Apple Park, Cupertino",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 23, minute: 0),
                category: "Social",
                eventType: EventType.party.rawValue,
                notes: "Fun gaming event with prizes and refreshments",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            // THURSDAY, June 12th
            Event(
                title: "WWDC Lab: SwiftUI Performance",
                eventDescription: "One-on-one lab with Apple engineers about SwiftUI performance",
                location: "Apple Park, Cupertino",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 12, minute: 0),
                category: "Lab",
                eventType: EventType.conference.rawValue,
                notes: "Bring your projects for optimization advice",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "Swift for Good Hackathon",
                eventDescription: "Collaborative coding for charitable projects",
                location: "Cupertino, California",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 18, minute: 0),
                category: "Hackathon",
                eventType: EventType.event.rawValue,
                notes: "Full-day hackathon focused on social impact projects",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresRegistration: true
            ),
            
            Event(
                title: "Machine Learning in iOS Apps",
                eventDescription: "Technical deep dive into CoreML and on-device ML",
                location: "Apple Developer Academy, Cupertino",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 16, minute: 30),
                category: "Workshop",
                eventType: EventType.conference.rawValue,
                notes: "Advanced session on implementing ML in iOS applications",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "Tokyo Swift Meetup: WWDC Special",
                eventDescription: "Special meetup to discuss WWDC announcements",
                location: "Tokyo, Japan",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 21, minute: 30),
                category: "Meetup",
                eventType: EventType.meetup.rawValue,
                notes: "Presentations and discussions in Japanese and English",
                isWWDCEvent: true,
                countryCode: "JP",
                countryFlag: "🇯🇵"
            ),
            
            // FRIDAY, June 13th
            Event(
                title: "SwiftUI Challenge Finals",
                eventDescription: "Final presentation of the week-long SwiftUI Challenge",
                location: "Apple Park, Cupertino",
                startDate: dateFrom(month: 6, day: 13, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 13, year: 2025, hour: 13, minute: 0),
                category: "Contest",
                eventType: EventType.event.rawValue,
                notes: "Winners announcement and demo of top projects",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "WWDC25 Farewell Lunch",
                eventDescription: "Casual farewell lunch for WWDC attendees",
                location: "Infinite Loop, Cupertino",
                startDate: dateFrom(month: 6, day: 13, year: 2025, hour: 12, minute: 30),
                endDate: dateFrom(month: 6, day: 13, year: 2025, hour: 14, minute: 30),
                category: "Social",
                eventType: EventType.social.rawValue,
                notes: "Last chance to connect with fellow developers",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸"
            ),
            
            Event(
                title: "Swift Community Awards",
                eventDescription: "Annual recognition of outstanding Swift community contributions",
                location: "San Jose Convention Center, California",
                startDate: dateFrom(month: 6, day: 13, year: 2025, hour: 17, minute: 0),
                endDate: dateFrom(month: 6, day: 13, year: 2025, hour: 20, minute: 0),
                category: "Awards",
                eventType: EventType.party.rawValue,
                notes: "Semi-formal event with dinner and awards ceremony",
                isWWDCEvent: true,
                countryCode: "US",
                countryFlag: "🇺🇸",
                requiresTicket: true
            ),
            
            Event(
                title: "Sydney WWDC Wrap-up",
                eventDescription: "Community discussion of WWDC announcements",
                location: "Sydney, Australia",
                startDate: dateFrom(month: 6, day: 13, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 13, year: 2025, hour: 21, minute: 0),
                category: "Meetup",
                eventType: EventType.meetup.rawValue,
                notes: "Casual meetup with presentations and networking",
                isWWDCEvent: true,
                countryCode: "AU",
                countryFlag: "🇦🇺"
            ),
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
