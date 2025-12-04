import Foundation
import BackgroundTasks
import SwiftData

class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    
    // Unique identifier for our background task
    // This MUST match the identifier in Info.plist
    static let backgroundTaskIdentifier = "com.easitopen.refresh"
    
    private init() {}
    
    // Register the background task handler
    // Call this once at app launch
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        print("✅ Background task registered: \(Self.backgroundTaskIdentifier)")
    }
    
    // Schedule the next background refresh
    func scheduleBackgroundRefresh(intervalHours: Double = 8.0) {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        
        // Schedule to run after the specified interval
        // iOS will run it when appropriate (device charging, good network, etc.)
        let intervalSeconds = intervalHours * 60 * 60
        request.earliestBeginDate = Date(timeIntervalSinceNow: intervalSeconds)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled for \(request.earliestBeginDate!)")
        } catch {
            // Error Code 1 = Not permitted (expected in simulator)
            #if targetEnvironment(simulator)
            print("ℹ️ Background refresh scheduling skipped (simulator limitation)")
            #else
            print("❌ Could not schedule background refresh: \(error)")
            #endif
        }
    }
    
    // Handle the background refresh task
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        print("\n🔄 Background refresh task started")
        
        // Schedule the next refresh
        scheduleBackgroundRefresh()
        
        // Set expiration handler - called if iOS needs to terminate the task early
        task.expirationHandler = {
            print("⚠️ Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the refresh
        Task {
            let success = await performBackgroundRefresh()
            task.setTaskCompleted(success: success)
        }
    }
    
    // Perform the actual refresh work
    private func performBackgroundRefresh() async -> Bool {
        do {
            // Create a temporary model container for background context
            let container = try ModelContainer(for: Business.self, DaySchedule.self)
            let context = ModelContext(container)
            
            // Fetch all businesses
            let descriptor = FetchDescriptor<Business>()
            let businesses = try context.fetch(descriptor)
            
            guard !businesses.isEmpty else {
                print("ℹ️ No businesses to refresh")
                return true
            }
            
            print("🔄 Refreshing \(businesses.count) businesses in background")
            
            // Refresh all businesses
            let refreshService = BusinessRefreshService()
            let results = await refreshService.refreshAllBusinesses(businesses)
            
            // Save changes
            try context.save()
            
            let successCount = results.filter { $0.success }.count
            let changesCount = results.filter { $0.hasChanges }.count
            
            print("✅ Background refresh complete: \(successCount)/\(businesses.count) updated, \(changesCount) had changes")
            
            return successCount > 0
        } catch {
            print("❌ Background refresh error: \(error)")
            return false
        }
    }
    
    // Cancel all scheduled background refresh tasks
    func cancelBackgroundRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundTaskIdentifier)
        print("🛑 Background refresh cancelled")
    }
}
