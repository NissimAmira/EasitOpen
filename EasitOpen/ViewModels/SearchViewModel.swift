//
//  SearchViewModel.swift
//  EasitOpen
//
//  Created by nissim amira on 05/12/2025.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [PlaceResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var addedBusinessIds: Set<String> = []
    @Published var distanceSortOption: DistanceSortOption = .relevance
    
    enum DistanceSortOption: String, CaseIterable {
        case relevance = "Relevance"
        case current = "Near Me"
        case home = "Near Home"
    }
    
    private let placesService: GooglePlacesService
    private let locationManager: LocationManager
    
    init(
        placesService: GooglePlacesService = GooglePlacesService(),
        locationManager: LocationManager = .shared
    ) {
        self.placesService = placesService
        self.locationManager = locationManager
    }
    
    func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await placesService.searchPlaces(query: searchText)
            isSearching = false
        } catch {
            isSearching = false
            errorMessage = "Failed to search. Please try again."
            print("Search error: \(error)")
        }
    }
    
    func sortedResults() -> [PlaceResult] {
        guard let refLocation = referenceLocation() else { return searchResults }
        
        return searchResults.sorted { place1, place2 in
            let loc1 = CLLocation(latitude: place1.location?.latitude ?? 0, longitude: place1.location?.longitude ?? 0)
            let loc2 = CLLocation(latitude: place2.location?.latitude ?? 0, longitude: place2.location?.longitude ?? 0)
            return loc1.distance(from: refLocation) < loc2.distance(from: refLocation)
        }
    }
    
    func referenceLocation() -> CLLocation? {
        switch distanceSortOption {
        case .relevance: return nil
        case .current: return locationManager.currentLocation
        case .home: return locationManager.homeLocation
        }
    }
    
    func addBusiness(_ place: PlaceResult, to context: ModelContext) {
        print("Adding business: \(place.name)")
        print("Place ID: \(place.id)")
        
        let schedule = convertOpeningHours(place.currentOpeningHours)
        print("Converted \(schedule.count) schedule entries")
        
        let business = Business(
            googlePlaceId: place.id,
            name: place.name,
            address: place.address,
            latitude: place.location?.latitude ?? 0,
            longitude: place.location?.longitude ?? 0,
            phoneNumber: place.internationalPhoneNumber,
            website: place.websiteUri,
            openingHours: schedule
        )
        
        print("Created business object")
        
        do {
            context.insert(business)
            try context.save()
            print("Successfully saved business to database")
            
            addedBusinessIds.insert(place.id)
        } catch {
            print("Error saving business: \(error)")
            errorMessage = "Failed to add business. Please try again."
        }
    }
    
    func clearSearchIfEmpty() {
        if searchText.isEmpty {
            searchResults = []
            errorMessage = nil
        }
    }
    
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
