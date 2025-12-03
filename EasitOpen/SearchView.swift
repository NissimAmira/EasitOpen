//
//  SearchView.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    private let placesService = GooglePlacesService()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search results
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No results found")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Search for businesses")
                            .font(.headline)
                        Text("Try searching for coffee shops, restaurants, or stores")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List(searchResults) { place in
                        SearchResultRow(place: place) {
                            addBusiness(place)
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search businesses")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { oldValue, newValue in
                if newValue.isEmpty {
                    searchResults = []
                    errorMessage = nil
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                searchResults = try await placesService.searchPlaces(query: searchText)
                isSearching = false
            } catch {
                isSearching = false
                errorMessage = "Failed to search. Please try again."
                print("Search error: \(error)")
            }
        }
    }
    
    private func addBusiness(_ place: PlaceResult) {
        // Convert Google Place to our Business model
        let schedule = convertOpeningHours(place.currentOpeningHours)
        
        let business = Business(
            name: place.name,
            address: place.address,
            latitude: place.location?.latitude ?? 0,
            longitude: place.location?.longitude ?? 0,
            phoneNumber: place.internationalPhoneNumber,
            website: place.websiteUri,
            openingHours: schedule
        )
        
        modelContext.insert(business)
        
        // Clear search and show confirmation
        searchText = ""
        searchResults = []
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

#Preview {
    SearchView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
