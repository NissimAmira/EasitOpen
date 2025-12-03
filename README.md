# EasitOpen

An iOS app to track opening hours of your favorite businesses using Google Maps API.

## Setup

1. **Get a Google Places API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project
   - Enable "Places API (New)"
   - Create credentials (API Key)

2. **Configure the API Key:**
   - Copy `EasitOpen/Config.swift.template` to `EasitOpen/Config.swift`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
   - **Important:** Do NOT commit `Config.swift` (it's in .gitignore)

3. **Build and Run:**
   - Open `EasitOpen.xcodeproj` in Xcode
   - Build and run (Cmd+R)

## Features

- Dashboard showing saved businesses with open/closed status
- Search for businesses using Google Places API
- Add businesses to your personalized dashboard
- Swipe to delete businesses

## Security Note

Never commit your `Config.swift` file with your API key. It's included in `.gitignore` to prevent accidental commits.
