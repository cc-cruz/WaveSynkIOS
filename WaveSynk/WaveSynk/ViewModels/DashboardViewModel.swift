import SwiftUI
import CoreLocation
import SwiftData

@MainActor
class DashboardViewModel: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    @Published var userLocation: CLLocation?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let networkManager = NetworkManager.shared
    private let locationManager: CLLocationManager
    private var modelContext: ModelContext?
    
    override init() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        super.init()
        
        self.locationManager.delegate = self
        
        // Check initial authorization status
        locationAuthorizationStatus = locationManager.authorizationStatus
        
        // If already authorized, start updating location
        if locationAuthorizationStatus == .authorizedWhenInUse ||
           locationAuthorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func requestLocationUpdate() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Show alert or handle restricted/denied state
            error = "Location access is restricted. Please enable it in Settings to see nearby spots."
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func refreshSpots() async {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        error = nil
        
        do {
            let networkSpots = try await networkManager.fetchSpots()
            
            // Get existing spots from SwiftData
            let descriptor = FetchDescriptor<Spot>()
            let existingSpots = try modelContext.fetch(descriptor)
            
            // Update existing spots and add new ones
            for spot in networkSpots {
                if let existingSpot = existingSpots.first(where: { $0.id == spot.id }) {
                    // Update existing spot properties
                    existingSpot.name = spot.name
                    existingSpot.spitcastId = spot.spitcastId
                    existingSpot.latitude = spot.latitude
                    existingSpot.longitude = spot.longitude
                    existingSpot.region = spot.region
                    existingSpot.subRegion = spot.subRegion
                    existingSpot.spotType = spot.spotType
                    existingSpot.difficulty = spot.difficulty
                    existingSpot.consistency = spot.consistency
                    existingSpot.metadata = spot.metadata
                } else {
                    // Add new spot
                    modelContext.insert(spot)
                }
            }
            
            // Remove spots that no longer exist
            let networkSpotIds = Set(networkSpots.map { $0.id })
            for existingSpot in existingSpots {
                if !networkSpotIds.contains(existingSpot.id) {
                    modelContext.delete(existingSpot)
                }
            }
            
            // Save changes
            try modelContext.save()
        } catch {
            self.error = "Failed to load surf spots"
        }
        
        isLoading = false
    }
    
    func toggleFavorite(_ spot: Spot) {
        spot.isFavorite.toggle()
        
        // Save changes
        try? modelContext?.save()
    }
}

// MARK: - Location Manager Delegate
extension DashboardViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            error = "Location access is restricted. Please enable it in Settings to see nearby spots."
            userLocation = nil
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                self.error = "Location access is denied. Please enable it in Settings to see nearby spots."
            case .locationUnknown:
                self.error = "Unable to determine location. Please try again."
            default:
                self.error = "Location error: \(error.localizedDescription)"
            }
        }
    }
} 