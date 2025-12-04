# EasitOpen 🕐

An iOS app to help you quickly check opening hours and current status of your favorite businesses. Never wonder if your local coffee shop is open again!

## 📱 Features

### Dashboard
- **Real-time Status**: See which businesses are currently open, closing soon, or closed at a glance
- **Closing Soon Alert**: Orange badge appears when business closes within 60 minutes
- **Custom Labels**: Personalize business names (e.g., "My Favorite Cafe")
- **Today's Hours**: View opening hours for today on each business card
- **Smart Filtering**: Filter by Open, Closing Soon, or Closed status
- **Intelligent Sorting**: Sort businesses by name or status (Open → Closing Soon → Closed)
- **Search**: Quickly find a specific business in your saved list
- **Easy Management**: Swipe to delete with confirmation prompt

### Search & Add
- **Google Places Integration**: Search for any business using Google Places API
- **Comprehensive Results**: See business name, address, and current status
- **One-Tap Add**: Add businesses to your dashboard with a single tap
- **Visual Feedback**: Added businesses show a green checkmark
- **Persistent Results**: Search results remain visible after adding a business
- **Automatic Hours Import**: Opening hours are automatically fetched and saved

### Business Details
- **Custom Labels**: Edit business names with a personal touch
- **Interactive Map**: See business location with MapKit integration
- **Full Weekly Schedule**: View complete opening hours for every day
- **Quick Actions**: 
  - Call the business directly
  - Open website in Safari
  - Get directions in Apple Maps
- **Today Highlight**: Current day is highlighted in the schedule
- **Safe Deletion**: Confirmation dialog before removing businesses

## 🛠 Technical Stack

- **Language**: Swift 6.2
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Maps**: MapKit
- **API Integration**: Google Places API (New)
- **Testing**: XCTest with comprehensive unit tests
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

5. **Build and Run:**
   - Select your target device or simulator
   - Press Cmd+R or click the Play button
   - For physical devices: You may need to trust your developer account in Settings

## 📂 Project Structure

```
EasitOpen/
├── EasitOpen/
│   ├── Models/
│   │   ├── Business.swift          # Business data model
│   │   └── DaySchedule.swift       # Opening hours model
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── DashboardView.swift     # Business dashboard
│   │   ├── BusinessCardView.swift  # Business card component
│   │   ├── SearchView.swift        # Search interface
│   │   ├── SearchResultRow.swift   # Search result component
│   │   └── BusinessDetailView.swift # Detailed business view
│   ├── Services/
│   │   └── GooglePlacesService.swift # Google Places API integration
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
- Comprehensive test suite with 20+ tests
- Run tests with Cmd+U in Xcode
- Tests cover:
  - Business model and status logic
  - Custom label functionality
  - Opening hours calculations
  - Closing soon threshold (60 minutes)
  - Time formatting and edge cases

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

- [x] Real-time open/closed/closing soon status
- [x] Custom business labels
- [x] Comprehensive filtering and sorting
- [x] Search with persistent results
- [x] Visual feedback for added businesses
- [x] Confirmation dialogs for deletions
- [x] Full test suite coverage

## 🚧 Future Enhancements

- [ ] Custom app icon
- [ ] Launch screen
- [ ] Favorites/priority businesses
- [ ] Push notifications for closing time
- [ ] Edit business hours manually
- [ ] Location-based sorting by distance
- [ ] Dark mode optimizations
- [ ] Widget support
- [ ] iPad optimization

## 📝 Learning Journey

This is my first iOS app, built to learn:
- SwiftUI fundamentals (views, state management, navigation)
- SwiftData for persistence
- API integration with URLSession (async/await)
- MapKit integration
- MVVM architecture patterns
- Unit testing with XCTest
- Git workflow and version control
- iOS app deployment and TestFlight
- User experience design (status indicators, confirmation dialogs)

## 🤝 Contributing

This is a personal learning project, but feedback and suggestions are welcome!

## 📄 License

This project is open source and available for learning purposes.

## 👤 Author

Nissim Amira

---

**Note:** This app requires a Google Places API key to function. API usage may incur costs depending on your usage and Google Cloud pricing.
