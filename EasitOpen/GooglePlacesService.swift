//
//  GooglePlacesService.swift
//  EasitOpen
//
//  Created by nissim amira on 03/12/2025.
//

import Foundation
import CoreLocation

class GooglePlacesService {
    private let apiKey = Config.googlePlacesAPIKey
    private let baseURL = "https://places.googleapis.com/v1/places"
    
    // Search for places by text
    func searchPlaces(query: String) async throws -> [PlaceResult] {
        let searchURL = "\(baseURL):searchText"
        
        guard let components = URLComponents(string: searchURL) else {
            throw PlacesError.invalidURL
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location,places.currentOpeningHours,places.internationalPhoneNumber,places.websiteUri", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let body: [String: Any] = [
            "textQuery": query,
            "languageCode": "en"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlacesError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(PlacesSearchResponse.self, from: data)
        return result.places ?? []
    }
}

// Error types
enum PlacesError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

// Response models
struct PlacesSearchResponse: Codable {
    let places: [PlaceResult]?
}

struct PlaceResult: Codable, Identifiable {
    let id: String
    let displayName: LocalizedString?
    let formattedAddress: String?
    let location: Location?
    let currentOpeningHours: OpeningHours?
    let internationalPhoneNumber: String?
    let websiteUri: String?
    
    var name: String {
        displayName?.text ?? "Unknown"
    }
    
    var address: String {
        formattedAddress ?? "No address"
    }
}

struct LocalizedString: Codable {
    let text: String
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

struct OpeningHours: Codable {
    let openNow: Bool?
    let periods: [Period]?
    let weekdayDescriptions: [String]?
}

struct Period: Codable {
    let open: DayTime?
    let close: DayTime?
}

struct DayTime: Codable {
    let day: Int?
    let hour: Int?
    let minute: Int?
}
