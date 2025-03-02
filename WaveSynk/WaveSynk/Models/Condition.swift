import Foundation
import SwiftData

@Model
final class Condition: Codable {
    var id: Int
    var spotId: Int
    var timestamp: Date
    var waveHeight: Decimal      // in feet
    var wavePeriod: Decimal      // in seconds
    var windSpeed: Decimal       // in mph
    var windDirection: String    // cardinal direction (N, NE, etc.)
    var waterTemperature: Decimal? // in fahrenheit
    var swellDirection: Decimal  // in degrees
    var swellHeight: Decimal    // in feet
    var swellPeriod: Decimal    // in seconds
    var quality: Int            // wave quality rating (0-5)
    var isLive: Bool           // whether this is live buoy data
    
    // Relationship - Fix circular reference
    @Relationship
    var spot: Spot?
    
    init(id: Int,
         spotId: Int,
         timestamp: Date,
         waveHeight: Decimal,
         wavePeriod: Decimal,
         windSpeed: Decimal,
         windDirection: String,
         waterTemperature: Decimal? = nil,
         swellDirection: Decimal,
         swellHeight: Decimal,
         swellPeriod: Decimal,
         quality: Int,
         isLive: Bool = false) {
        self.id = id
        self.spotId = spotId
        self.timestamp = timestamp
        self.waveHeight = waveHeight
        self.wavePeriod = wavePeriod
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.waterTemperature = waterTemperature
        self.swellDirection = swellDirection
        self.swellHeight = swellHeight
        self.swellPeriod = swellPeriod
        self.quality = min(max(quality, 0), 5) // Ensure quality is between 0-5
        self.isLive = isLive
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case spotId = "spot_id"
        case timestamp
        case waveHeight = "wave_height"
        case wavePeriod = "wave_period"
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case waterTemperature = "water_temperature"
        case swellDirection = "swell_direction"
        case swellHeight = "swell_height"
        case swellPeriod = "swell_period"
        case quality
        case isLive = "is_live"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        spotId = try container.decode(Int.self, forKey: .spotId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        waveHeight = try container.decode(Decimal.self, forKey: .waveHeight)
        wavePeriod = try container.decode(Decimal.self, forKey: .wavePeriod)
        windSpeed = try container.decode(Decimal.self, forKey: .windSpeed)
        windDirection = try container.decode(String.self, forKey: .windDirection)
        waterTemperature = try container.decodeIfPresent(Decimal.self, forKey: .waterTemperature)
        swellDirection = try container.decode(Decimal.self, forKey: .swellDirection)
        swellHeight = try container.decode(Decimal.self, forKey: .swellHeight)
        swellPeriod = try container.decode(Decimal.self, forKey: .swellPeriod)
        quality = try container.decode(Int.self, forKey: .quality)
        isLive = try container.decode(Bool.self, forKey: .isLive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(spotId, forKey: .spotId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(waveHeight, forKey: .waveHeight)
        try container.encode(wavePeriod, forKey: .wavePeriod)
        try container.encode(windSpeed, forKey: .windSpeed)
        try container.encode(windDirection, forKey: .windDirection)
        try container.encodeIfPresent(waterTemperature, forKey: .waterTemperature)
        try container.encode(swellDirection, forKey: .swellDirection)
        try container.encode(swellHeight, forKey: .swellHeight)
        try container.encode(swellPeriod, forKey: .swellPeriod)
        try container.encode(quality, forKey: .quality)
        try container.encode(isLive, forKey: .isLive)
    }
    
    // MARK: - Formatted Values
    
    var formattedWaveHeight: String {
        String(format: "%.1f ft", Double(truncating: waveHeight as NSDecimalNumber))
    }
    
    var formattedWindSpeed: String {
        String(format: "%.1f mph", Double(truncating: windSpeed as NSDecimalNumber))
    }
    
    var formattedSwellHeight: String {
        String(format: "%.1f ft", Double(truncating: swellHeight as NSDecimalNumber))
    }
    
    var formattedWaterTemperature: String? {
        guard let temp = waterTemperature else { return nil }
        return String(format: "%.1f°F", Double(truncating: temp as NSDecimalNumber))
    }
    
    var qualityDescription: String {
        switch quality {
        case 0: return "Flat"
        case 1: return "Very Poor"
        case 2: return "Poor"
        case 3: return "Fair"
        case 4: return "Good"
        case 5: return "Epic"
        default: return "Unknown"
        }
    }
} 