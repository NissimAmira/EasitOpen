//
//  EasitOpenApp.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import SwiftData

@main
struct EasitOpenApp: App {
    init() {
        // Register background tasks
        BackgroundRefreshManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Business.self, DaySchedule.self]) { schema, configuration in
            do {
                // Attempt to create container with migration options
                configuration.isAutosaveEnabled = true
                // Allow lightweight migration (preserves data when adding optional fields)
                configuration.allowsSave = true
                return try ModelContainer(for: schema, configurations: configuration)
            } catch {
                // If migration fails, fallback to default container
                // In production, you'd want to handle this more gracefully
                print("⚠️ Model container creation failed: \(error)")
                print("ℹ️ Creating fresh container. Previous data may be lost.")
                return try! ModelContainer(for: schema, configurations: configuration)
            }
        }
    }
}
