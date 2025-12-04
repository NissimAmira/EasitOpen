//
//  NotificationManager.swift
//  EasitOpen
//
//  Created by nissim amira on 04/12/2025.
//

import UserNotifications
import SwiftUI
import Combine

// Represents a specific change to a business
struct BusinessChange {
    enum ChangeType {
        case hoursChanged(day: String, oldHours: String, newHours: String)
        case dayClosed(day: String)
        case dayOpened(day: String, hours: String)
        case phoneChanged(old: String?, new: String?)
        case websiteChanged(old: String?, new: String?)
    }
    
    let type: ChangeType
    let businessName: String
    let businessId: String
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // Check current notification permission status
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // Request notification permission from user
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    // Send notification when business hours change
    func sendChangeNotification(for changes: [BusinessChange]) async {
        guard authorizationStatus == .authorized else { return }
        
        for change in changes {
            let content = UNMutableNotificationContent()
            
            // Customize notification based on change type
            switch change.type {
            case .hoursChanged(let day, let oldHours, let newHours):
                content.title = "\(change.businessName) Changed Hours"
                content.body = "\(day): \(oldHours) → \(newHours)"
                content.sound = .default
                
            case .dayClosed(let day):
                content.title = "\(change.businessName) Closed"
                content.body = "Now closed on \(day)"
                content.sound = .default
                
            case .dayOpened(let day, let hours):
                content.title = "\(change.businessName) Now Open"
                content.body = "Now open on \(day): \(hours)"
                content.sound = .default
                
            case .phoneChanged(let old, let new):
                content.title = "\(change.businessName) Updated"
                content.body = "Phone: \(old ?? "N/A") → \(new ?? "N/A")"
                content.sound = .default
                
            case .websiteChanged(let old, let new):
                content.title = "\(change.businessName) Updated"
                content.body = "Website updated"
                content.sound = .default
            }
            
            // Add business ID to userInfo so we can open it when tapped
            content.userInfo = ["businessId": change.businessId]
            
            // Create unique identifier for this notification
            let identifier = "\(change.businessId)-\(Date().timeIntervalSince1970)"
            
            // Deliver immediately
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: nil // nil = deliver immediately
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Error sending notification: \(error)")
            }
        }
    }
}
