//
//  SearchResultRow.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import SwiftUI

struct SearchResultRow: View {
    let place: PlaceResult
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
                
                if let isOpen = place.currentOpeningHours?.openNow {
                    Text(isOpen ? "Open now" : "Closed")
                        .font(.caption)
                        .foregroundColor(isOpen ? .green : .red)
                }
            }
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
