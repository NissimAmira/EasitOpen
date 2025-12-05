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
    @StateObject private var viewModel: BusinessDetailViewModel
    @State private var region: MKCoordinateRegion
    @State private var showDeleteAlert = false
    
    init(business: Business) {
        _viewModel = StateObject(wrappedValue: BusinessDetailViewModel(business: business))
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
                                Text(viewModel.business.displayName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Button(action: { viewModel.startEditingLabel() }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if viewModel.business.customLabel != nil {
                                Text(viewModel.business.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Text(viewModel.business.status.text)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(viewModel.business.status.color)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text(viewModel.business.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Last updated indicator with staleness badge
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                        Text("Updated \(viewModel.business.lastUpdatedText)")
                            .font(.caption)
                        
                        // Staleness indicator dot
                        if viewModel.business.isDataStale {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Map
                Map(coordinateRegion: $region, annotationItems: [viewModel.business]) { place in
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
                    if let phone = viewModel.business.phoneNumber {
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
                    
                    if let website = viewModel.business.website {
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
                    
                    if viewModel.business.openingHours.isEmpty {
                        Text("No hours available")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.sortedSchedule(), id: \.weekday) { schedule in
                                HStack {
                                    Text(viewModel.dayName(for: schedule.weekday))
                                        .frame(width: 100, alignment: .leading)
                                        .fontWeight(viewModel.isToday(schedule.weekday) ? .bold : .regular)
                                    
                                    if schedule.isClosed {
                                        Text("Closed")
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("\(schedule.openTimeFormatted) - \(schedule.closeTimeFormatted)")
                                            .foregroundColor(viewModel.isToday(schedule.weekday) ? .primary : .secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.isToday(schedule.weekday) {
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
                    Text("Are you sure you want to remove \(viewModel.business.name) from your dashboard?")
                }
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await viewModel.refreshBusiness() } }) {
                    if viewModel.isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isRefreshing)
            }
        }
        .overlay(alignment: .top) {
            if let message = viewModel.refreshMessage {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.refreshMessageType.icon)
                        .foregroundColor(viewModel.refreshMessageType.color)
                    Text(message)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(viewModel.refreshMessageType.color.opacity(0.15))
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(viewModel.refreshMessageType.color.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Edit Label", isPresented: $viewModel.showEditLabel) {
            TextField("Custom name", text: $viewModel.editingLabel)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                viewModel.saveLabel()
            }
            if viewModel.business.customLabel != nil {
                Button("Clear", role: .destructive) {
                    viewModel.clearLabel()
                }
            }
        } message: {
            Text("Give this business a custom name (e.g., \"My Favorite Cafe\")")
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: viewModel.business.latitude,
            longitude: viewModel.business.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = viewModel.business.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    private func deleteBusiness() {
        modelContext.delete(viewModel.business)
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
