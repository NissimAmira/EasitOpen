//
//  SearchView.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import SwiftData
import CoreLocation

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search results
                if viewModel.isSearching {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    noResultsView
                } else if viewModel.searchResults.isEmpty {
                    emptyStateView
                } else {
                    resultsView
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, prompt: "Search businesses")
            .onSubmit(of: .search) {
                Task { await viewModel.performSearch() }
            }
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.clearSearchIfEmpty()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        ProgressView("Searching...")
            .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No results found")
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
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
    }
    
    private var resultsView: some View {
        VStack(spacing: 0) {
            if locationManager.currentLocation != nil || locationManager.homeLocation != nil {
                sortPicker
            }
            resultsList
        }
    }
    
    private var sortPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sort by")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Picker("Sort by", selection: $viewModel.distanceSortOption) {
                ForEach(SearchViewModel.DistanceSortOption.allCases, id: \.self) { option in
                    if option == .relevance ||
                       (option == .current && locationManager.currentLocation != nil) ||
                       (option == .home && locationManager.homeLocation != nil) {
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private var resultsList: some View {
        List(viewModel.sortedResults()) { place in
            SearchResultRow(
                place: place,
                isAdded: viewModel.addedBusinessIds.contains(place.id),
                referenceLocation: viewModel.referenceLocation()
            ) {
                viewModel.addBusiness(place, to: modelContext)
            }
        }
    }
}

#Preview {
    SearchView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
