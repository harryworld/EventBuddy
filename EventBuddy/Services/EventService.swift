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
                title: "Fundamentals of 3D Graphics Programming with Metal",
                eventDescription: "Half-day workshop led by Warren Moore",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Premium workshop. Requires workshop ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "MLX – A Practical Introduction",
                eventDescription: "Half-day workshop led by Vatsal Manot",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 13, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Premium workshop. Requires workshop ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
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
                eventDescription: "Let's kick off WWDC 2025 with some fresh air, great vibes, and an energizing 5-mile (7.5 km) run! Group run for conference attendees.",
                location: "Apple Park Visitor Center",
                address: "10600 N Tantau Ave, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 10:00am-12:00pm. 5-mile energizing run. 3 people going as of last update. Registration suggested.",
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
                title: "Level up your Swift",
                eventDescription: "Workshop led by Paul Hudson",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 9, minute: 30),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 12, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Premium workshop. Requires workshop ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),

            Event(
                title: "Concurrency Fundamentals with Swift 6.2",
                eventDescription: "Half-day workshop led by Matt Massicotte",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 13, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Premium workshop. Requires workshop ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),

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
                startDate: dateFrom(month: 6, day: 8, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 8, year: 2025, hour: 10, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 8:00am-10:00am. Registration suggested.",
                requiresRegistration: true,
                url: "https://lu.ma/713c95jq"
            ),

            Event(
                title: "Core Coffee - WWDC Edition",
                eventDescription: "Coffee chat about last-minute WWDC predictions, development, tech, and everything in-between 🍏 Hosted by Kai Dombrowski.",
                location: "Voyager Craft Coffee (San Pedro Square)",
                address: "111 W St John St, San Jose, CA 95113, USA",
                startDate: dateFrom(month: 6, day: 7, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 7, year: 2025, hour: 12, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 10:00am-12:00pm PDT (GMT-7). Registration suggested. Hosted by Kai Dombrowski (@kaidombrowski). 71+ on waitlist.",
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
                title: "CommunityKit Hackathon Space - Day 1",
                eventDescription: "Continuous hackathon and coding space",
                location: "Hyatt House San Jose Cupertino - Board Room",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "All-day hackathon space at CommunityKit.",
                requiresRegistration: true,
                url: "https://communitykit.social/schedule.html"
            ),
            
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
                eventDescription: "🇫🇷🇧🇪🇨🇦🇨🇭 French-speaking community dinner. Note to WWDC community members: This gathering is intended for French-speaking attendees.",
                location: "Restaurant in Cupertino",
                address: "10088 Wolfe Road, Cupertino",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 30),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00pm-10:30pm. 4 going, 2 interested as of last update. Requires registration.",
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
            
            Event(
                title: "Vision Pro Developers Meetup",
                eventDescription: "Meetup for Vision Pro developers",
                location: "Hyatt House San Jose Cupertino - Room 1",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Vision Pro developers meetup at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/jz8wgmls"
            ),
            
            Event(
                title: "EmpowerApps.Show LIVE with Leo Dion",
                eventDescription: "Live recording of EmpowerApps.Show podcast",
                location: "Hyatt House San Jose Cupertino - Room 2",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 16, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Live podcast recording at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/snplx9gn"
            ),
            
            // TUESDAY, June 10th
            Event(
                title: "CommunityKit Hackathon Space - Day 2",
                eventDescription: "Continuous hackathon and coding space",
                location: "Hyatt House San Jose Cupertino - Board Room",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "All-day hackathon space at CommunityKit.",
                requiresRegistration: true,
                url: "https://communitykit.social/schedule.html"
            ),
            
            Event(
                title: "Lightning Talks",
                eventDescription: "Quick presentation sessions",
                location: "Hyatt House San Jose Cupertino - Room 1",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 11, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Lightning talks at CommunityKit. Registration to present available.",
                requiresRegistration: true,
                url: "https://docs.google.com/forms/d/e/1FAIpQLScA0IWK6m64fLAv97-Oqj5Fr8JtOXQ7SVtBqKN0xOuOF596Lg/viewform"
            ),
            
            Event(
                title: "What's New in visionOS at WWDC 25",
                eventDescription: "Speaker session by John Forester",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "Apple Intelligence Automators Meetup",
                eventDescription: "Meetup focused on Apple Intelligence and automation",
                location: "Hyatt House San Jose Cupertino - Room 1",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Apple Intelligence and automation meetup at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/ai6mx0lr"
            ),
            
            Event(
                title: "try! Swift",
                eventDescription: "try! Swift community meetup",
                location: "Hyatt House San Jose Cupertino - Room 2",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "try! Swift community meetup at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/v554k2fj"
            ),
            
            Event(
                title: "RocketSim Meetup at CommunityKit",
                eventDescription: "RocketSim developer meetup",
                location: "Hyatt House San Jose Cupertino - Room 3",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "RocketSim developer meetup at CommunityKit.",
                requiresRegistration: true,
                url: "https://t.co/WFWWzNlMMJ"
            ),
            
            Event(
                title: "Hacking with Swift IRL",
                eventDescription: "Hacking with Swift community session",
                location: "Hyatt House San Jose Cupertino - Rooms 1-4",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Hacking with Swift session at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/4mk22om8"
            ),
            
            Event(
                title: "Swift Over Coffee LIVE",
                eventDescription: "Live Swift Over Coffee session",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Live Swift Over Coffee session at CommunityKit.",
                requiresRegistration: true,
                url: "https://communitykit.social/schedule.html"
            ),
            
            Event(
                title: "What's New in Swift Concurrency",
                eventDescription: "Speaker session by Matt Massicotte",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "Fireside Chat with Michael Darius",
                eventDescription: "Interview session with Michael Darius",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 11, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "One More Thing 2025 - Day 3",
                eventDescription: "Conference event for iOS developers - Day 3",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 17, minute: 30),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 8:00am-5:30pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "WWDC Women's Get-Together Breakfast",
                eventDescription: "Breakfast meetup for women in tech",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 7, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 7:00am-9:00am. RSVP Required. Part of CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/lcaz5v0q"
            ),
            
            Event(
                title: "Apple Developer Activities - Morning",
                eventDescription: "Official Apple Developer Activities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 12, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Activities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "Apple Developer Activities - Afternoon",
                eventDescription: "Official Apple Developer Activities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 16, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Activities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "Apple Developer Activities - Evening",
                eventDescription: "Official Apple Developer Activities",
                location: "Apple Developer Center Cupertino",
                address: "10500 N Tantau Ave, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 20, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Official Apple Developer Activities. Requires WWDC ticket.",
                requiresTicket: true,
                url: "https://developer.apple.com/wwdc25/"
            ),
            
            Event(
                title: "CommunityKit - Day 2",
                eventDescription: "Community event for developers",
                location: "Hyatt House San Jose Cupertino",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 17, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 9:00am-5:00pm",
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
                title: "#WWDCScholars meetup at WWDC25",
                eventDescription: "Meetup for WWDC Scholarship and Swift Student Challenge winners",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 22, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 7:00pm-10:00pm. For WWDC Scholarship and Swift Student Challenge winners. Part of CommunityKit.",
                requiresRegistration: true,
                url: "https://docs.google.com/forms/d/e/1FAIpQLSeVb_GYJE5twJYzbg-iaTFi29_1ouKHfPb88A6KGeUZ0uz4fhg/viewform"
            ),
            
            Event(
                title: "WWDC'25 Watch Party @ Komunite Space, Istanbul",
                eventDescription: "Watch party in Istanbul",
                location: "Istanbul, Turkey",
                address: "Istanbul, Turkey",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 9, year: 2025, hour: 22, minute: 0),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:00pm-10:00pm IST",
                url: "https://kommunity.com/nsistanbul/events/wwdc25-seyir-partisi-6c721925",
                originalTimezoneIdentifier: "Europe/Istanbul"
            ),
            
            Event(
                title: "WWDC'25 Watch Party Ahmedabad",
                eventDescription: "Watch party in Ahmedabad",
                location: "Ahmedabad, India",
                address: "Ahmedabad, India",
                startDate: dateFrom(month: 6, day: 9, year: 2025, hour: 19, minute: 30),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 0, minute: 30),
                eventType: EventType.watchParty.rawValue,
                notes: "Runs from 7:30pm-12:30am IST",
                url: "https://lu.ma/kne1yfpm",
                originalTimezoneIdentifier: "Asia/Kolkata"
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
                title: "CommunityKit Hackathon Space - Day 3",
                eventDescription: "Continuous hackathon and coding space",
                location: "Hyatt House San Jose Cupertino - Board Room",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "All-day hackathon space at CommunityKit.",
                requiresRegistration: true,
                url: "https://communitykit.social/schedule.html"
            ),
            
            Event(
                title: "Trivia Game with Matt Heaney and Tyler Hillsman",
                eventDescription: "Interactive trivia game session",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 9, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 10, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Trivia game at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/1eldc9q3"
            ),
            
            Event(
                title: "What's New in AI/ML",
                eventDescription: "Speaker session by Rudrank Riyam",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 9, minute: 30),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 10, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "LLMs on MLX for absolute beginners",
                eventDescription: "Speaker session by Ronald Mannak",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 10, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "Launched LIVE with Charlie Chapman",
                eventDescription: "Live recording of Launched podcast",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 11, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 12, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Live podcast recording at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/htlbbu10"
            ),
            
            Event(
                title: "Indie Fair",
                eventDescription: "Showcase for indie developers and apps",
                location: "Hyatt House San Jose Cupertino - All Rooms",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 14, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 16, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Indie developer showcase at CommunityKit. Registration to present available.",
                requiresRegistration: true,
                url: "https://docs.google.com/forms/d/e/1FAIpQLSeMwmzORBNswW8qrzjJXwelaAJPb9o92l3uSUS-LBNVg1Ggqg/viewform"
            ),
            
            Event(
                title: "Vapor@WWDC",
                eventDescription: "Vapor framework community meetup",
                location: "Hyatt House San Jose Cupertino - Rooms 1-2",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 16, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Vapor framework community meetup at CommunityKit.",
                requiresRegistration: true,
                url: "https://lu.ma/zihfxdqz"
            ),
            
            Event(
                title: "Swift Multiplatform",
                eventDescription: "Speaker session by Serhii Popov",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 10, minute: 30),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 11, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "One More Thing 2025 - Day 4",
                eventDescription: "Conference event for iOS developers - Day 4",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 17, minute: 30),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 8:00am-5:30pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "CommunityKit - Day 3",
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
            
            Event(
                title: "CommunityKit Closer",
                eventDescription: "Closing session for CommunityKit",
                location: "Hyatt House San Jose Cupertino - Room 1",
                address: "10380 Perimeter Rd, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 19, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Closing session for CommunityKit.",
                requiresRegistration: true,
                url: "https://communitykit.social/schedule.html"
            ),
            
            // THURSDAY, June 12th
            Event(
                title: "What's New in Testing at WWDC 25",
                eventDescription: "Speaker session by Rachel Brindle",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 10, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 10, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "What's New in Developer Tools at WWDC 25",
                eventDescription: "Speaker session on developer tools",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 10, minute: 30),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 11, minute: 0),
                eventType: EventType.keynote.rawValue,
                notes: "Part of One More Thing conference.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "James Dempsey's WWDC Week In Review",
                eventDescription: "Weekly review session with James Dempsey",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 15, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 16, minute: 30),
                eventType: EventType.keynote.rawValue,
                notes: "RSVP required. Part of One More Thing conference.",
                requiresRegistration: true,
                url: "https://lu.ma/wwdc-week-in-review-with-james-dempsey-2025"
            ),
            
            Event(
                title: "OMT Closing Party & Happy Hour",
                eventDescription: "Closing celebration for One More Thing conference",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 16, minute: 30),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 19, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Conference closing celebration.",
                requiresTicket: true,
                url: "https://omt-conf.com/#OMTSchedule"
            ),
            
            Event(
                title: "One More Thing 2025 - Day 5",
                eventDescription: "Conference event for iOS developers - Day 5",
                location: "Residence Inn, Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, United States",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 8, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 17, minute: 30),
                eventType: EventType.meetup.rawValue,
                notes: "Runs from 8:00am-5:30pm. Requires a ticket.",
                requiresTicket: true,
                url: "https://omt-conf.com/"
            ),
            
            Event(
                title: "Annual WWDC Women's Lunch (unofficial)",
                eventDescription: "Unofficial lunch meetup for women in tech",
                location: "Cupertino, California",
                address: "Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 12, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 14, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Free admission. Unofficial women's lunch meetup.",
                requiresRegistration: false,
                url: "https://www.meetup.com/swift-language/events/307194649"
            ),
            
            Event(
                title: "Live near WWDC",
                eventDescription: "Local community gathering for nearby residents",
                location: "Cupertino, California",
                address: "Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 22, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Community gathering for those living near WWDC area.",
                requiresRegistration: false,
                url: "https://livenearwwdc.com/"
            ),
            
            // ADDITIONAL EVENTS FROM DUBDUB.COMMUNITY AND LU.MA
            Event(
                title: "Cloud x Voice x Beers @ WWDC Social",
                eventDescription: "Calling all mobile developers in town for WWDC 2025! Join us for an evening of networking, insights, and great conversations.",
                location: "Stevens Creek Boulevard Area",
                address: "Stevens Creek Boulevard, Cupertino",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 19, minute: 0),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 22, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Networking event for mobile developers. 3 going, 1 interested as of last update.",
                requiresRegistration: true,
                url: "https://dubdub.community/"
            ),
            
            // VIBE CODE & CHILL EVENT FROM LU.MA
            Event(
                title: "Vibe Code & Chill: WWDC 2025 Edition",
                eventDescription: "Join us for a laid-back coding session where we will vibe code and create apps using the latest Apple APIs, frameworks, and features revealed at WWDC 2025. We will hopefully use Apple's latest AI integration with Xcode or whatever AI tool you prefer. All skill levels are welcome, so grab your Mac, sip some drinks, and vibe to the WWDC energy!",
                location: "Residence Inn San Jose Cupertino",
                address: "19429 Stevens Creek Blvd, Cupertino, CA 95014, USA",
                startDate: dateFrom(month: 6, day: 11, year: 2025, hour: 18, minute: 30),
                endDate: dateFrom(month: 6, day: 11, year: 2025, hour: 21, minute: 0),
                eventType: EventType.meetup.rawValue,
                notes: "Laid-back coding session with latest Apple APIs. All skill levels welcome. Hosted by One More Thing 2025 & Rudrank Riyam. 44 people going as of last update.",
                requiresRegistration: true,
                url: "https://lu.ma/vibe-code-omt"
            ),
            
            Event(
                title: "Core Coffee – WWDC Edition pt. 2 ☕️",
                eventDescription: "Morning(-ish) meetup for people to catch up to talk about iOS, macOS, watchOS, tvOS and everything in between. Part 2 of the WWDC Core Coffee series.",
                location: "Voyager Craft Coffee - Cupertino",
                address: "Voyager Craft Coffee, Cupertino, CA",
                startDate: dateFrom(month: 6, day: 10, year: 2025, hour: 11, minute: 0),
                endDate: dateFrom(month: 6, day: 10, year: 2025, hour: 13, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 11:00am-1:00pm PDT (GMT-7). Hosted by Malin & Kai. 20+ on waitlist.",
                requiresRegistration: true,
                url: "https://lu.ma/83g359qs"
            ),
            
            Event(
                title: "Core Coffee ✗ LookUp Anniversary – WWDC Edition",
                eventDescription: "Special Core Coffee collaboration with LookUp Anniversary during WWDC. Morning meetup for Apple platform developers and enthusiasts.",
                location: "Caffè Macs - Apple Park Visitor Center",
                address: "Apple Park Visitor Center, 10600 N Tantau Ave, Cupertino, CA 95014",
                startDate: dateFrom(month: 6, day: 12, year: 2025, hour: 11, minute: 0),
                endDate: dateFrom(month: 6, day: 12, year: 2025, hour: 13, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 11:00am-1:00pm PDT (GMT-7). Special LookUp Anniversary collaboration. Hosted by Kai & Malin. 20+ on waitlist.",
                requiresRegistration: true,
                url: "https://lu.ma/zrz0r147"
            ),
            
            Event(
                title: "Core Coffee – Post-WWDC In-Person Edition ☕️",
                eventDescription: "Post-WWDC Core Coffee meetup to debrief and discuss all the announcements from the week. Morning meetup for developers to catch up.",
                location: "Prototype Coffee",
                address: "Prototype Coffee, Cupertino, CA",
                startDate: dateFrom(month: 6, day: 15, year: 2025, hour: 11, minute: 0),
                endDate: dateFrom(month: 6, day: 15, year: 2025, hour: 13, minute: 0),
                eventType: EventType.social.rawValue,
                notes: "Runs from 11:00am-1:00pm PDT (GMT-7). Post-WWDC debrief session. Hosted by Kai.",
                requiresRegistration: true,
                url: "https://lu.ma/wbcs4l69"
            )
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

