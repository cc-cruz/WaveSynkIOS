import Foundation
@testable import WaveSynk

enum TestConfiguration {
    // MARK: - Test Environment
    static let environment: AppEnvironment = .development
    
    // MARK: - Mock API Configuration
    static let mockBaseURL = "https://mock-api.wavesynk.com/v1"
    static let mockNOAAApiKey = "test_noaa_key"
    
    // MARK: - Test Data
    static let testCredentials = (
        username: "testuser",
        password: "TestPassword123!",
        phone: "5555555555"
    )
    
    static let testSpots = [
        Spot(
            id: 1,
            name: "Test Beach",
            spitcastId: "test-beach",
            latitude: Decimal(33.618),
            longitude: Decimal(-118.317),
            region: "Southern California",
            spotType: "Beach Break",
            difficulty: "Intermediate",
            consistency: "Fair",
            metadata: [
                "parking_info": "Street parking available",
                "local_tips": "Best on morning high tide"
            ]
        ),
        Spot(
            id: 2,
            name: "Another Beach",
            spitcastId: "another-beach",
            latitude: Decimal(33.749),
            longitude: Decimal(-119.053),
            region: "Southern California",
            spotType: "Point Break",
            difficulty: "Advanced",
            consistency: "Good",
            metadata: [
                "parking_info": "Parking lot available",
                "local_tips": "Watch out for rocks at low tide"
            ]
        )
    ]
    
    static let testForecasts: [Forecast] = {
        let now = Date()
        return (0..<24).map { hour in
            Forecast(
                id: UUID().uuidString,
                spotId: testSpots[0].id,
                timestamp: Calendar.current.date(byAdding: .hour, value: hour, to: now)!,
                waveHeight: Double.random(in: 1...8),
                wavePeriod: Double.random(in: 8...16),
                windSpeed: Double.random(in: 0...20),
                windDirection: Double.random(in: 0...360),
                waterTemperature: Double.random(in: 60...75),
                swellDirection: Double.random(in: 180...270),
                swellHeight: Double.random(in: 1...6),
                swellPeriod: Double.random(in: 8...16),
                confidence: Int.random(in: 70...100)
            )
        }
    }()
    
    // MARK: - Test Helpers
    static func setupTestEnvironment() {
        // Override configuration for testing
        Configuration.baseURL = mockBaseURL
        Configuration.noaaApiKey = mockNOAAApiKey
        
        // Reduce cache age for testing
        Configuration.maxCacheAge = 5 // 5 seconds for testing
        Configuration.minimumRefreshInterval = 2 // 2 seconds for testing
    }
    
    static func cleanupTestEnvironment() {
        // Clear any test data
        try? CacheService.shared.clearCache()
        AuthenticationService.shared.clearTokens()
    }
}

// MARK: - Mock Response Helpers
extension TestConfiguration {
    static func mockForecastResponse(for spot: Spot) -> [Forecast] {
        testForecasts.map { forecast in
            var mutableForecast = forecast
            mutableForecast.spotId = spot.id
            return mutableForecast
        }
    }
    
    static func mockCurrentConditions(for spot: Spot) -> Condition {
        Condition(
            id: Int.random(in: 1...1000),
            spotId: spot.id,
            timestamp: Date(),
            waveHeight: Decimal(Double.random(in: 1...8)),
            wavePeriod: Decimal(Double.random(in: 8...16)),
            windSpeed: Decimal(Double.random(in: 0...20)),
            windDirection: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"].randomElement()!
        )
    }
} 