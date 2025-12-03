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
                        Text(business.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Status badge
                        Text(business.isOpen ? "OPEN" : "CLOSED")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(business.isOpen ? Color.green : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text(business.address)
                        .font(.subheadline)
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
                HStack(spacing: 12) {
                    if let phone = business.phoneNumber {
                        Button(action: {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Call", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let website = business.website {
                        Button(action: {
                            if let url = URL(string: website) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("Website", systemImage: "safari.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: openInMaps) {
                        Label("Directions", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
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
