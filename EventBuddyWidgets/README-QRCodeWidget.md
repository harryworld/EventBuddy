# QR Code Widget

The QR Code Widget provides quick access to your profile's contact information in QR code format, making it easy to share your contact details with others.

## Features

- **Small Widget (2x2)**: Displays a QR code with "My Contact" label
- **Medium Widget (4x2)**: Shows QR code alongside profile information including name, title, company, email, and phone
- **Tap to Open**: Tapping the widget opens the Profile view in the EventBuddy app

## Widget Sizes

### Small Widget
- Compact QR code display
- Perfect for quick access to contact sharing
- Shows "Setup Profile" message when no profile exists
- Tap to open Profile view in app

### Medium Widget
- QR code on the left side
- Profile details on the right side including:
  - Name and job title/company
  - Email address (if available)
  - Phone number (if available)
  - "Tap to Open Profile" action hint
- Tap anywhere to open Profile view in app

## Setup Requirements

1. **Profile Configuration**: Set up your profile in the EventBuddy app with:
   - Name (required)
   - Email (optional but recommended)
   - Phone number (optional but recommended)
   - Job title and company (optional)

2. **Adding the Widget**:
   - Long press on your home screen
   - Tap the "+" button to add widgets
   - Search for "EventBuddy" 
   - Select "QR Contact" widget
   - Choose your preferred size (Small or Medium)

## QR Code Content

The QR code contains a vCard (Virtual Contact Card) with your profile information:
- Full name
- Email address
- Phone number
- Job title and company
- Social media profiles (configured in your EventBuddy profile)

## Data Updates

- The widget refreshes every 24 hours
- Changes to your profile in the EventBuddy app will be reflected in the widget after the next refresh
- No user interaction required - the widget automatically updates when profile data changes

## Troubleshooting

**QR Code not showing?**
- Ensure you have set up your profile in the EventBuddy app
- Check that your profile has at least a name configured
- Wait a few minutes for the widget to refresh

**Old information showing?**
- The widget updates every 24 hours automatically
- For immediate updates, remove and re-add the widget

## Technical Details

- Built using iOS WidgetKit framework
- Uses SwiftData for profile data access
- Generates QR codes using Core Image's CIFilter.qrCodeGenerator
- Supports vCard format for maximum compatibility with contact apps
- Deep linking via `eventbuddy://profile` URL scheme
- Automatically navigates to Profile tab when tapped 