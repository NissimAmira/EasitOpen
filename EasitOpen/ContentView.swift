//
//  ContentView.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var businesses: [Business]
    @State private var hasCheckedForRefresh = false
    
    private let refreshService = BusinessRefreshService()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
        .task {
            // Only check once per app launch
            if !hasCheckedForRefresh {
                hasCheckedForRefresh = true
                await checkAndRefreshStaleData()
            }
        }
    }
    
    private func checkAndRefreshStaleData() async {
        // Find businesses that haven't been updated in 24+ hours
        // For testing: change 24 to 0 to force refresh on every launch
        let calendar = Calendar.current
        let staleThresholdHours = 24 // Change to 0 for testing
        
        let staleBusinesses = businesses.filter { business in
            let hoursSinceUpdate = calendar.dateComponents([.hour], from: business.lastUpdated, to: Date()).hour ?? 0
            return hoursSinceUpdate >= staleThresholdHours
        }
        
        guard !staleBusinesses.isEmpty else {
            print("✅ All businesses are fresh (updated within 24 hours)")
            return
        }
        
        print("🔄 Auto-refresh: Found \(staleBusinesses.count) stale business(es) to update")
        
        // Refresh stale businesses in the background
        let results = await refreshService.refreshAllBusinesses(staleBusinesses)
        
        let successCount = results.filter { $0.success }.count
        let changesCount = results.filter { $0.hasChanges }.count
        
        print("✅ Auto-refresh complete: \(successCount)/\(staleBusinesses.count) updated, \(changesCount) had changes")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
