import XCTest
@testable import WaveSynk

final class ForecastIntegrationTests: XCTestCase {
    var forecastService: ForecastService!
    var cacheService: CacheService!
    var testSpot: Spot!
    
    override func setUp() async throws {
        forecastService = ForecastService.shared
        cacheService = CacheService.shared
        
        // Create a test spot
        testSpot = Spot(
            id: 1,
            name: "Test Beach",
            spitcastId: "test-beach",
            latitude: Decimal(33.618),  // San Pedro buoy location
            longitude: Decimal(-118.317),
            region: "Southern California",
            spotType: "Beach Break",
            difficulty: "Intermediate",
            consistency: "Fair",
            metadata: [
                "parking_info": "Street parking available",
                "local_tips": "Best on morning high tide"
            ]
        )
        
        // Clear cache before each test
        try cacheService.clearCache()
    }
    
    override func tearDown() async throws {
        try cacheService.clearCache()
    }
    
    // MARK: - Forecast Tests
    
    func testFetchForecast() async throws {
        // Test fetching forecast
        let forecasts = try await forecastService.fetchForecast(for: testSpot)
        
        // Verify forecast data
        XCTAssertFalse(forecasts.isEmpty, "Forecast should not be empty")
        XCTAssertGreaterThanOrEqual(forecasts.count, Configuration.hourlyForecastPoints,
                                   "Should have at least 24 hours of forecast")
        
        // Verify forecast properties
        let firstForecast = forecasts[0]
        XCTAssertEqual(firstForecast.spotId, testSpot.id)
        XCTAssertGreaterThan(firstForecast.waveHeight, 0)
        XCTAssertGreaterThan(firstForecast.wavePeriod, 0)
        XCTAssertGreaterThanOrEqual(firstForecast.confidence, 0)
        XCTAssertLessThanOrEqual(firstForecast.confidence, 100)
    }
    
    func testFetchCurrentConditions() async throws {
        // Test fetching current conditions
        let conditions = try await forecastService.fetchCurrentConditions(for: testSpot)
        
        // Verify current conditions
        XCTAssertEqual(conditions.spotId, testSpot.id)
        XCTAssertGreaterThan(conditions.waveHeight, 0)
        XCTAssertGreaterThan(conditions.wavePeriod, 0)
        XCTAssertFalse(conditions.windDirection.isEmpty)
    }
    
    // MARK: - Caching Tests
    
    func testForecastCaching() async throws {
        // Fetch and cache forecast
        let originalForecasts = try await forecastService.fetchForecast(for: testSpot)
        try await cacheService.cacheForecast(originalForecasts, for: testSpot.id)
        
        // Retrieve from cache
        let cachedForecasts = try await cacheService.getCachedForecast(for: testSpot.id)
        
        // Verify cached data
        XCTAssertNotNil(cachedForecasts)
        XCTAssertEqual(originalForecasts.count, cachedForecasts?.count)
        
        // Compare first forecast
        let original = originalForecasts[0]
        let cached = cachedForecasts![0]
        
        XCTAssertEqual(original.waveHeight, cached.waveHeight)
        XCTAssertEqual(original.wavePeriod, cached.wavePeriod)
        XCTAssertEqual(original.windSpeed, cached.windSpeed)
        XCTAssertEqual(original.windDirection, cached.windDirection)
    }
    
    func testCacheExpiration() async throws {
        // Fetch and cache forecast
        let forecasts = try await forecastService.fetchForecast(for: testSpot)
        try await cacheService.cacheForecast(forecasts, for: testSpot.id)
        
        // Verify cache is valid
        var cachedForecasts = try await cacheService.getCachedForecast(for: testSpot.id)
        XCTAssertNotNil(cachedForecasts)
        
        // Simulate cache expiration by modifying last cache timestamp
        let key = "forecastCache_\(testSpot.id)"
        UserDefaults.standard.set(Date().addingTimeInterval(-Configuration.maxCacheAge - 1), 
                                forKey: key)
        
        // Verify cache is expired
        cachedForecasts = try await cacheService.getCachedForecast(for: testSpot.id)
        XCTAssertNil(cachedForecasts)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidLocation() async throws {
        // Create spot with invalid location
        let invalidSpot = Spot(
            id: 2,
            name: "Invalid Location",
            spitcastId: "invalid",
            latitude: Decimal(90.1),  // Invalid latitude
            longitude: Decimal(0)
        )
        
        // Verify forecast fetch fails
        do {
            _ = try await forecastService.fetchForecast(for: invalidSpot)
            XCTFail("Should throw error for invalid location")
        } catch {
            XCTAssertTrue(error is ForecastError)
        }
    }
    
    func testOfflineMode() async throws {
        // Fetch and cache forecast
        let forecasts = try await forecastService.fetchForecast(for: testSpot)
        try await cacheService.cacheForecast(forecasts, for: testSpot.id)
        
        // Simulate offline mode by using invalid API key
        let originalKey = Configuration.noaaApiKey
        Configuration.noaaApiKey = "invalid_key"
        
        // Verify cached data is returned
        let cachedForecasts = try await cacheService.getCachedForecast(for: testSpot.id)
        XCTAssertNotNil(cachedForecasts)
        XCTAssertEqual(forecasts.count, cachedForecasts?.count)
        
        // Restore API key
        Configuration.noaaApiKey = originalKey
    }
}

// MARK: - Test Helpers
extension ForecastIntegrationTests {
    func waitForCache() async throws {
        // Wait for cache operations to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
} 