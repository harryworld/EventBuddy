# EventBuddy - App Structure

## App Navigation Structure

```
EventBuddy
├── Onboarding
│   ├── Login/Registration
│   └── Profile Setup
│
├── Events Tab
│   ├── Events List
│   │   └── Filter/Search
│   ├── Event Details
│   │   ├── Information
│   │   ├── Location
│   │   ├── Date/Time
│   │   └── Attendees List
│   ├── Add/Edit Event
│   │   └── Friend Selection
│   └── Event Invitations
│
├── Friends Tab
│   ├── Friends List
│   │   └── Search
│   ├── Friend Details
│   │   ├── Profile Info
│   │   └── Shared Events
│   ├── Add Friend
│   │   └── Import Contacts
│   └── Friend Requests
│
├── Profile Tab
│   ├── Personal Info
│   ├── Social Media Links
│   │   ├── Twitter/X
│   │   ├── LinkedIn
│   │   ├── GitHub
│   │   └── Others
│   ├── Profile Sharing
│   │   ├── QR Code
│   │   └── Share Link
│   └── Activity History
│
└── Settings Tab
    ├── Account Settings
    ├── Notifications
    ├── Privacy
    ├── Appearance
    ├── Data Management
    └── Help/Support
```

## Data Model Overview

```
┌────────────────────┐       ┌────────────────────┐
│       User         │       │       Event        │
├────────────────────┤       ├────────────────────┤
│ - id               │       │ - id               │
│ - name             │       │ - title            │
│ - email            │       │ - description      │
│ - profileImage     │       │ - location         │
│ - socialAccounts   │       │ - dateTime         │
│ - friends          │◄─────►│ - organizer        │
│ - events           │       │ - attendees        │
│ - settings         │       │ - category         │
└────────────────────┘       └────────────────────┘
           ▲                            ▲
           │                            │
           │                            │
           │                            │
           ▼                            ▼
┌────────────────────┐       ┌────────────────────┐
│      Friend        │       │     Attendance     │
├────────────────────┤       ├────────────────────┤
│ - id               │       │ - userId           │
│ - userId           │       │ - eventId          │
│ - name             │       │ - status           │
│ - contactInfo      │       │ - responseDate     │
│ - events           │       │                    │
└────────────────────┘       └────────────────────┘
```

## UI Wireframe Components

1. **Event List Item**
   - Event image/icon
   - Title
   - Date
   - Location
   - Attendee count

2. **Friend List Item**
   - Profile photo
   - Name
   - Shared events count
   - Last interaction

3. **Event Detail View**
   - Header image
   - Title and description
   - Date/time with calendar add option
   - Location with map
   - Attendee list with status
   - Action buttons (RSVP, Share, Edit)

4. **Profile View**
   - Cover and profile image
   - Name and bio
   - Social media links
   - Recent events
   - Share profile button

5. **Settings Controls**
   - Toggle switches
   - Selection lists
   - Action buttons
   - Info panels 