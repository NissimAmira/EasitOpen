import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var homeLocation: CLLocation?
    @Published var homeAddress: String?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        authorizationStatus = locationManager.authorizationStatus
        
        // Load home location and address from UserDefaults
        homeLocation = loadHomeLocationFromStorage()
        homeAddress = loadHomeAddressFromStorage()
    }
    
    // Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Start updating location
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Get one-time location
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.locationError = error
            print("⚠️ Location error: \(error.localizedDescription)")
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            // If authorized, start updating
            if manager.authorizationStatus == .authorizedWhenInUse || 
               manager.authorizationStatus == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }
}

// MARK: - Home Location Storage
extension LocationManager {
    private enum Keys {
        static let homeLatitude = "homeLatitude"
        static let homeLongitude = "homeLongitude"
        static let homeAddress = "homeAddress"
    }
    
    private func loadHomeLocationFromStorage() -> CLLocation? {
        let latitude = UserDefaults.standard.double(forKey: Keys.homeLatitude)
        let longitude = UserDefaults.standard.double(forKey: Keys.homeLongitude)
        
        // Check if values were actually set (default is 0.0)
        guard latitude != 0.0 || longitude != 0.0 else { return nil }
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func loadHomeAddressFromStorage() -> String? {
        return UserDefaults.standard.string(forKey: Keys.homeAddress)
    }
    
    private func saveHomeLocationToStorage(_ location: CLLocation?) {
        if let location = location {
            UserDefaults.standard.set(location.coordinate.latitude, forKey: Keys.homeLatitude)
            UserDefaults.standard.set(location.coordinate.longitude, forKey: Keys.homeLongitude)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.homeLatitude)
            UserDefaults.standard.removeObject(forKey: Keys.homeLongitude)
            UserDefaults.standard.removeObject(forKey: Keys.homeAddress)
        }
    }
    
    private func saveHomeAddress(_ address: String?) {
        if let address = address {
            UserDefaults.standard.set(address, forKey: Keys.homeAddress)
        } else {
            UserDefaults.standard.removeObject(forKey: Keys.homeAddress)
        }
    }
    
    // Set current location as home
    func setCurrentLocationAsHome() {
        guard let current = currentLocation else { return }
        homeLocation = current
        saveHomeLocationToStorage(current)
        
        // Reverse geocode to get address
        reverseGeocodeHomeLocation(current)
    }
    
    // Set custom coordinates as home
    func setHomeLocation(latitude: Double, longitude: Double, address: String? = nil) {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        homeLocation = location
        saveHomeLocationToStorage(location)
        
        if let address = address {
            // Use provided address
            homeAddress = address
            saveHomeAddress(address)
        } else {
            // Reverse geocode to get address
            reverseGeocodeHomeLocation(location)
        }
    }
    
    // Clear home location
    func clearHomeLocation() {
        homeLocation = nil
        homeAddress = nil
        saveHomeLocationToStorage(nil)
    }
    
    private func reverseGeocodeHomeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let address = self.formatAddress(from: placemark)
                DispatchQueue.main.async {
                    self.homeAddress = address
                    self.saveHomeAddress(address)
                }
            }
        }
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
