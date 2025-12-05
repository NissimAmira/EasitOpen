# Location Services Implementation Guide

## Overview

Version 1.1.0 introduces comprehensive location services to EasitOpen, enabling users to sort and view businesses based on distance from their current location or a saved home location.

## Features

### 1. Distance-Based Sorting

**Dashboard View:**
- Sort by Name (alphabetically)
- Sort by Status (Open → Closing Soon → Closed)
- **Sort by Distance (Current)** - Businesses sorted by distance from your current location
- **Sort by Distance (Home)** - Businesses sorted by distance from your saved home location

**Search View:**
- Sort by Relevance (Google's default)
- **Sort by Near Me** - Search results sorted by distance from current location
- **Sort by Near Home** - Search results sorted by distance from saved home location

### 2. Distance Display

- Distances shown in **kilometers** (≥1 km) or **meters** (<1 km)
- Format: "1.5 km" or "250 m"
- Displayed in blue text on business cards and search results
- Only shown when sorting by distance

### 3. Home Location Management

Users can set a home location through Settings in two ways:

**Option 1: Use Current Location**
- Tap "Use Current Location" button
- Automatically reverse geocodes to show readable address
- Saves location and address instantly

**Option 2: Enter Address**
1. Type any address in the search field
2. Press return/search to geocode the address
3. See location on interactive map preview
4. View formatted address below map
5. Tap "Set" to confirm and save

**Home Location Display:**
- Shows human-readable address (e.g., "123 Main St, San Francisco, CA, USA")
- NOT just coordinates
- Can be changed or cleared anytime

### 4. Permission Handling

The app gracefully handles all location permission states:

**Not Determined:**
- Prompts user to enable location services
- Shows alert explaining why location is needed

**Denied/Restricted:**
- Alert with "Open Settings" button
- Direct link to iOS Settings app

**Authorized:**
- Automatic location updates
- Distance features fully functional

**No Home Location Set:**
- Alert directing user to Settings tab
- Cannot sort by home distance until set

## Technical Implementation

### Core Components

**LocationManager.swift**
- Singleton service managing CoreLocation
- Handles location updates and permissions
- Stores home location in UserDefaults
- Reverse geocodes addresses for display
- Published properties for reactive UI updates

**Business Model Extensions**
```swift
// Computed property for CLLocation
var location: CLLocation

// Calculate distance to another location
func distance(from location: CLLocation) -> CLLocationDistance

// Format distance as human-readable text
func distanceText(from location: CLLocation) -> String
```

**HomeLocationPickerView.swift**
- SwiftUI view with address search
- Interactive MapKit preview
- Real-time geocoding feedback
- "Use Current Location" quick action

### Data Flow

1. **User enables location** → LocationManager requests permission
2. **Permission granted** → LocationManager starts updating location
3. **User selects distance sort** → View checks for required location
4. **Location available** → Businesses sorted by distance
5. **Distance displayed** → Formatted text shown on cards

### Storage

**UserDefaults Keys:**
- `homeLatitude` - Double
- `homeLongitude` - Double
- `homeAddress` - String

**Published Properties:**
- `@Published var currentLocation: CLLocation?`
- `@Published var homeLocation: CLLocation?`
- `@Published var homeAddress: String?`
- `@Published var authorizationStatus: CLAuthorizationStatus`

## Info.plist Requirements

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>EasitOpen uses your location to show distances to businesses and sort by proximity.</string>
```

## Testing

### Unit Tests (LocationManagerTests.swift)

**Home Location Storage (7 tests):**
- Set by coordinates
- Set with address
- Clear home location
- Persistence verification
- Set current as home
- Edge cases (zero coords, extreme coords)
- Multiple updates

**Business Distance Tests (9 tests):**
- Location property
- Distance calculation accuracy
- Distance text formatting (km vs m)
- Zero distance handling
- Long distance calculations
- Distance-based sorting

### Manual Testing Checklist

**Dashboard:**
- [ ] Sort by Distance (Current) shows correct order
- [ ] Sort by Distance (Home) shows correct order
- [ ] Distance displayed in appropriate units (km/m)
- [ ] Alert shown when location unavailable
- [ ] Sorting works after setting home location

**Search:**
- [ ] "Near Me" sorts results by distance
- [ ] "Near Home" sorts results by distance
- [ ] "Relevance" shows original order
- [ ] Segmented picker hides unavailable options

**Settings:**
- [ ] Location status shown correctly
- [ ] "Enable Location Services" button works
- [ ] "Use Current Location" sets home
- [ ] Address search geocodes correctly
- [ ] Map preview shows correct location
- [ ] Address displayed (not coordinates)
- [ ] "Clear Home Location" works

**Permissions:**
- [ ] Alert shown for denied location
- [ ] "Open Settings" opens iOS Settings
- [ ] Alert shown for no home location
- [ ] Permission prompt appears first time

## User Experience Considerations

### Design Decisions

1. **Optional Feature**: Location services are completely optional
   - App works fully without location permission
   - Distance sorting simply unavailable when permission denied

2. **Clear Communication**: Users always know why location is needed
   - Alert messages explain the feature requiring location
   - Settings shows current permission status

3. **Graceful Degradation**: Missing data handled elegantly
   - Sort options disabled when location unavailable
   - Helpful error messages guide users

4. **Privacy First**: Minimal location data collection
   - Only "When In Use" permission (not "Always")
   - Location only used for distance calculations
   - Home address stored locally (UserDefaults)

5. **User Control**: Full control over location features
   - Easy to set/change/clear home location
   - Can revoke permissions anytime in iOS Settings

### UI/UX Highlights

- **Segmented Picker**: Clear visual indication of sort mode
- **Blue Distance Text**: Subtle color differentiates distance from other info
- **Map Preview**: Visual confirmation before setting home
- **Formatted Addresses**: Human-readable, not raw coordinates
- **Loading States**: "Loading address..." shown during geocoding

## Migration Notes

### Version 1.0.0 → 1.1.0

**New UserDefaults Keys:**
- `homeLatitude`
- `homeLongitude`
- `homeAddress`

**Business Model Changes:**
- Added `import CoreLocation`
- Added computed `location` property
- Added `distance(from:)` method
- Added `distanceText(from:)` method

**Breaking Changes:**
- None - location features are additive
- Existing installations work without changes
- Users can opt-in to location features

## Troubleshooting

### Location Not Updating

**Symptoms:** Current location is nil, distance sorting unavailable

**Solutions:**
1. Check location permission in iOS Settings
2. Ensure location services enabled system-wide
3. Try requesting permission again from app
4. Restart app after granting permission

### Geocoding Fails

**Symptoms:** "Could not find address" error when searching

**Solutions:**
1. Check internet connection (geocoding requires network)
2. Try more specific address (include city, state)
3. Use standard address format
4. Try "Use Current Location" instead

### Distance Seems Wrong

**Symptoms:** Distance values don't match expectations

**Solutions:**
1. Verify home location is set correctly
2. Check if sorting by correct reference (current vs home)
3. Distance is "as the crow flies" (straight line, not driving)
4. Remember: meters for <1km, kilometers for ≥1km

### Permission Denied

**Symptoms:** Can't enable location services

**Solutions:**
1. Go to iOS Settings → EasitOpen → Location
2. Select "While Using the App"
3. Restart app if needed
4. Check system-wide location services enabled

## Future Enhancements

Potential additions for future versions:

- [ ] **Route Planning**: Get directions to multiple businesses
- [ ] **Nearby Discovery**: Find new businesses near current location
- [ ] **Location History**: Track frequently visited locations
- [ ] **Geofencing**: Notifications when near favorite businesses
- [ ] **Distance Filter**: Only show businesses within X km
- [ ] **Always Allow**: Background location for advanced features
- [ ] **Custom Locations**: Save multiple reference locations beyond just "home"
- [ ] **Address Autocomplete**: MKLocalSearchCompleter for better address entry

## API Reference

### LocationManager

```swift
class LocationManager: NSObject, ObservableObject {
    static let shared: LocationManager
    
    // Published properties
    @Published var currentLocation: CLLocation?
    @Published var homeLocation: CLLocation?
    @Published var homeAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationError: Error?
    
    // Methods
    func requestPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func requestLocation()
    func setCurrentLocationAsHome()
    func setHomeLocation(latitude: Double, longitude: Double, address: String?)
    func clearHomeLocation()
}
```

### Business Extensions

```swift
extension Business {
    var location: CLLocation { get }
    func distance(from location: CLLocation) -> CLLocationDistance
    func distanceText(from location: CLLocation) -> String
}
```

## Resources

- [Apple CoreLocation Documentation](https://developer.apple.com/documentation/corelocation)
- [CLLocationManager Guide](https://developer.apple.com/documentation/corelocation/cllocationmanager)
- [Location Permissions Best Practices](https://developer.apple.com/documentation/corelocation/requesting_authorization_to_use_location_services)
- [MapKit Documentation](https://developer.apple.com/documentation/mapkit)

---

**Version 1.1.0** - Location Services Implementation  
**Last Updated:** December 5, 2025
