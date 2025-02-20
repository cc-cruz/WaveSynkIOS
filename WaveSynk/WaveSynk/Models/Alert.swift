import Foundation
import SwiftData

@Model
final class Alert: Codable {
    var id: Int
    var userId: Int
    var spotId: Int
    var minWaveHeight: Decimal
    var maxWaveHeight: Decimal
    var minWindSpeed: Decimal
    var maxWindSpeed: Decimal
    var preferredWindDirections: [String]  // cardinal directions (N, NE, etc.)
    var enabled: Bool
    var createdAt: Date
    var lastTriggered: Date?
    var notificationsSent: Int
    
    // Relationships
    @Relationship(inverse: \User.alerts)
    var user: User?
    
    @Relationship(inverse: \Spot.alerts)
    var spot: Spot?
    
    init(id: Int,
         userId: Int,
         spotId: Int,
         minWaveHeight: Decimal,
         maxWaveHeight: Decimal,
         minWindSpeed: Decimal,
         maxWindSpeed: Decimal,
         preferredWindDirections: [String],
         enabled: Bool = true,
         createdAt: Date = Date(),
         lastTriggered: Date? = nil,
         notificationsSent: Int = 0) {
        self.id = id
        self.userId = userId
        self.spotId = spotId
        self.minWaveHeight = minWaveHeight
        self.maxWaveHeight = maxWaveHeight
        self.minWindSpeed = minWindSpeed
        self.maxWindSpeed = maxWindSpeed
        self.preferredWindDirections = preferredWindDirections
        self.enabled = enabled
        self.createdAt = createdAt
        self.lastTriggered = lastTriggered
        self.notificationsSent = notificationsSent
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case spotId = "spot_id"
        case minWaveHeight = "min_wave_height"
        case maxWaveHeight = "max_wave_height"
        case minWindSpeed = "min_wind_speed"
        case maxWindSpeed = "max_wind_speed"
        case preferredWindDirections = "preferred_wind_directions"
        case enabled
        case createdAt = "created_at"
        case lastTriggered = "last_triggered"
        case notificationsSent = "notifications_sent"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        spotId = try container.decode(Int.self, forKey: .spotId)
        minWaveHeight = try container.decode(Decimal.self, forKey: .minWaveHeight)
        maxWaveHeight = try container.decode(Decimal.self, forKey: .maxWaveHeight)
        minWindSpeed = try container.decode(Decimal.self, forKey: .minWindSpeed)
        maxWindSpeed = try container.decode(Decimal.self, forKey: .maxWindSpeed)
        preferredWindDirections = try container.decode([String].self, forKey: .preferredWindDirections)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastTriggered = try container.decodeIfPresent(Date.self, forKey: .lastTriggered)
        notificationsSent = try container.decode(Int.self, forKey: .notificationsSent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(spotId, forKey: .spotId)
        try container.encode(minWaveHeight, forKey: .minWaveHeight)
        try container.encode(maxWaveHeight, forKey: .maxWaveHeight)
        try container.encode(minWindSpeed, forKey: .minWindSpeed)
        try container.encode(maxWindSpeed, forKey: .maxWindSpeed)
        try container.encode(preferredWindDirections, forKey: .preferredWindDirections)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastTriggered, forKey: .lastTriggered)
        try container.encode(notificationsSent, forKey: .notificationsSent)
    }
    
    // MARK: - Formatted Values
    
    var formattedWaveHeightRange: String {
        "\(formatDecimal(minWaveHeight))-\(formatDecimal(maxWaveHeight)) ft"
    }
    
    var formattedWindSpeedRange: String {
        "\(formatDecimal(minWindSpeed))-\(formatDecimal(maxWindSpeed)) mph"
    }
    
    var formattedWindDirections: String {
        preferredWindDirections.joined(separator: ", ")
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        String(format: "%.1f", Double(truncating: value as NSDecimalNumber))
    }
    
    // MARK: - Alert Evaluation
    
    func shouldTrigger(for condition: Condition) -> Bool {
        // Check if alert is enabled
        guard enabled else { return false }
        
        // Check wave height range
        let waveHeightInRange = condition.waveHeight >= minWaveHeight && condition.waveHeight <= maxWaveHeight
        
        // Check wind speed range
        let windSpeedInRange = condition.windSpeed >= minWindSpeed && condition.windSpeed <= maxWindSpeed
        
        // Check wind direction
        let windDirectionMatch = preferredWindDirections.isEmpty || preferredWindDirections.contains(condition.windDirection)
        
        return waveHeightInRange && windSpeedInRange && windDirectionMatch
    }
} 