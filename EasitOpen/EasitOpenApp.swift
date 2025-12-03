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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Business.self, DaySchedule.self])
    }
}
