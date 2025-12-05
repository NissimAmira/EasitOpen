//
//  DashboardViewModel.swift
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
class DashboardViewModel: ObservableObject {
    // MARK: - Published State
    @Published var sortOption: SortOption = .name
    @Published var filterOption: FilterOption = .all
    @Published var searchText = ""
    @Published var isRefreshing = false
    @Published var refreshMessage: String?
    @Published var refreshMessageType: MessageType = .success
    @Published var alertState: AlertState?
    
    // MARK: - Dependencies
    private let refreshService: BusinessRefreshService
    private let locationManager: LocationManager
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case status = "Status"
        case distanceCurrent = "Distance (Current)"
        case distanceHome = "Distance (Home)"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case closingSoon = "Closing Soon"
        case closed = "Closed"
    }
    
    // MARK: - Initialization
    init(
        refreshService: BusinessRefreshService = BusinessRefreshService(),
        locationManager: LocationManager = .shared
    ) {
        self.refreshService = refreshService
        self.locationManager = locationManager
    }
    
    // MARK: - Business Logic
    
    func filteredAndSorted(_ businesses: [Business]) -> [Business] {
        var result = businesses
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { business in
                business.name.localizedCaseInsensitiveContains(searchText) ||
                business.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status
        switch filterOption {
        case .all: break
        case .open: result = result.filter { $0.status == .open }
        case .closingSoon: result = result.filter { $0.status == .closingSoon }
        case .closed: result = result.filter { $0.status == .closed }
        }
        
        // Sort
        switch sortOption {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .status:
            result.sort { statusPriority($0.status) < statusPriority($1.status) }
        case .distanceCurrent:
            if let location = locationManager.currentLocation {
                result.sort { $0.distance(from: location) < $1.distance(from: location) }
            }
        case .distanceHome:
            if let location = locationManager.homeLocation {
                result.sort { $0.distance(from: location) < $1.distance(from: location) }
            }
        }
        
        return result
    }
    
    func referenceLocation() -> CLLocation? {
        switch sortOption {
        case .distanceCurrent: return locationManager.currentLocation
        case .distanceHome: return locationManager.homeLocation
        default: return nil
        }
    }
    
    func validateSortOption(_ option: SortOption) {
        var shouldShowAlert = false
        let alertTitle = "Location Required"
        var alertMessage = ""
        var alertAction: (() -> Void)?
        
        switch option {
        case .distanceCurrent:
            if locationManager.currentLocation == nil {
                shouldShowAlert = true
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    alertMessage = "Enable location services to sort by distance."
                    alertAction = { self.locationManager.requestPermission() }
                case .denied, .restricted:
                    alertMessage = "Location access is disabled. Enable it in Settings."
                    alertAction = { 
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                default:
                    alertMessage = "Waiting for your location. Try again in a moment."
                }
            }
            
        case .distanceHome:
            if locationManager.homeLocation == nil {
                shouldShowAlert = true
                alertMessage = "Set a home location in Settings first."
            }
            
        default:
            break
        }
        
        if shouldShowAlert {
            alertState = AlertState(
                title: alertTitle,
                message: alertMessage,
                primaryButton: alertAction.map { action in
                    AlertState.AlertButton(title: "Open Settings", action: action)
                },
                secondaryButton: AlertState.AlertButton(title: "Cancel") {
                    self.sortOption = .name
                }
            )
        }
    }
    
    func refreshAllBusinesses(_ businesses: [Business]) async {
        print("\n🔄 Starting refresh of \(businesses.count) businesses...")
        isRefreshing = true
        
        let results = await refreshService.refreshAllBusinesses(businesses)
        
        isRefreshing = false
        
        let successCount = results.filter { $0.success }.count
        let changesCount = results.filter { $0.hasChanges }.count
        let failureCount = results.filter { !$0.success }.count
        
        print("✅ Refresh complete: \(successCount) succeeded, \(changesCount) had changes, \(failureCount) failed")
        
        if failureCount > 0 {
            showRefreshMessage("Updated \(successCount) of \(businesses.count) businesses", type: .warning)
        } else if changesCount > 0 {
            showRefreshMessage("Updated \(changesCount) business(es) with new hours", type: .success)
        } else {
            showRefreshMessage("All businesses are up to date", type: .info)
        }
    }
    
    // MARK: - Private Helpers
    
    private func statusPriority(_ status: BusinessStatus) -> Int {
        switch status {
        case .open: return 0
        case .closingSoon: return 1
        case .closed: return 2
        }
    }
    
    private func showRefreshMessage(_ message: String, type: MessageType) {
        refreshMessage = message
        refreshMessageType = type
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            refreshMessage = nil
        }
    }
}
