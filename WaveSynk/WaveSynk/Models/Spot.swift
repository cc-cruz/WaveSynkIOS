import Foundation
import SwiftData
import CoreLocation

@Model
final class Spot: Codable {
    var id: Int
    var name: String
    var spitcastId: String
    var latitude: Decimal
    var longitude: Decimal
    var region: String?
    var subRegion: String?
    var spotType: String?
    var difficulty: String?
    var consistency: String?
    var metadata: [String: String]
    var isFavorite: Bool
    var lastUpdated: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Condition.spot)
    var conditions: [Condition]?
    
    @Relationship(deleteRule: .cascade, inverse: \Alert.spot)
    var alerts: [Alert]?
    
    @Relationship(deleteRule: .cascade, inverse: \Forecast.spot)
    var forecasts: [Forecast]?
    
    init(id: Int,
         name: String,
         spitcastId: String,
         latitude: Decimal,
         longitude: Decimal,
         region: String? = nil,
         subRegion: String? = nil,
         spotType: String? = nil,
         difficulty: String? = nil,
         consistency: String? = nil,
         metadata: [String: String] = [:],
         isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.spitcastId = spitcastId
        self.latitude = latitude
        self.longitude = longitude
        self.region = region
        self.subRegion = subRegion
        self.spotType = spotType
        self.difficulty = difficulty
        self.consistency = consistency
        self.metadata = metadata
        self.isFavorite = isFavorite
        self.lastUpdated = Date()
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case spitcastId = "spitcast_id"
        case latitude
        case longitude
        case region
        case subRegion = "sub_region"
        case spotType = "spot_type"
        case difficulty
        case consistency
        case metadata
        case isFavorite = "is_favorite"
        case lastUpdated = "last_updated"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        spitcastId = try container.decode(String.self, forKey: .spitcastId)
        latitude = try container.decode(Decimal.self, forKey: .latitude)
        longitude = try container.decode(Decimal.self, forKey: .longitude)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        subRegion = try container.decodeIfPresent(String.self, forKey: .subRegion)
        spotType = try container.decodeIfPresent(String.self, forKey: .spotType)
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        consistency = try container.decodeIfPresent(String.self, forKey: .consistency)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(spitcastId, forKey: .spitcastId)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encodeIfPresent(subRegion, forKey: .subRegion)
        try container.encodeIfPresent(spotType, forKey: .spotType)
        try container.encodeIfPresent(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(consistency, forKey: .consistency)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
    
    // MARK: - Computed Properties
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: CLLocationDegrees(truncating: latitude as NSDecimalNumber),
            longitude: CLLocationDegrees(truncating: longitude as NSDecimalNumber)
        )
    }
    
    var location: CLLocation {
        CLLocation(latitude: CLLocationDegrees(truncating: latitude as NSDecimalNumber),
                  longitude: CLLocationDegrees(truncating: longitude as NSDecimalNumber))
    }
    
    var formattedCoordinates: String {
        String(format: "%.4f, %.4f", 
               Double(truncating: latitude as NSDecimalNumber),
               Double(truncating: longitude as NSDecimalNumber))
    }
    
    var formattedLocation: String {
        if let region = region {
            if let subRegion = subRegion {
                return "\(subRegion), \(region)"
            }
            return region
        }
        return formattedCoordinates
    }
    
    var currentCondition: Condition? {
        conditions?.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    var currentForecast: Forecast? {
        forecasts?.filter { $0.timestamp > Date() }
            .sorted(by: { $0.timestamp < $1.timestamp })
            .first
    }
    
    var formattedSpotType: String {
        spotType?.capitalized ?? "Unknown"
    }
    
    var formattedDifficulty: String {
        difficulty?.capitalized ?? "Unknown"
    }
    
    var formattedConsistency: String {
        consistency?.capitalized ?? "Unknown"
    }
    
    // MARK: - Distance Calculation
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        self.location.distance(from: location)
    }
    
    func formattedDistance(from location: CLLocation) -> String {
        let distance = self.distance(from: location)
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            let kilometers = distance / 1000
            return String(format: "%.1f km", kilometers)
        }
    }
    
    // MARK: - Forecast Analysis
    
    func forecastsForDate(_ date: Date) -> [Forecast] {
        let calendar = Calendar.current
        return forecasts?.filter { forecast in
            calendar.isDate(forecast.timestamp, inSameDayAs: date)
        }.sorted(by: { $0.timestamp < $1.timestamp }) ?? []
    }
    
    func bestTimeToSurf(on date: Date = Date()) -> Date? {
        let dayForecasts = forecastsForDate(date)
        
        // Find the forecast with the highest wave height and favorable wind conditions
        return dayForecasts.max { a, b in
            let aScore = calculateSurfScore(forecast: a)
            let bScore = calculateSurfScore(forecast: b)
            return aScore < bScore
        }?.timestamp
    }
    
    private func calculateSurfScore(forecast: Forecast) -> Double {
        var score = Double(truncating: forecast.waveHeight as NSDecimalNumber)
        
        // Penalize for high wind speeds (over 15 mph)
        let windSpeed = Double(truncating: forecast.windSpeed as NSDecimalNumber)
        if windSpeed > 15 {
            score -= (windSpeed - 15) * 0.5
        }
        
        return max(score, 0)
    }
} 