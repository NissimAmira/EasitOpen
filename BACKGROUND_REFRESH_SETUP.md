# Background Refresh Setup Guide

## Required Xcode Configuration

To enable background refresh, you must configure your Xcode project manually. Follow these steps:

### Step 1: Add Background Modes Capability

1. Open `EasitOpen.xcodeproj` in Xcode
2. Select the **EasitOpen** target in the project navigator
3. Click on the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **Background Modes**
6. In the Background Modes section, check the box for **Background fetch**

### Step 2: Register Background Task Identifier

1. Stay in the **EasitOpen** target
2. Switch to the **Info** tab
3. Find or add the key: `BGTaskSchedulerPermittedIdentifiers`
   - Type: Array
4. Add an item to the array with the value: `com.easitopen.refresh`

#### Visual Guide:
```
Info.plist structure:
├── BGTaskSchedulerPermittedIdentifiers (Array)
│   └── Item 0 (String): com.easitopen.refresh
```

Alternatively, if you're editing the raw Info.plist XML:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.easitopen.refresh</string>
</array>
```

### Step 3: Build and Run

After making these changes:
1. Clean build folder: **Product > Clean Build Folder** (Shift+Cmd+K)
2. Build and run the app
3. Check the console for: `✅ Background task registered: com.easitopen.refresh`

## Testing Background Refresh

Background tasks don't run in the simulator or when debugging normally. To test:

### Method 1: Using Xcode Debugger

1. Run the app on a real device (background tasks don't work reliably in simulator)
2. Set a breakpoint in `BackgroundRefreshManager.handleBackgroundRefresh()`
3. While debugging, use the Xcode console to manually trigger:
   ```
   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.easitopen.refresh"]
   ```

### Method 2: Using Terminal Command (Device)

1. Run the app
2. Background the app (go to home screen)
3. Open Terminal and run:
   ```bash
   xcrun simctl spawn booted log stream --predicate 'subsystem == "com.easitopen"'
   ```
4. Then trigger the background task:
   ```bash
   xcrun simctl spawn booted notify_post com.easitopen.refresh
   ```

### Method 3: Wait for Natural Scheduling

iOS will run the background task when conditions are optimal:
- Device is charging or has sufficient battery
- Good network connection available
- Device is not being actively used
- At least 8 hours have passed since last refresh

Background tasks are **not guaranteed** to run - iOS decides when based on system conditions.

## How It Works

1. **Registration**: App registers the background task on launch (`EasitOpenApp.init()`)
2. **Scheduling**: After the first app launch check, we schedule the next refresh (`ContentView`)
3. **Execution**: iOS wakes up the app in the background to run the refresh
4. **Notifications**: If any business hours change, users receive notifications
5. **Re-scheduling**: After each refresh, we schedule the next one

## Debugging Tips

Check the console logs:
- ✅ `Background task registered: com.easitopen.refresh` - Registration successful
- ✅ `Background refresh scheduled for [DATE]` - Task scheduled
- 🔄 `Background refresh task started` - Task is running
- ✅ `Background refresh complete: X/Y updated, Z had changes` - Task finished

Common issues:
- ❌ Registration fails → Check Info.plist identifier matches code
- ❌ Scheduling fails → Check Background Modes capability is enabled
- ❌ Task never runs → Normal! iOS schedules based on system conditions

## Configuration Values

You can adjust these in `BackgroundRefreshManager.swift`:

```swift
// Minimum time between refreshes (currently 8 hours)
request.earliestBeginDate = Date(timeIntervalSinceNow: 8 * 60 * 60)
```

Consider:
- Shorter intervals = More up-to-date data, but more battery/API usage
- Longer intervals = Less battery/API usage, but data might be stale
- 8-24 hours is a good balance for most apps

## API Rate Limits

Google Places API has these limits:
- **Free tier**: 100 requests/day for Place Details
- **Rate limiting**: Built-in 1-second delay between requests

If you have 10 businesses:
- 1 manual refresh = 10 API calls
- 1 background refresh/day = 10 API calls
- 1 app launch refresh/day = 10 API calls (if data is stale)
- **Total**: ~30 calls/day (well within free tier)

## Security & Privacy

- Background refresh only updates existing businesses
- No new data is collected without user knowledge
- Notifications require user permission
- All refresh operations are logged for debugging

## Future Enhancements

Possible improvements:
- User-configurable refresh frequency
- Battery-aware refresh (only when charging)
- Network-aware refresh (WiFi only)
- Refresh only "favorite" businesses
- Smart refresh based on business patterns (refresh coffee shops in morning, restaurants at lunch)
