//
//  HomeLocationPickerView.swift
//  EasitOpen
//
//  Created by AI Assistant on 05/12/2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct HomeLocationPickerView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var isPresented: Bool
    
    @State private var addressInput = ""
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var previewLocation: CLLocation?
    @State private var previewAddress: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Address input
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Enter address", text: $addressInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                        .onSubmit {
                            searchAddress()
                        }
                    
                    if let error = searchError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if isSearching {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Quick action button
                if locationManager.currentLocation != nil {
                    Button(action: useCurrentLocation) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Use Current Location")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Map preview
                if let location = previewLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Map(position: $cameraPosition) {
                            Marker("Home", coordinate: location.coordinate)
                                .tint(.red)
                        }
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        if let address = previewAddress {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Address")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(address)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "map")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Enter an address to see it on the map")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .navigationTitle("Set Home Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        confirmHomeLocation()
                    }
                    .disabled(previewLocation == nil)
                }
            }
        }
    }
    
    private func searchAddress() {
        guard !addressInput.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addressInput) { placemarks, error in
            isSearching = false
            
            if let error = error {
                searchError = "Could not find address"
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                searchError = "Could not find coordinates for this address"
                return
            }
            
            // Update preview
            previewLocation = location
            previewAddress = formatAddress(from: placemark)
            
            // Update map camera
            cameraPosition = .region(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
    
    private func useCurrentLocation() {
        guard let current = locationManager.currentLocation else { return }
        
        previewLocation = current
        addressInput = ""
        
        // Update map camera
        cameraPosition = .region(MKCoordinateRegion(
            center: current.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
        
        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(current) { placemarks, error in
            if let placemark = placemarks?.first {
                previewAddress = formatAddress(from: placemark)
            }
        }
    }
    
    private func confirmHomeLocation() {
        guard let location = previewLocation else { return }
        
        locationManager.setHomeLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: previewAddress
        )
        
        isPresented = false
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let street = placemark.thoroughfare {
            components.append(street)
        }
        if let city = placemark.locality {
            components.append(city)
        }
        if let state = placemark.administrativeArea {
            components.append(state)
        }
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}
