import Foundation
import SwiftData

@Model
class DaySchedule {
    var weekday: Int // 1 = Sunday, 2 = Monday, etc.
    var openTime: Int // Minutes since midnight (e.g., 540 = 9:00 AM)
    var closeTime: Int // Minutes since midnight (e.g., 1020 = 5:00 PM)
    var isClosed: Bool
    
    init(weekday: Int, openTime: Int, closeTime: Int, isClosed: Bool = false) {
        self.weekday = weekday
        self.openTime = openTime
        self.closeTime = closeTime
        self.isClosed = isClosed
    }
    
    // Check if open at specific time (in minutes since midnight)
    func isOpen(at minutes: Int) -> Bool {
        if isClosed {
            return false
        }
        return minutes >= openTime && minutes < closeTime
    }
    
    // Helper to convert minutes to readable time (e.g., "9:00 AM")
    var openTimeFormatted: String {
        return formatMinutes(openTime)
    }
    
    var closeTimeFormatted: String {
        return formatMinutes(closeTime)
    }
    
    private func formatMinutes(_ totalMinutes: Int) -> String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let period = hours >= 12 ? "PM" : "AM"
        let displayHour = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, period)
    }
}
