import Foundation
import SwiftData

@Model
class Business {
    var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var website: String?
    var openingHours: [DaySchedule]
    var dateAdded: Date
    
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
    
    // Computed property to check if business is currently open
    var isOpen: Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute
        
        // Find today's schedule
        guard let todaySchedule = openingHours.first(where: { $0.weekday == weekday }) else {
            return false
        }
        
        return todaySchedule.isOpen(at: currentMinutes)
    }
}
