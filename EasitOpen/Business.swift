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
    var name: String
    var customLabel: String? // Custom name set by user
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var website: String?
    var openingHours: [DaySchedule]
    var dateAdded: Date
    
    // Display name (custom label if set, otherwise business name)
    var displayName: String {
        customLabel ?? name
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        phoneNumber: String? = nil,
        website: String? = nil,
        openingHours: [DaySchedule] = []
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.website = website
        self.openingHours = openingHours
        self.dateAdded = Date()
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
        
        // Check if closing soon (within 30 minutes)
        let minutesUntilClose = todaySchedule.closeTime - currentMinutes
        if minutesUntilClose <= 30 && minutesUntilClose > 0 {
            return .closingSoon
        }
        
        return .open
    }
    
    // Computed property to check if business is currently open (for backward compatibility)
    var isOpen: Bool {
        status == .open || status == .closingSoon
    }
}
