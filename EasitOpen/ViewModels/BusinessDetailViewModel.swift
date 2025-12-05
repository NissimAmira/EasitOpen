//
//  BusinessDetailViewModel.swift
//  EasitOpen
//
//  Created by nissim amira on 05/12/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class BusinessDetailViewModel: ObservableObject {
    @Published var showEditLabel = false
    @Published var editingLabel = ""
    @Published var isRefreshing = false
    @Published var refreshMessage: String?
    @Published var refreshMessageType: MessageType = .success
    
    let business: Business
    private let refreshService: BusinessRefreshService
    
    nonisolated init(business: Business, refreshService: BusinessRefreshService = BusinessRefreshService()) {
        self.business = business
        self.refreshService = refreshService
    }
    
    func startEditingLabel() {
        editingLabel = business.customLabel ?? business.name
        showEditLabel = true
    }
    
    func saveLabel() {
        business.customLabel = editingLabel.isEmpty ? nil : editingLabel
        showEditLabel = false
    }
    
    func clearLabel() {
        business.customLabel = nil
    }
    
    func refreshBusiness() async {
        print("\n🔄 Manual refresh: \(business.displayName)")
        isRefreshing = true
        
        do {
            let changes = try await refreshService.refreshBusiness(business)
            isRefreshing = false
            
            if !changes.isEmpty {
                showRefreshMessage("Hours updated (\(changes.count) change\(changes.count == 1 ? "" : "s"))", type: .success)
                print("✅ Business hours were updated with \(changes.count) changes")
            } else {
                showRefreshMessage("Already up to date", type: .info)
                print("✅ No changes detected")
            }
        } catch {
            isRefreshing = false
            showRefreshMessage("Failed to refresh", type: .error)
            print("❌ Refresh error: \(error)")
        }
    }
    
    func sortedSchedule() -> [DaySchedule] {
        business.openingHours.sorted { $0.weekday < $1.weekday }
    }
    
    func dayName(for weekday: Int) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.weekdaySymbols = calendar.weekdaySymbols
        
        let adjustedIndex = (weekday - 1) % 7
        return formatter.weekdaySymbols[adjustedIndex]
    }
    
    func timeString(from minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return ""
    }
    
    func isToday(_ weekday: Int) -> Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        return weekday == today
    }
    
    private func showRefreshMessage(_ message: String, type: MessageType) {
        refreshMessage = message
        refreshMessageType = type
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            refreshMessage = nil
        }
    }
}
