import Foundation
import SwiftData
import SwiftUI

enum BusinessStatus {
    case open
    case closingSoon
    case closed
    
    var text: String {
        switch self {
        case .open: return "OPEN"
        case .closingSoon: return "CLOSING SOON"
        case .closed: return "CLOSED"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .green
        case .closingSoon: return .orange
        case .closed: return .red
        }
    }
}

@Model
class Business: Identifiable {
    var id: UUID
    var googlePlaceId: String? // For fetching updates from Google
    var name: String
    var customLabel: String? // Custom name set by user
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var website: String?
    var openingHours: [DaySchedule]
    var dateAdded: Date
    var lastUpdated: Date // When data was last refreshed
    var lastChecked: Date? // Last time we tried to check for updates
    
    // Display name (custom label if set, otherwise business name)
    var displayName: String {
        customLabel ?? name
    }
    
    init(
        id: UUID = UUID(),
        googlePlaceId: String? = nil,
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        phoneNumber: String? = nil,
        website: String? = nil,
        openingHours: [DaySchedule] = []
    ) {
        self.id = id
        self.googlePlaceId = googlePlaceId
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.website = website
        self.openingHours = openingHours
        self.dateAdded = Date()
        self.lastUpdated = Date()
        self.lastChecked = nil
    }
    
    // Computed property to get current business status
    var status: BusinessStatus {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        // Find today's schedule
        guard let todaySchedule = openingHours.first(where: { $0.weekday == weekday }) else {
            return .closed
        }
        
        // Check if closed
        if !todaySchedule.isOpen(at: currentMinutes) {
            return .closed
        }
        
        // Check if closing soon (within 60 minutes)
        let minutesUntilClose = todaySchedule.closeTime - currentMinutes
        if minutesUntilClose <= 60 && minutesUntilClose > 0 {
            return .closingSoon
        }
        
        return .open
    }
    
    // Computed property to check if business is currently open (for backward compatibility)
    var isOpen: Bool {
        status == .open || status == .closingSoon
    }
    
    // Helper to check if data is stale (>7 days old)
    var isDataStale: Bool {
        let daysSinceUpdate = Calendar.current.dateComponents([.day], from: lastUpdated, to: Date()).day ?? 0
        return daysSinceUpdate > 7
    }
    
    // Human-readable last updated text
    var lastUpdatedText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}
