import Foundation
import SwiftData

enum RefreshError: Error {
    case noPlaceId
    case apiError
    case noData
}

struct RefreshResult {
    let business: Business
    let success: Bool
    let hasChanges: Bool
    let error: Error?
}

class BusinessRefreshService {
    private let placesService = GooglePlacesService()
    
    // Refresh a single business
    func refreshBusiness(_ business: Business) async throws -> Bool {
        guard let placeId = business.googlePlaceId else {
            throw RefreshError.noPlaceId
        }
        
        // Update last checked timestamp
        business.lastChecked = Date()
        
        // Fetch updated data from Google Places
        let updatedPlace = try await placesService.getPlaceDetails(placeId: placeId)
        
        // Check if hours have changed
        let hasChanges = detectChanges(business: business, newPlace: updatedPlace)
        
        if hasChanges {
            // Update business data
            updateBusiness(business, with: updatedPlace)
            business.lastUpdated = Date()
            return true
        }
        
        return false
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
                let hasChanges = try await refreshBusiness(business)
                results.append(RefreshResult(
                    business: business,
                    success: true,
                    hasChanges: hasChanges,
                    error: nil
                ))
            } catch {
                results.append(RefreshResult(
                    business: business,
                    success: false,
                    hasChanges: false,
                    error: error
                ))
            }
        }
        
        return results
    }
    
    // Detect if opening hours have changed
    private func detectChanges(business: Business, newPlace: PlaceResult) -> Bool {
        let newSchedule = convertOpeningHours(newPlace.currentOpeningHours)
        
        // Simple comparison: check if schedule count changed
        if business.openingHours.count != newSchedule.count {
            return true
        }
        
        // Compare each day's hours
        for newDay in newSchedule {
            if let existingDay = business.openingHours.first(where: { $0.weekday == newDay.weekday }) {
                if existingDay.openTime != newDay.openTime ||
                   existingDay.closeTime != newDay.closeTime ||
                   existingDay.isClosed != newDay.isClosed {
                    return true
                }
            } else {
                return true // New day added
            }
        }
        
        return false
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
}
