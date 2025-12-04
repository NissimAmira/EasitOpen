//
//  BusinessDetailView.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import MapKit
import SwiftData

struct BusinessDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let business: Business
    
    @State private var region: MKCoordinateRegion
    @State private var showDeleteAlert = false
    @State private var showEditLabel = false
    @State private var editingLabel: String = ""
    @State private var isRefreshing = false
    @State private var refreshMessage: String?
    @State private var refreshMessageType: MessageType = .success
    
    enum MessageType {
        case success, info, error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .info: return .blue
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    private let refreshService = BusinessRefreshService()
    
    init(business: Business) {
        self.business = business
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: business.latitude,
                longitude: business.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(business.displayName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Button(action: {
                                    editingLabel = business.customLabel ?? business.name
                                    showEditLabel = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if business.customLabel != nil {
                                Text(business.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Text(business.status.text)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(business.status.color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text(business.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Last updated indicator with staleness badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text("Updated \(business.lastUpdatedText)")
                            .font(.caption)
                        
                        // Staleness indicator dot
                        if business.isDataStale {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Map
                Map(coordinateRegion: $region, annotationItems: [business]) { place in
                    MapMarker(
                        coordinate: CLLocationCoordinate2D(
                            latitude: place.latitude,
                            longitude: place.longitude
                        ),
                        tint: .red
                    )
                }
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 8) {
                    if let phone = business.phoneNumber {
                        Button(action: {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.title3)
                                Text("Call")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let website = business.website {
                        Button(action: {
                            if let url = URL(string: website) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "safari.fill")
                                    .font(.title3)
                                Text("Website")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: openInMaps) {
                        VStack(spacing: 4) {
                            Image(systemName: "map.fill")
                                .font(.title3)
                            Text("Directions")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                // Opening Hours
                VStack(alignment: .leading, spacing: 12) {
                    Text("Opening Hours")
                        .font(.headline)
                    
                    if business.openingHours.isEmpty {
                        Text("No hours available")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(sortedSchedule(), id: \.weekday) { schedule in
                                HStack {
                                    Text(dayName(for: schedule.weekday))
                                        .frame(width: 100, alignment: .leading)
                                        .fontWeight(isToday(schedule.weekday) ? .bold : .regular)
                                    
                                    if schedule.isClosed {
                                        Text("Closed")
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(schedule.openTimeFormatted) - \(schedule.closeTimeFormatted)")
                                            .foregroundColor(isToday(schedule.weekday) ? .primary : .secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if isToday(schedule.weekday) {
                                        Image(systemName: "circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Delete button
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    Label("Remove Business", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom)
                .alert("Remove Business", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        deleteBusiness()
                    }
                } message: {
                    Text("Are you sure you want to remove \(business.name) from your dashboard?")
                }
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await refreshBusiness() } }) {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .overlay(alignment: .top) {
            if let message = refreshMessage {
                HStack(spacing: 8) {
                    Image(systemName: refreshMessageType.icon)
                        .foregroundColor(refreshMessageType.color)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(refreshMessageType.color.opacity(0.15))
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(refreshMessageType.color.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Edit Label", isPresented: $showEditLabel) {
            TextField("Custom name", text: $editingLabel)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveLabel()
            }
            if business.customLabel != nil {
                Button("Clear", role: .destructive) {
                    business.customLabel = nil
                }
            }
        } message: {
            Text("Give this business a custom name (e.g., \"My Favorite Cafe\")")
        }
    }
    
    private func sortedSchedule() -> [DaySchedule] {
        // Sort by weekday (1 = Sunday, 7 = Saturday)
        business.openingHours.sorted { $0.weekday < $1.weekday }
    }
    
    private func dayName(for weekday: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let index = weekday - 1
        return index >= 0 && index < days.count ? days[index] : "Unknown"
    }
    
    private func isToday(_ weekday: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        return today == weekday
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: business.latitude,
            longitude: business.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = business.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func saveLabel() {
        let trimmed = editingLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        business.customLabel = trimmed.isEmpty ? nil : trimmed
    }
    
    @MainActor
    private func refreshBusiness() async {
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
    
    private func showRefreshMessage(_ message: String, type: MessageType) {
        withAnimation {
            refreshMessage = message
            refreshMessageType = type
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                refreshMessage = nil
            }
        }
    }
    
    private func deleteBusiness() {
        modelContext.delete(business)
        dismiss()
    }
}

#Preview {
    let sampleSchedule = [
        DaySchedule(weekday: 1, openTime: 0, closeTime: 0, isClosed: true),
        DaySchedule(weekday: 2, openTime: 540, closeTime: 1080),
        DaySchedule(weekday: 3, openTime: 540, closeTime: 1080),
        DaySchedule(weekday: 4, openTime: 540, closeTime: 1080),
        DaySchedule(weekday: 5, openTime: 540, closeTime: 1080),
        DaySchedule(weekday: 6, openTime: 540, closeTime: 1080),
        DaySchedule(weekday: 7, openTime: 600, closeTime: 840)
    ]
    
    let sampleBusiness = Business(
        name: "Coffee Shop",
        address: "123 Main St, Tel Aviv",
        latitude: 32.0853,
        longitude: 34.7818,
        phoneNumber: "03-1234567",
        website: "https://example.com",
        openingHours: sampleSchedule
    )
    
    return NavigationStack {
        BusinessDetailView(business: sampleBusiness)
    }
    .modelContainer(for: [Business.self, DaySchedule.self])
}
