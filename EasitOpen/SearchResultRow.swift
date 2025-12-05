//
//  SearchResultRow.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI
import CoreLocation

struct SearchResultRow: View {
    let place: PlaceResult
    let isAdded: Bool
    var referenceLocation: CLLocation? = nil
    let onAdd: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                
                Text(place.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let isOpen = place.currentOpeningHours?.openNow {
                        Text(isOpen ? "Open now" : "Closed")
                            .font(.caption)
                            .foregroundColor(isOpen ? .green : .red)
                    }
                    
                    // Distance display
                    if let refLoc = referenceLocation,
                       let placeLat = place.location?.latitude,
                       let placeLon = place.location?.longitude {
                        let placeLocation = CLLocation(latitude: placeLat, longitude: placeLon)
                        let distance = refLoc.distance(from: placeLocation)
                        let kilometers = distance / 1000.0
                        
                        Text(kilometers >= 1.0 ?
                             String(format: "%.1f km", kilometers) :
                             String(format: "%.0f m", distance))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            if isAdded {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Added")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
