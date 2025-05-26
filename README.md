# EventBuddy

EventBuddy is an iOS app designed to help you manage events, connect with friends, and make the most of your conference and meetup experiences. Built specifically with WWDC and developer community events in mind.

## Features

### Events
- [x] Load WWDC25 events
- [x] Load WWDC25 events from server
- [x] Add custom event
- [x] Mark which one I will be going
- [x] Show event detail
- [x] Open map
- [x] Associate friends that I meet here
- [ ] Choose people I want to meet, and mark done if I did meet
- [x] Add a new friend quickly

### Friends
- [x] List out all friends
- [x] Show friend detail
- [x] Add social media links
- [ ] Save contact detail if shared via app
- [x] Show events that I meet this person
- [x] Quickly jump to social media links of this person

### Profile
- [x] Show my profile
- [x] Show QR code of the contact, ready to be scanned and saved
- [ ] Use NameDrop or fallback to AirDrop to exchange contact

### Settings
- [ ] List out my social profiles
- [ ] Credits to anyone who helps out building the app

### Widget
- [ ] Show QR Code of my profile
- [ ] Live Activity to show joined and ongoing event

### Watch
- [ ] Show QR Code for scan

### Technical Features
- [x] Save data in SwiftData
- [ ] Sync via CloudKit
- [ ] Available on iPhone and Mac
- [ ] Use App Clips

### Future Plans

- [ ] Connect to Luma API

## Getting Started

1. Clone the repository
2. Open `EventBuddy.xcodeproj` in Xcode
3. Build and run the project

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

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

We welcome contributions from the community! Feel free to fork this repository, make your changes, and submit a pull request. Together, we can make EventBuddy even better.