# EasitOpen 🕐

An iOS app to help you quickly check opening hours and current status of your favorite businesses. Never wonder if your local coffee shop is open again!

## 📱 Features

### Dashboard
- **Real-time Status**: See which businesses are currently open, closing soon, or closed at a glance
- **Closing Soon Alert**: Orange badge appears when business closes within 60 minutes
- **Custom Labels**: Personalize business names (e.g., "My Favorite Cafe")
- **Today's Hours**: View opening hours for today on each business card
- **Smart Filtering**: Filter by Open, Closing Soon, or Closed status
- **Distance-Based Sorting**: Sort businesses by:
  - Name (alphabetically)
  - Status (Open → Closing Soon → Closed)
  - Distance from current location
  - Distance from home location
- **Distance Display**: See how far each business is from you (in km or meters)
- **Search**: Quickly find a specific business in your saved list
- **Pull-to-Refresh**: Swipe down to update all business hours from Google Places
- **Auto-Refresh**: Stale data (>24 hours) automatically updates on app launch
- **Staleness Indicators**: Orange dot shows when data is >7 days old
- **Easy Management**: Swipe to delete with confirmation prompt

### Search & Add
- **Google Places Integration**: Search for any business using Google Places API
- **Comprehensive Results**: See business name, address, and current status
- **Distance Sorting**: Sort search results by:
  - Relevance (Google's default ranking)
  - Near Me (distance from current location)
  - Near Home (distance from saved home location)
- **Distance Display**: See how far each result is from your reference location
- **One-Tap Add**: Add businesses to your dashboard with a single tap
- **Visual Feedback**: Added businesses show a green checkmark
- **Persistent Results**: Search results remain visible after adding a business
- **Automatic Hours Import**: Opening hours are automatically fetched and saved

### Business Details
- **Custom Labels**: Edit business names with a personal touch
- **Manual Refresh**: Tap refresh button to update individual business hours instantly
- **Last Updated Info**: See when data was last refreshed with staleness indicator
- **Interactive Map**: See business location with MapKit integration
- **Full Weekly Schedule**: View complete opening hours for every day
- **Quick Actions**: Optimized vertical layout (icon + text)
  - Call the business directly
  - Open website in Safari
  - Get directions in Apple Maps
  - All 3 buttons fit without text wrapping
- **Today Highlight**: Current day is highlighted in the schedule
- **Safe Deletion**: Confirmation dialog before removing businesses

### Settings & Customization
- **Notification Management**: View permission status and enable/disable notifications
- **Background Refresh Control**: Toggle automatic background refresh on/off (every 24 hours)
- **Location Services**:
  - View location permission status
  - Enable location services for distance-based features
  - Set home location via:
    - Current device location
    - Manual address entry with map preview
  - View saved home address (not just coordinates)
  - Clear or change home location anytime
- **System Settings Integration**: Quick access to iOS settings for permissions
- **App Information**: View version and API provider details

### Data Refresh System
- **Multiple Refresh Methods**: Pull-to-refresh, auto-refresh, manual per-business, and background refresh
- **Background Refresh**: Automatically updates business hours even when app is closed (configurable interval)
- **Change Detection**: Automatically identifies when hours have been updated
- **Smart Notifications**: Receive alerts when business hours change (requires permission)
- **Detailed Change Tracking**: Know exactly what changed (hours, closures, phone, website)
- **Smart Updates**: Only refreshes businesses with stale data (>24 hours)
- **Visual Feedback**: Color-coded toast messages (green=success, blue=info, orange=warning)
- **Rate Limiting**: 1-second delay between API requests to avoid rate limits
- **Background Operation**: Refreshes don't block the UI

## 🛠 Technical Stack

- **Language**: Swift 6.2
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Maps**: MapKit
- **Location Services**: CoreLocation for distance calculations and geocoding
- **API Integration**: Google Places API (New)
- **Background Tasks**: BGTaskScheduler for background refresh
- **Notifications**: UserNotifications framework for change alerts
- **Testing**: XCTest with comprehensive unit tests (80+ tests)
- **Minimum iOS Version**: iOS 17.0
- **Architecture**: MVVM pattern with SwiftUI

## 🚀 Setup Instructions

### Prerequisites
- macOS with Xcode 15.0 or later
- iOS device or simulator running iOS 17.0+
- Google Cloud account for Places API

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/NissimAmira/EasitOpen.git
   cd EasitOpen
   ```

2. **Get a Google Places API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project (or select existing)
   - Enable "Places API (New)"
   - Navigate to "Credentials" and create an API Key
   - (Optional but recommended) Restrict the key to Places API only

3. **Configure the API Key:**
   ```bash
   cp EasitOpen/Config.swift.template EasitOpen/Config.swift
   ```
   - Open `EasitOpen/Config.swift` in Xcode
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - **Important:** Do NOT commit `Config.swift` (it's in .gitignore)

4. **Open in Xcode:**
   ```bash
   open EasitOpen.xcodeproj
   ```

5. **Enable Background Refresh (Required):**
   - Follow instructions in `BACKGROUND_REFRESH_SETUP.md`
   - Add Background Modes capability
   - Register background task identifier in Info.plist

6. **Build and Run:**
   - Select your target device or simulator
   - Press Cmd+R or click the Play button
   - For physical devices: You may need to trust your developer account in Settings
   - **Note**: Background refresh works best on physical devices, not simulators

## 📂 Project Structure

```
EasitOpen/
├── EasitOpen/
│   ├── Models/
│   │   ├── Business.swift          # Business data model with distance calculations
│   │   └── DaySchedule.swift       # Opening hours model
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── DashboardView.swift     # Business dashboard with distance sorting
│   │   ├── BusinessCardView.swift  # Business card component with distance display
│   │   ├── SearchView.swift        # Search interface with distance sorting
│   │   ├── SearchResultRow.swift   # Search result component with distance
│   │   ├── BusinessDetailView.swift # Detailed business view
│   │   ├── SettingsView.swift      # Settings and preferences
│   │   └── HomeLocationPickerView.swift # Home location picker with map
│   ├── Services/
│   │   ├── GooglePlacesService.swift      # Google Places API integration
│   │   ├── BusinessRefreshService.swift   # Data refresh logic
│   │   ├── NotificationManager.swift      # Local notification handling
│   │   ├── BackgroundRefreshManager.swift # Background task scheduling
│   │   └── LocationManager.swift          # Location services and home location
│   ├── EasitOpenApp.swift          # App entry point
│   └── Config.swift.template       # API key configuration template
├── README.md
└── .gitignore
```

## 🔒 Security

- API keys are stored in `Config.swift` which is excluded from version control
- Never commit your `Config.swift` file with real API keys
- The `.gitignore` file is configured to prevent accidental commits
- Always regenerate API keys if accidentally exposed

## 🧪 Testing

### Unit Tests
- Comprehensive test suite with 80+ tests across 5 test files
- Run tests with Cmd+U in Xcode
- Tests cover:
  - Business model and status logic (36 tests)
    - Custom label functionality
    - Opening hours calculations
    - Closing soon threshold (60 minutes)
    - Distance calculations and formatting
    - Distance-based sorting
  - Location services (15 tests)
    - Home location storage and persistence
    - Address geocoding and reverse geocoding
    - Authorization status handling
    - Edge cases and validation
  - Notification system and BusinessChange types (15 tests)
  - Refresh service time/day formatting (20 tests)
  - RefreshResult and error handling
  - Time formatting and edge cases
  - Data staleness detection

### On Simulator
- Simply run from Xcode (Cmd+R)
- All features work except actual phone calls

### On Physical Device
- Connect iPhone via cable
- Select device in Xcode
- Trust your Mac on iPhone when prompted
- Run from Xcode (free Apple ID works for 7 days)

### TestFlight (Optional)
- For longer-term testing and sharing with others
- Requires Apple Developer account enrollment

## 🎯 Completed Features

- [x] Real-time open/closed/closing soon status (60-minute threshold)
- [x] Custom business labels
- [x] Comprehensive filtering and sorting
- [x] Search with persistent results
- [x] Visual feedback for added businesses
- [x] Confirmation dialogs for deletions
- [x] Full test suite coverage
- [x] Pull-to-refresh on dashboard
- [x] Auto-refresh on app launch (24-hour threshold)
- [x] Manual refresh per business
- [x] Data staleness indicators
- [x] Change detection system
- [x] Color-coded toast notifications
- [x] Rate-limited API requests
- [x] Background refresh (when app is closed, every 24 hours)
- [x] Push notifications when hours change
- [x] Detailed change tracking (hours, closures, contact info)
- [x] Settings tab with notification and location controls
- [x] Location services integration
- [x] Distance-based sorting (current location & home)
- [x] Home location management with address search
- [x] Map preview for home location selection
- [x] Distance display on business cards and search results

## 📋 Documentation

- **README.md** - Main project documentation (this file)
- **LOCATION_FEATURES.md** - Complete guide to location services and distance features
- **BACKGROUND_REFRESH_SETUP.md** - Step-by-step guide for enabling background refresh
- **PHASE_4_6_IMPLEMENTATION.md** - Technical details of notification and background refresh features
- **DATA_MIGRATION_GUIDE.md** - Guide for handling SwiftData schema changes and migrations
- **CONTRIBUTING.md** - Guidelines for contributing code and reporting issues

## 🚧 Future Enhancements
- [ ] Data export/import feature
- [ ] Custom app icon
- [ ] Launch screen
- [ ] Favorites/priority businesses
- [ ] Edit business hours manually
- [ ] Dark mode optimizations
- [ ] Widget support
- [ ] iPad optimization
- [ ] Route planning to multiple businesses
- [ ] Nearby businesses discovery

## 📝 Learning Journey

This is my first iOS app, built to learn:
- SwiftUI fundamentals (views, state management, navigation)
- SwiftData for persistence
- API integration with URLSession (async/await)
- MapKit integration
- CoreLocation services (location tracking, geocoding, distance calculations)
- Background task scheduling with BGTaskScheduler
- Local notifications with UserNotifications
- MVVM architecture patterns
- Unit testing with XCTest (80+ tests)
- Git workflow and version control
- iOS app deployment and TestFlight
- User experience design (status indicators, confirmation dialogs, notifications, location permissions)

## 📋 Documentation

For developers who want to understand or contribute to the codebase:

- **README.md** (this file) - Project overview, features, setup instructions
- **BACKGROUND_REFRESH_SETUP.md** - Xcode configuration for BGTaskScheduler
- **PHASE_4_6_IMPLEMENTATION.md** - Technical implementation details
- **DATA_MIGRATION_GUIDE.md** - SwiftData migration patterns and best practices
- **CONTRIBUTING.md** - Guidelines for contributing code and reporting issues

## 🤝 Contributing

This is a personal learning project, but contributions are welcome!

Interested in contributing?
- Report bugs or suggest features via [Issues](https://github.com/NissimAmira/EasitOpen/issues)
- Fork the repo and submit Pull Requests
- Follow existing code style and add tests for new features
- See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines

## 📄 License

This project is open source and available for learning purposes.

## 👤 Author

Nissim Amira

## 📝 Release Notes

### Version 1.1.0 (Current)

**New Features:**
- ✅ Location services integration with CoreLocation
- ✅ Distance-based sorting (current location & home)
- ✅ Home location management with address search and map preview
- ✅ Distance display on business cards (km/meters)
- ✅ Simplified background refresh (fixed 24-hour interval)
- ✅ 80+ unit tests including location features
- ✅ Improved Settings UI with location management

**Previous Features (v1.0.0):**
- ✅ Complete business tracking system with real-time status
- ✅ Background refresh when app is closed
- ✅ Smart notifications for hours changes
- ✅ Settings tab with full customization
- ✅ Optimized UI layouts (vertical quick action buttons)
- ✅ Data migration protection for future updates

**Known Issues:**
- Background refresh requires manual Xcode configuration (see BACKGROUND_REFRESH_SETUP.md)
- Background tasks work best on physical devices, not simulators
- Location services require "When In Use" permission for distance features

**Documentation:**
- Complete setup guides
- Data migration best practices
- Background refresh testing instructions

---

**Note:** This app requires a Google Places API key to function. API usage may incur costs depending on your usage and Google Cloud pricing.
