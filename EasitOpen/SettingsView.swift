import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("backgroundRefreshEnabled") private var backgroundRefreshEnabled = true
    @AppStorage("refreshIntervalHours") private var refreshIntervalHours = 8.0
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTestNotification = false
    @State private var testNotificationMessage: String?
    
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
                    
                    if notificationManager.authorizationStatus == .denied {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are disabled")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("Open Settings") {
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
                    
                    Button("Send Test Notification") {
                        sendTestNotification()
                    }
                    .disabled(notificationManager.authorizationStatus != .authorized)
                    
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get notified when business hours change. Test notifications show what real change alerts look like.")
                }
                
                // Background Refresh Section
                Section {
                    Toggle("Background Refresh", isOn: $backgroundRefreshEnabled)
                        .onChange(of: backgroundRefreshEnabled) { oldValue, newValue in
                            handleBackgroundRefreshToggle(enabled: newValue)
                        }
                    
                    if backgroundRefreshEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Refresh Interval")
                                .font(.subheadline)
                            
                            HStack {
                                Text("\(Int(refreshIntervalHours))h")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $refreshIntervalHours, in: 1...24, step: 1)
                                    .onChange(of: refreshIntervalHours) { oldValue, newValue in
                                        rescheduleBackgroundRefresh()
                                    }
                                
                                Text("24h")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Current: Every \(Int(refreshIntervalHours)) hour\(Int(refreshIntervalHours) == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                } header: {
                    Text("Background Refresh")
                } footer: {
                    if backgroundRefreshEnabled {
                        Text("App will automatically refresh business hours in the background every \(Int(refreshIntervalHours)) hours. iOS schedules background tasks based on device conditions (charging, WiFi, etc.).")
                    } else {
                        Text("Background refresh is disabled. Business hours will only update when you open the app or manually refresh.")
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
        .overlay(alignment: .top) {
            if let message = testNotificationMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.15))
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
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
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendTestNotification() {
        Task {
            // Create a test change notification
            let testChange = BusinessChange(
                type: .hoursChanged(
                    day: "Monday",
                    oldHours: "8:00 AM - 5:00 PM",
                    newHours: "9:00 AM - 6:00 PM"
                ),
                businessName: "Test Coffee Shop",
                businessId: "test-id"
            )
            
            await notificationManager.sendChangeNotification(for: [testChange])
            
            // Show confirmation
            withAnimation {
                testNotificationMessage = "Test notification sent!"
            }
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            withAnimation {
                testNotificationMessage = nil
            }
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
