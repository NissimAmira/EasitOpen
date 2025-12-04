import Foundation
import SwiftData
import UserNotifications

enum RefreshError: Error {
    case noPlaceId
    case apiError
    case noData
}

struct RefreshResult {
    let business: Business
    let success: Bool
    let hasChanges: Bool
    let changes: [BusinessChange]
    let error: Error?
}

class BusinessRefreshService {
    private let placesService = GooglePlacesService()
    private let notificationManager = NotificationManager.shared
    
    // Refresh a single business and send notifications if changes detected
    func refreshBusiness(_ business: Business) async throws -> [BusinessChange] {
        guard let placeId = business.googlePlaceId else {
            throw RefreshError.noPlaceId
        }
        
        // Update last checked timestamp
        business.lastChecked = Date()
        
        // Fetch updated data from Google Places
        let updatedPlace = try await placesService.getPlaceDetails(placeId: placeId)
        
        // Detect detailed changes
        let changes = detectDetailedChanges(business: business, newPlace: updatedPlace)
        
        if !changes.isEmpty {
            // Update business data
            updateBusiness(business, with: updatedPlace)
            business.lastUpdated = Date()
            
            // Send notifications for changes
            await notificationManager.sendChangeNotification(for: changes)
        }
        
        return changes
    }
    
    // Refresh all businesses with rate limiting
    func refreshAllBusinesses(_ businesses: [Business]) async -> [RefreshResult] {
        var results: [RefreshResult] = []
        
        for business in businesses {
            // Add delay to avoid rate limiting (1 second between requests)
            if !results.isEmpty {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            do {
                let changes = try await refreshBusiness(business)
                results.append(RefreshResult(
                    business: business,
                    success: true,
                    hasChanges: !changes.isEmpty,
                    changes: changes,
                    error: nil
                ))
            } catch {
                results.append(RefreshResult(
                    business: business,
                    success: false,
                    hasChanges: false,
                    changes: [],
                    error: error
                ))
            }
        }
        
        return results
    }
    
    // Detect detailed changes between old and new business data
    func detectDetailedChanges(business: Business, newPlace: PlaceResult) -> [BusinessChange] {
        var changes: [BusinessChange] = []
        let businessId = business.id.uuidString
        let businessName = business.customLabel ?? business.name
        
        let newSchedule = convertOpeningHours(newPlace.currentOpeningHours)
        
        // Compare opening hours for each day
        for newDay in newSchedule {
            if let existingDay = business.openingHours.first(where: { $0.weekday == newDay.weekday }) {
                // Day exists in both - check if hours changed
                if existingDay.isClosed != newDay.isClosed {
                    if newDay.isClosed {
                        changes.append(BusinessChange(
                            type: .dayClosed(day: dayName(for: newDay.weekday)),
                            businessName: businessName,
                            businessId: businessId
                        ))
                    } else {
                        let hours = "\(formatTime(newDay.openTime)) - \(formatTime(newDay.closeTime))"
                        changes.append(BusinessChange(
                            type: .dayOpened(day: dayName(for: newDay.weekday), hours: hours),
                            businessName: businessName,
                            businessId: businessId
                        ))
                    }
                } else if existingDay.openTime != newDay.openTime || existingDay.closeTime != newDay.closeTime {
                    let oldHours = "\(formatTime(existingDay.openTime)) - \(formatTime(existingDay.closeTime))"
                    let newHours = "\(formatTime(newDay.openTime)) - \(formatTime(newDay.closeTime))"
                    changes.append(BusinessChange(
                        type: .hoursChanged(day: dayName(for: newDay.weekday), oldHours: oldHours, newHours: newHours),
                        businessName: businessName,
                        businessId: businessId
                    ))
                }
            } else {
                // New day added
                let hours = "\(formatTime(newDay.openTime)) - \(formatTime(newDay.closeTime))"
                changes.append(BusinessChange(
                    type: .dayOpened(day: dayName(for: newDay.weekday), hours: hours),
                    businessName: businessName,
                    businessId: businessId
                ))
            }
        }
        
        // Check for days that were removed
        for existingDay in business.openingHours {
            if !newSchedule.contains(where: { $0.weekday == existingDay.weekday }) {
                changes.append(BusinessChange(
                    type: .dayClosed(day: dayName(for: existingDay.weekday)),
                    businessName: businessName,
                    businessId: businessId
                ))
            }
        }
        
        // Check phone number changes
        if business.phoneNumber != newPlace.internationalPhoneNumber {
            changes.append(BusinessChange(
                type: .phoneChanged(old: business.phoneNumber, new: newPlace.internationalPhoneNumber),
                businessName: businessName,
                businessId: businessId
            ))
        }
        
        // Check website changes
        if business.website != newPlace.websiteUri {
            changes.append(BusinessChange(
                type: .websiteChanged(old: business.website, new: newPlace.websiteUri),
                businessName: businessName,
                businessId: businessId
            ))
        }
        
        return changes
    }
    
    // Update business with new data
    private func updateBusiness(_ business: Business, with place: PlaceResult) {
        let newSchedule = convertOpeningHours(place.currentOpeningHours)
        business.openingHours = newSchedule
        
        // Update other details if they changed
        if business.phoneNumber != place.internationalPhoneNumber {
            business.phoneNumber = place.internationalPhoneNumber
        }
        if business.website != place.websiteUri {
            business.website = place.websiteUri
        }
    }
    
    // Convert Google Places opening hours to our format
    private func convertOpeningHours(_ hours: OpeningHours?) -> [DaySchedule] {
        guard let periods = hours?.periods else { return [] }
        
        var schedules: [DaySchedule] = []
        
        for period in periods {
            guard let openDay = period.open?.day,
                  let openHour = period.open?.hour,
                  let openMinute = period.open?.minute,
                  let closeHour = period.close?.hour,
                  let closeMinute = period.close?.minute else {
                continue
            }
            
            let openTime = openHour * 60 + openMinute
            let closeTime = closeHour * 60 + closeMinute
            
            // Convert Google's day format (0 = Sunday) to Calendar format (1 = Sunday)
            let weekday = openDay == 0 ? 1 : openDay + 1
            
            let schedule = DaySchedule(
                weekday: weekday,
                openTime: openTime,
                closeTime: closeTime
            )
            schedules.append(schedule)
        }
        
        return schedules
    }
    
    // Helper: Format time in minutes to readable string (e.g., "9:30 AM")
    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
    
    // Helper: Convert weekday number to day name
    private func dayName(for weekday: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard weekday >= 1 && weekday <= 7 else { return "Unknown" }
        return days[weekday]
    }
}
