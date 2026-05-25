# WWDCBuddy

WWDCBuddy is an iOS app designed to help you manage WWDC events, connect with friends, and make the most of developer community gatherings.

## Features

### Events
- [x] Load WWDC26 events
- [x] Load WWDC26 events from server
- [x] Add custom event
- [x] Mark which one I will be going
- [x] Show event detail
- [x] Open map
- [x] Associate friends that I meet here
- [x] Choose people I want to meet, and mark done if I did meet
- [x] Add a new friend quickly
- [x] Update with latest events
- [x] Hide events in the past days
- [ ] Show DONE button on the keyboard to hide it
- [ ] Filter user list by text field

### Friends
- [x] List out all friends
- [x] Show friend detail
- [x] Add social media links
- [ ] Save contact detail if shared via app
- [x] Show events that I meet this person
- [x] Quickly jump to social media links of this person
- [ ] Save friends photo
- [ ] Add a checkmark to indicate if I took a picture
- [x] Add litte cross on search bar to reset
- [x] Reset text field when switching filter
- [x] Social handles by default start with small letter
- [x] Unify Add & Edit friend page for social handles

### Profile
- [x] Show my profile
- [x] Show QR code of the contact, ready to be scanned and saved
- [ ] Save my profile pic
- [x] Use NameDrop or fallback to AirDrop to exchange contact
- [ ] Add URL field

### Settings
- [x] List out my social profiles
- [x] Show GitHub open-source link
- [x] Credits to anyone who helps out building the app
- [x] Export data
- [x] Add a way to share the App Store link

### Widget
- [ ] Show QR Code of my profile
- [ ] Live Activity to show joined and ongoing event

### Watch
- [ ] Show QR Code for scan

### Technical Features
- [x] Save data in SwiftData
- [x] Set up SQLiteData `defaultSyncEngine` so distinct local datasets can merge through CloudKit sync
- [x] Available on iPhone and Mac
- [x] Bundle a Rust CLI in the macOS app for events, friends, and friend-event relationships
- [ ] Use App Clips

### Bugs

- [ ] Data is not saved
- [ ] Live Activity couldn't get updated locally
- [ ] Missing events

### Future Plans

- [ ] Show past events
- [ ] Connect to Luma API
- [ ] Capture Twitter handle easily and save to this app

## Getting Started

1. Clone the repository
2. Open `EventBuddy.xcodeproj` in Xcode
3. Build and run the project

## Command Line Tool

The macOS app bundles `wwdcbuddy` and can install it from Settings > Data. The CLI reads events, friends, and relationships from the shared app-group SQLite database. Mutating commands queue work to the running Mac app so saves go through SQLiteData and trigger iCloud push when sync is enabled.

See [docs/wwdcbuddy-cli.md](docs/wwdcbuddy-cli.md) for commands and install details.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## WWDC26 Event Data

WWDCBuddy includes a curated WWDC26 event list for Apple Park, Cupertino, San Jose, Sunnyvale, nearby Bay Area gatherings, online events, and selected watch parties. Event details are refreshed from organizer pages first, then checked against aggregate and discovery sources.

Source priority:

1. Organizer pages for canonical time, venue, RSVP status, tickets, and notes.
2. CommunityKit schedule for CommunityKit-hosted sessions without dedicated event pages.
3. Apple Community-driven events for curated WWDC26 discovery.
4. Community aggregators and social posts for discovery and cross-checking.

Credits for event data and discovery:

- [Apple WWDC26](https://developer.apple.com/wwdc26/) and [Apple Community-driven events](https://developer.apple.com/community/events/)
- [CommunityKit](https://communitykit.social/schedule/) and the [CommunityKit Luma calendar](https://luma.com/communitykit)
- [twostraws/wwdc](https://github.com/twostraws/wwdc)
- Event organizers publishing details through Luma, Eventbrite, TicketTailor, Meetup, Kommunity, Framna, MacPaw, and other public event pages
- Community members sharing event announcements on X and other public channels

The detailed import notes live in [EventBuddy-WWDC26-EventSources.md](EventBuddy-WWDC26-EventSources.md).

## Project Structure

```
EventBuddy/
├── Models/          # Data models and SwiftData entities
├── Services/        # Business logic and data services
├── Views/           # SwiftUI views organized by feature
│   ├── Components/  # Reusable UI components
│   ├── Events/      # Event-related views
│   ├── Friends/     # Friend management views
│   └── Profile/     # Profile and settings views
└── Assets.xcassets/ # App icons and other assets
```

## Contributing

This project is part of the BuildWithHarry series. Contributions and suggestions are welcome!

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

The MIT License is a permissive license that is short and to the point. It lets people do anything they want with your code as long as they provide attribution back to you and don't hold you liable.

We welcome contributions from the community! Feel free to fork this repository, make your changes, and submit a pull request. Together, we can make WWDCBuddy even better.
