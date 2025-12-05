import SwiftUI
import UserNotifications
import CoreLocation
import MapKit

struct SettingsView: View {
    @AppStorage("backgroundRefreshEnabled") private var backgroundRefreshEnabled = true
    private let refreshIntervalHours = 24.0
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showHomeLocationSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Settings Section
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                        Text("Notification Status")
                        Spacer()
                        Text(notificationStatusText)
                            .foregroundColor(notificationStatusColor)
                            .font(.subheadline)
                    }
                    
                    if notificationManager.authorizationStatus == .authorized {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are enabled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Change in iOS Settings") {
                                openAppSettings()
                            }
                            .font(.subheadline)
                        }
                    } else if notificationManager.authorizationStatus == .denied {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are disabled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Open iOS Settings") {
                                openAppSettings()
                            }
                            .font(.subheadline)
                        }
                    } else if notificationManager.authorizationStatus == .notDetermined {
                        Button("Enable Notifications") {
                            Task {
                                await notificationManager.requestPermission()
                            }
                        }
                    }
                    
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationManager.authorizationStatus == .authorized {
                        Text("Notifications are enabled. To disable, change settings in iOS Settings app.")
                    } else {
                        Text("Get notified when business hours change.")
                    }
                }
                
                // Background Refresh Section
                Section {
                    Toggle("Background Refresh", isOn: $backgroundRefreshEnabled)
                        .onChange(of: backgroundRefreshEnabled) { oldValue, newValue in
                            handleBackgroundRefreshToggle(enabled: newValue)
                        }
                    
                } header: {
                    Text("Background Refresh")
                } footer: {
                    if backgroundRefreshEnabled {
                        Text("App will automatically refresh business hours in the background every 24 hours. iOS schedules background tasks based on device conditions (charging, WiFi, etc.).")
                    } else {
                        Text("Background refresh is disabled. Business hours will only update when you open the app or manually refresh.")
                    }
                }
                
                // Location Section
                Section {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Location Services")
                        Spacer()
                        Text(locationStatusText)
                            .foregroundColor(locationStatusColor)
                            .font(.subheadline)
                    }
                    
                    if locationManager.authorizationStatus == .denied {
                        Button("Open iOS Settings") {
                            openAppSettings()
                        }
                    } else if locationManager.authorizationStatus == .notDetermined {
                        Button("Enable Location Services") {
                            locationManager.requestPermission()
                        }
                    }
                    
                    // Home Location
                    if locationManager.homeLocation != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Home Location")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let address = locationManager.homeAddress {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Loading address...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Change Home Location") {
                                showHomeLocationSheet = true
                            }
                            .font(.subheadline)
                            
                            Button("Clear Home Location") {
                                locationManager.clearHomeLocation()
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                    } else {
                        Button("Set Home Location") {
                            showHomeLocationSheet = true
                        }
                    }
                    
                } header: {
                    Text("Location")
                } footer: {
                    if locationManager.homeLocation != nil {
                        Text("Home location is used to sort businesses by distance from home.")
                    } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                        Text("Location services are disabled. Enable them to use distance-based sorting and set a home location.")
                    } else if locationManager.currentLocation == nil {
                        Text("Waiting for your location. Once available, you can set it as your home location for distance-based sorting.")
                    } else {
                        Text("Enable location services to sort businesses by distance. Set a home location for sorting by distance from home.")
                    }
                }
                
                // About Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("API Provider")
                        Spacer()
                        Text("Google Places")
                            .foregroundColor(.secondary)
                    }
                    
                } header: {
                    Text("About")
                }
            }
        .navigationTitle("Settings")
        }
        .sheet(isPresented: $showHomeLocationSheet) {
            HomeLocationPickerView(
                locationManager: locationManager,
                isPresented: $showHomeLocationSheet
            )
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
    
    private var notificationStatusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var notificationStatusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        default:
            return .secondary
        }
    }
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied, .restricted:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func handleBackgroundRefreshToggle(enabled: Bool) {
        if enabled {
            rescheduleBackgroundRefresh()
        } else {
            // Cancel all scheduled background tasks
            BackgroundRefreshManager.shared.cancelBackgroundRefresh()
            print("ℹ️ Background refresh disabled by user")
        }
    }
    
    private func rescheduleBackgroundRefresh() {
        guard backgroundRefreshEnabled else { return }
        BackgroundRefreshManager.shared.scheduleBackgroundRefresh(intervalHours: refreshIntervalHours)
        print("🔄 Background refresh rescheduled: every \(Int(refreshIntervalHours)) hours")
    }
}

#Preview {
    SettingsView()
}
