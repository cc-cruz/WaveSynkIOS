import Foundation
import CoreLocation

enum ForecastError: Error {
    case invalidData
    case noaaError(String)
    case buoyError(String)
    case calculationError
}

@MainActor
class ForecastService {
    static let shared = ForecastService()
    private init() {}
    
    private let networkManager = NetworkManager.shared
    private let cache = NSCache<NSString, CachedForecast>()
    
    // MARK: - Public Interface
    
    /// Fetches forecast for a specific spot, combining NOAA data and buoy readings
    func fetchForecast(for spot: Spot) async throws -> [Forecast] {
        // Check cache first
        if let cached = getCachedForecast(for: spot.id), !cached.isExpired {
            return cached.forecasts
        }
        
        async let noaaData = fetchNOAAData(latitude: spot.latitude, longitude: spot.longitude)
        async let buoyData = fetchNearestBuoyData(latitude: spot.latitude, longitude: spot.longitude)
        
        do {
            let (noaa, buoy) = try await (noaaData, buoyData)
            let forecasts = try processForecastData(noaa: noaa, buoy: buoy, for: spot)
            
            // Cache the results
            cacheForecast(forecasts, for: spot.id)
            
            return forecasts
        } catch {
            throw ForecastError.calculationError
        }
    }
    
    /// Fetches current conditions for a specific spot
    func fetchCurrentConditions(for spot: Spot) async throws -> Condition {
        // First try to get real-time buoy data
        do {
            let buoyData = try await fetchNearestBuoyData(
                latitude: spot.latitude,
                longitude: spot.longitude
            )
            return try processCurrentConditions(buoyData: buoyData, for: spot)
        } catch {
            // Fallback to NOAA data if buoy data unavailable
            let noaaData = try await fetchNOAAData(
                latitude: spot.latitude,
                longitude: spot.longitude
            )
            return try processCurrentConditions(noaaData: noaaData, for: spot)
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchNOAAData(latitude: Decimal, longitude: Decimal) async throws -> NOAAForecastData {
        // Format the URL with proper parameters
        let urlString = "https://api.noaa.gov/wavewatch/v3/point" +
            "?lat=\(latitude)&lon=\(longitude)" +
            "&parameters=HTSGW,PERPW,DIRPW,WVDIR,WVPER,WVHGT" +
            "&time=\(ISO8601DateFormatter().string(from: Date()))"
        
        guard let url = URL(string: urlString) else {
            throw ForecastError.invalidData
        }
        
        var request = URLRequest(url: url)
        request.setValue(Configuration.noaaApiKey, forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(NOAAForecastData.self, from: data)
    }
    
    private func fetchNearestBuoyData(latitude: Decimal, longitude: Decimal) async throws -> BuoyData {
        // Find nearest buoy first
        let nearestBuoy = try await findNearestBuoy(
            latitude: Double(truncating: latitude as NSDecimalNumber),
            longitude: Double(truncating: longitude as NSDecimalNumber)
        )
        
        // Then fetch its data
        let urlString = "https://www.ndbc.noaa.gov/data/realtime2/\(nearestBuoy.id).txt"
        guard let url = URL(string: urlString) else {
            throw ForecastError.invalidData
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseBuoyData(data)
    }
    
    private func findNearestBuoy(latitude: Double, longitude: Double) async throws -> Buoy {
        // In a real app, we would fetch this from a buoy directory API
        // For MVP, we'll use a static list of major buoys
        let buoys = [
            Buoy(id: "46222", name: "San Pedro", latitude: 33.618, longitude: -118.317),
            Buoy(id: "46025", name: "Santa Monica Bay", latitude: 33.749, longitude: -119.053),
            // Add more buoys as needed
        ]
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        return buoys.min { buoy1, buoy2 in
            let loc1 = CLLocation(latitude: buoy1.latitude, longitude: buoy1.longitude)
            let loc2 = CLLocation(latitude: buoy2.latitude, longitude: buoy2.longitude)
            return location.distance(from: loc1) < location.distance(from: loc2)
        } ?? buoys[0] // Fallback to first buoy if calculation fails
    }
    
    private func processForecastData(noaa: NOAAForecastData, buoy: BuoyData, for spot: Spot) throws -> [Forecast] {
        // Combine NOAA and buoy data to create forecasts
        // For MVP, we'll primarily use NOAA data and adjust with buoy observations
        return try noaa.timePoints.enumerated().map { index, timePoint in
            let adjustmentFactor = calculateAdjustmentFactor(noaa: noaa, buoy: buoy, timePoint: timePoint)
            
            return Forecast(
                id: Int.random(in: 1...1000),
                spotId: spot.id,
                timestamp: timePoint.timestamp,
                waveHeight: Decimal(timePoint.waveHeight * adjustmentFactor),
                wavePeriod: Decimal(timePoint.wavePeriod),
                windSpeed: Decimal(timePoint.windSpeed),
                windDirection: timePoint.windDirection,
                waterTemperature: buoy.waterTemperature != nil ? Decimal(buoy.waterTemperature!) : nil,
                swellDirection: Decimal(timePoint.swellDirection),
                swellHeight: Decimal(timePoint.swellHeight * adjustmentFactor),
                swellPeriod: Decimal(timePoint.swellPeriod),
                confidence: calculateConfidence(timePoint: timePoint, buoyData: buoy)
            )
        }
    }
    
    private func processCurrentConditions(buoyData: BuoyData, for spot: Spot) throws -> Condition {
        return Condition(
            id: Int.random(in: 1...1000),
            spotId: spot.id,
            timestamp: Date(),
            waveHeight: Decimal(buoyData.waveHeight),
            wavePeriod: Decimal(buoyData.wavePeriod),
            windSpeed: Decimal(buoyData.windSpeed),
            windDirection: buoyData.windDirection,
            swellDirection: Decimal(buoyData.swellDirection),
            swellHeight: Decimal(buoyData.swellHeight),
            swellPeriod: Decimal(buoyData.wavePeriod),
            quality: 3,
            isLive: true
        )
    }
    
    private func processCurrentConditions(noaaData: NOAAForecastData, for spot: Spot) throws -> Condition {
        guard let current = noaaData.timePoints.first else {
            throw ForecastError.invalidData
        }
        
        return Condition(
            id: Int.random(in: 1...1000),
            spotId: spot.id,
            timestamp: Date(),
            waveHeight: Decimal(current.waveHeight),
            wavePeriod: Decimal(current.wavePeriod),
            windSpeed: Decimal(current.windSpeed),
            windDirection: current.windDirection,
            swellDirection: Decimal(current.swellDirection),
            swellHeight: Decimal(current.swellHeight),
            swellPeriod: Decimal(current.swellPeriod),
            quality: 2,
            isLive: false
        )
    }
    
    private func calculateAdjustmentFactor(noaa: NOAAForecastData, buoy: BuoyData, timePoint: NOAATimePoint) -> Double {
        // For MVP, use a simple ratio between buoy observations and NOAA predictions
        // In a full version, this would use ML to learn spot-specific patterns
        if let noaaCurrent = noaa.timePoints.first {
            return max(0.5, min(2.0, buoy.waveHeight / noaaCurrent.waveHeight))
        }
        return 1.0
    }
    
    private func calculateConfidence(timePoint: NOAATimePoint, buoyData: BuoyData) -> Int {
        // Simple confidence calculation for MVP
        // Decrease confidence as forecast gets further in time
        let hoursDifference = Calendar.current.dateComponents(
            [.hour],
            from: Date(),
            to: timePoint.timestamp
        ).hour ?? 0
        
        return min(100, max(0, 100 - (hoursDifference / 24) * 10))
    }
    
    // MARK: - Caching
    
    private func getCachedForecast(for spotId: Int) -> CachedForecast? {
        return cache.object(forKey: NSString(string: String(spotId)))
    }
    
    private func cacheForecast(_ forecasts: [Forecast], for spotId: Int) {
        let cached = CachedForecast(forecasts: forecasts, timestamp: Date())
        cache.setObject(cached, forKey: NSString(string: String(spotId)))
    }
}

// MARK: - Supporting Types

struct NOAAForecastData: Codable {
    let timePoints: [NOAATimePoint]
}

struct NOAATimePoint: Codable {
    let timestamp: Date
    let waveHeight: Double
    let wavePeriod: Double
    let windSpeed: Double
    let windDirection: String
    let swellDirection: Double
    let swellHeight: Double
    let swellPeriod: Double
}

struct BuoyData {
    let waveHeight: Double
    let wavePeriod: Double
    let windSpeed: Double
    let windDirection: String
    let waterTemperature: Double?
    let timestamp: Date
    let swellDirection: Double = 0.0
    let swellHeight: Double = 0.0
    let swellPeriod: Double = 0.0
}

struct Buoy {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
}

class CachedForecast {
    let forecasts: [Forecast]
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 3600 // 1 hour cache
    }
    
    init(forecasts: [Forecast], timestamp: Date) {
        self.forecasts = forecasts
        self.timestamp = timestamp
    }
}

private enum ForecastConfiguration {
    static let noaaApiKey = "YOUR_NOAA_API_KEY" // Move to secure configuration
} 