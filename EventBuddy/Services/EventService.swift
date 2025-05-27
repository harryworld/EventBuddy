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
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:00am-4:00pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "WWDC 2025 Run !",
                eventDescription: "Group run for conference attendees",
                location: "Apple Park Visitor Center",
                address: "10600 N Tantau Ave, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 10:00am-12:00pm. Registration suggested.",
                requiresRegistration: true,
                url: "https://lu.ma/uob9fld4"
            ),
            
            Event(
                title: "Informal Pre-WWDC 25 Gathering",
                eventDescription: "Casual meetup before the conference starts",
                location: "San Pedro Square Market",
                address: "87 N San Pedro St San Jose CA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 17, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 20, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 5:00pm-8:00pm",
                requiresRegistration: true,
                url: "https://pre-wwdc25.splashthat.com/"
            ),
            
            Event(
                title: "Apple Park Happy Hour",
                eventDescription: "Social event at Apple Park",
                location: "Duke of Edinburgh",
                address: "10801 North Wolfe Road Cupertino, CA 95014 United States",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 22, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 6:30pm-10:00pm. RSVP requested.",
                requiresRegistration: true,
                url: "https://www.eventbrite.com/e/apple-park-happy-hour-tickets-1335249620559"
            ),
            
            // SUNDAY, June 8th
            Event(
                title: "WW Run",
                eventDescription: "Group run for conference attendees",
                location: "Philz Coffee",
                address: "19439 Stevens Creek Blvd, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 7, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 8, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00am-8:00am. Registration suggested.",
                requiresRegistration: true,
                url: "https://lu.ma/5zhaoikv"
            ),

            Event(
                title: "Run & Walk with Ctrl+Alt+Run",
                eventDescription: "Group run for conference attendees",
                location: "Apple Park Visitor Center",
                address: "10600 N Tantau Ave, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 8:00am-10:00am. Registration suggested.",
                requiresRegistration: true,
                url: "https://lu.ma/713c95jq"
            ),

            Event(
                title: "Core Coffee - WWDC Edition",
                eventDescription: "Coffee chat about last-minute WWDC predictions, development, tech, and everything in-between 🍏",
                location: "Voyager Craft Coffee (San Pedro Square)",
                address: "111 W St John St, San Jose, CA 95113, USA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 10:00am-12:00am. Registration suggested.",
                requiresRegistration: true,
                url: "https://lu.ma/tvpvts9a"
            ),

            Event(
                title: "One More Thing 2025 - Day 2",
                eventDescription: "Conference event for iOS developers - Day 2",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 9, minute: 30),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:30am-4:00pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "WWDC Check-in, refreshments, and games",
                eventDescription: "Official WWDC check-in with refreshments and games at Infinite Loop",
                location: "Infinite Loop",
                address: "1 Infinite Loop, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 15, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 19, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 3:00pm-7:00pm at Infinite Loop. Requires WWDC ticket.",
                requiresTicket: true
            ),
            
            Event(
                title: "RevenueCat's Pre-WWDC Bashcade",
                eventDescription: "Fun event before WWDC with games and networking",
                location: "Miniboss",
                address: "52 E Santa Clara St, San Jose, CA 95113",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 23, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 6:30pm-11:00pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://lu.ma/94pquugz"
            ),
            
            Event(
                title: "A Vision Pro Spatial Art Experience — Flatland: Mixed Reality Dreams",
                eventDescription: "Vision Pro spatial art experience",
                location: "Cupertino, California",
                address: "Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 18, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 9:00am-6:00pm. Free admission.",
                url: "https://story.app/wwdc"
            ),
            
            // MONDAY, June 9th (Keynote Day)
            Event(
                title: "WWDC 2025 Keynote",
                eventDescription: "Official Apple WWDC Special Event",
                location: "Apple Park",
                address: "1 Apple Park Way, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Runs from 9:00am-4:00pm. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "WWDC25 Keynote & SOTU Watch Party",
                eventDescription: "Watch party hosted by iOSDevHappyHour at CommunityKit",
                location: "Hyatt House San Jose Cupertino",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 7, minute: 45),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:45am-4:00pm. Hosted by iOSDevHappyHour at CommunityKit.",
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "WWDC25 Keynote & SOTU Watch Party by One More Thing",
                eventDescription: "Watch party hosted by One More Thing",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 17, minute: 30),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 8:00am-5:30pm",
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "Students, Swift, St★rs",
                eventDescription: "Event for students and Swift developers",
                location: "Hilton Garden Inn, Cupertino, California",
                address: "10741 N Wolfe Rd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 7:00pm-10:00pm",
                requiresRegistration: true,
                url: "https://ti.to/ios-conf-sg/students-swift-stars-2025"
            ),
            
            Event(
                title: "🇫🇷🇨🇦🇱🇺🇧🇪 The French Dinner",
                eventDescription: "French-speaking community dinner",
                location: "Cupertino, California",
                address: "Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 30),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-10:30pm. Requires registration.",
                requiresRegistration: true,
                url: "https://lu.ma/9vs7dmot"
            ),
            
            // International Watch Parties
            Event(
                title: "WWDC'25 TLV Watch Party @ monday.com",
                eventDescription: "Watch party at monday.com",
                location: "Tel Aviv, Israel",
                address: "Tel Aviv, Israel",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 23, minute: 0),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:00pm-11:00pm IDT",
                originalTimezoneIdentifier: "Asia/Jerusalem"
            ),
            
            Event(
                title: "NSLondon WWDC25 keynote viewing party at Ford",
                eventDescription: "Watch party at Ford",
                location: "London, United Kingdom",
                address: "London, United Kingdom",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 17, minute: 30),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 20, minute: 30),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 5:30pm-8:30pm BST",
                originalTimezoneIdentifier: "Europe/London"
            ),
            
            Event(
                title: "WWDC25 Keynote Watch Party @ Bangalore",
                eventDescription: "Watch party in Bangalore",
                location: "Bangalore, India",
                address: "Bangalore, India",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 2, minute: 30),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 10:30pm-2:30am IST",
                originalTimezoneIdentifier: "Asia/Kolkata"
            ),
            
            Event(
                title: "WWDC25 Keynote Watch Party @ Tokyo",
                eventDescription: "Watch party in Tokyo",
                location: "Tokyo, Japan",
                address: "Tokyo, Japan",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 2, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 6, minute: 0),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 2:00am-6:00am JST",
                originalTimezoneIdentifier: "Asia/Tokyo"
            ),
            
            Event(
                title: "WWDC25 Keynote Watch Party @ Sydney",
                eventDescription: "Watch party in Sydney",
                location: "Sydney, Australia",
                address: "Sydney, Australia",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 3, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 7, minute: 0),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 3:00am-7:00am AEST",
                originalTimezoneIdentifier: "Australia/Sydney"
            ),
            
            // TUESDAY, June 10th
            Event(
                title: "Apple Developer Activities - Morning",
                eventDescription: "Official Apple Developer Acitvities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 12, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Acitvities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "Apple Developer Activities - Afternoon",
                eventDescription: "Official Apple Developer Acitvities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Acitvities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "Apple Developer Activities - Evening",
                eventDescription: "Official Apple Developer Acitvities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 20, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Acitvities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "CommunityKit - Day 2",
                eventDescription: "Community event for developers",
                location: "Hyatt House San Jose Cupertino",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 12, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 12:00pm-10:00pm",
                requiresRegistration: true,
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "Beer with Swift @WWDC25 by createwithswift.com",
                eventDescription: "Social event for Swift developers",
                location: "Barebottle Brewing Co",
                address: "2520 Augustine Dr, Santa Clara, CA 95054",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 21, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-9:00pm. Requires registration.",
                requiresRegistration: true,
                url: "https://www.icloud.com/invites/0fffU92Mu3cnJVlXnUpyZq82A"
            ),
            
            Event(
                title: "iOSDevHappyHour @ WWDC25 IRL",
                eventDescription: "In-person meetup by iOSDevHappyHour",
                location: "Fuego Sports Bar and Club",
                address: "140 South Murphy Avenue Sunnyvale, CA 94086 United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-10:00pm. Requires registration.",
                requiresRegistration: true,
                url: "https://idhhwwdc25irl.eventbrite.com/"
            ),
            
            Event(
                title: "RocketSim Meetup at CommunityKit",
                eventDescription: "RocketSim developer meetup",
                location: "Hyatt House San Jose Cupertino",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 2:00pm-4:00pm. Requires registration.",
                requiresRegistration: true,
                url: "https://lu.ma/g4m3q37q"
            ),
            
            Event(
                title: "The Interface: WWDC25",
                eventDescription: "Design-focused event",
                location: "Homestead Bowl & The X Bar",
                address: "20990 Homestead Rd, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 2:00pm-6:00pm. Requires registration.",
                requiresRegistration: true,
                url: "https://theinterface.design/"
            ),
            
            // WEDNESDAY, June 11th
            Event(
                title: "CommunityKit",
                eventDescription: "Community event for developers - Day 3",
                location: "Hyatt House San Jose Cupertino",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:00am-6:00pm",
                url: "https://communitykit.social/"
            ),
            
            Event(
                title: "AiOS Meetup - WWDC 2025",
                eventDescription: "Meetup for developers on AI Coding",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 16, minute: 30),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 4:30pm-6:00pm. Requires registration.",
                requiresRegistration: true,
                url: "https://lu.ma/aios-omt"
            ),
            
            // THURSDAY, June 12th
        ]
        
        // Insert all events
        for event in events {
            modelContext.insert(event)
        }
        
        // Save the context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save events: \(error)")
        }
    }
    
    private static func clearExistingEvents(modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Event>()
            let existingEvents = try modelContext.fetch(descriptor)
            for event in existingEvents {
                modelContext.delete(event)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear existing events: \(error)")
        }
    }
    
    private static func dateFrom(month: Int, day: Int, year: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date()
    }
}

