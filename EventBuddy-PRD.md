# EventBuddy - Product Requirements Document

## Overview
EventBuddy is an iOS application designed to help users organize and manage events, track attendance of friends, and share their profiles. The app aims to simplify event coordination, particularly for community events like WWDC25.

## Target Users
- Event organizers and attendees
- Professional networking communities
- Conference attendees
- Social groups

## Key Features

### 1. Event Management
- Create, view, edit, and delete events
- Display event details (date, time, location, description)
- Categorize events (tech conferences, meetups, social gatherings)
- Filter and search events
- Calendar integration
- Push notifications for upcoming events

### 2. Friend Management
- Add and remove friends from contact list
- Search functionality for friends
- Import contacts from device
- Friend profile viewing

### 3. Event-Friend Association
- Add/remove friends from specific events
- Track RSVPs and attendance
- Send invitations to friends
- View attendee list for each event
- Mark attendance status (going, maybe, not going)

### 4. User Profile
- Personal information management
- Social media account linking (Twitter/X, LinkedIn, GitHub, etc.)
- Customizable profile visibility
- Profile sharing via link or QR code
- Profile image and bio

### 5. Settings
- Notification preferences
- Privacy controls
- Theme customization
- Account management
- Data synchronization options
- Export/import data

## Technical Requirements

### Platform Support
- iOS 16.0+
- Swift 5.7+
- SwiftUI for UI components

### Backend Requirements
- User authentication system
- Cloud storage for user data
- Push notification service
- Social media API integrations

### Data Model
- User (profile, settings, friends list)
- Event (details, location, time, attendees)
- Friend (contact information, attendance history)
- Settings (user preferences)

## User Flow

1. **Onboarding**
   - Account creation/login
   - Profile setup
   - Friend import option

2. **Main Navigation**
   - Tab bar navigation with:
     - Events list
     - Friends list
     - Profile
     - Settings

3. **Event Interaction**
   - Browse events → Select event → View details → Manage attendance → Invite friends

4. **Friend Management**
   - View friends list → Add new friend → Associate with events

5. **Profile Sharing**
   - Edit profile → Configure visible accounts → Generate shareable link/QR code

## Release Plan

### MVP (Version 1.0)
- Basic event creation and management
- Simple friends list
- Core profile functionality
- Essential settings

### Future Enhancements (Version 2.0+)
- Event recommendations
- Advanced search filters
- Group messaging
- Event photo sharing
- Location-based event discovery
- Calendar export functionality
- Dark mode

## Success Metrics
- User registration and retention
- Number of events created
- Friend connections made
- Profile shares
- Daily active users
- Session duration

## Constraints and Considerations
- Privacy compliance (GDPR, CCPA)
- Offline functionality
- Data backup and recovery
- Performance optimization for large friend/event lists
- Accessibility compliance 