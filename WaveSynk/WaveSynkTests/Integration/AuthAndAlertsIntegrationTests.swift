import XCTest
@testable import WaveSynk

final class AuthAndAlertsIntegrationTests: BaseWaveSynkTests {
    var authService: AuthenticationService!
    var networkManager: NetworkManager!
    var testUser: User!
    var testSpot: Spot!
    
    override func setUp() async throws {
        authService = AuthenticationService.shared
        networkManager = NetworkManager.shared
        
        // Create test user
        testUser = User(
            id: 1,
            username: "testuser",
            phone: "5555555555"
        )
        
        // Create test spot
        testSpot = Spot(
            id: 1,
            name: "Test Beach",
            spitcastId: "test-beach",
            latitude: Decimal(33.618),
            longitude: Decimal(-118.317)
        )
        
        // Clear any existing authentication
        authService.clearTokens()
    }
    
    override func tearDown() async throws {
        authService.clearTokens()
    }
    
    // MARK: - Authentication Tests
    
    func testLoginFlow() async throws {
        // Test successful login
        let user = try await networkManager.login(
            username: "testuser",
            password: "TestPassword123!"
        )
        
        XCTAssertEqual(user.username, testUser.username)
        XCTAssertTrue(authService.isAuthenticated)
        
        // Verify token storage
        XCTAssertNotNil(authService.currentAccessToken)
        
        // Test invalid credentials
        do {
            _ = try await networkManager.login(
                username: "testuser",
                password: "wrongpassword"
            )
            XCTFail("Should throw error for invalid credentials")
        } catch NetworkError.invalidCredentials {
            // Expected error
        }
    }
    
    func testRegistrationFlow() async throws {
        // Test successful registration
        let user = try await networkManager.register(
            username: "newuser",
            password: "NewPassword123!",
            phone: "5555555556"
        )
        
        XCTAssertEqual(user.username, "newuser")
        XCTAssertTrue(authService.isAuthenticated)
        
        // Test duplicate username
        do {
            _ = try await networkManager.register(
                username: "newuser",
                password: "AnotherPassword123!",
                phone: "5555555557"
            )
            XCTFail("Should throw error for duplicate username")
        } catch NetworkError.registrationError {
            // Expected error
        }
    }
    
    func testPhoneVerification() async throws {
        // Test successful verification
        let verified = try await networkManager.verifyPhone(code: "123456")
        XCTAssertTrue(verified)
        
        // Test invalid code
        let invalidVerification = try await networkManager.verifyPhone(code: "000000")
        XCTAssertFalse(invalidVerification)
    }
    
    // MARK: - Alert Tests
    
    func testAlertCreation() async throws {
        // Login first
        _ = try await networkManager.login(
            username: "testuser",
            password: "TestPassword123!"
        )
        
        // Create alert
        let alert = Alert(
            id: 1,
            userId: testUser.id,
            spotId: testSpot.id,
            minWaveHeight: Decimal(2),
            maxWaveHeight: Decimal(6),
            maxWindSpeed: Decimal(15),
            enabled: true
        )
        
        let createdAlert = try await networkManager.createAlert(alert)
        
        // Verify alert properties
        XCTAssertEqual(createdAlert.spotId, testSpot.id)
        XCTAssertEqual(createdAlert.userId, testUser.id)
        XCTAssertEqual(createdAlert.minWaveHeight, alert.minWaveHeight)
        XCTAssertEqual(createdAlert.maxWaveHeight, alert.maxWaveHeight)
        XCTAssertEqual(createdAlert.maxWindSpeed, alert.maxWindSpeed)
        XCTAssertTrue(createdAlert.enabled)
    }
    
    func testAlertLimits() async throws {
        // Login first
        _ = try await networkManager.login(
            username: "testuser",
            password: "TestPassword123!"
        )
        
        // Create maximum allowed alerts
        for i in 1...Configuration.maxAlertsPerUser {
            let alert = Alert(
                id: i,
                userId: testUser.id,
                spotId: testSpot.id,
                minWaveHeight: Decimal(2),
                maxWaveHeight: Decimal(6),
                maxWindSpeed: Decimal(15)
            )
            
            _ = try await networkManager.createAlert(alert)
        }
        
        // Try to create one more alert
        let extraAlert = Alert(
            id: Configuration.maxAlertsPerUser + 1,
            userId: testUser.id,
            spotId: testSpot.id,
            minWaveHeight: Decimal(2),
            maxWaveHeight: Decimal(6),
            maxWindSpeed: Decimal(15)
        )
        
        do {
            _ = try await networkManager.createAlert(extraAlert)
            XCTFail("Should throw error when exceeding max alerts")
        } catch {
            // Expected error
        }
    }
    
    func testAlertFetch() async throws {
        // Login first
        _ = try await networkManager.login(
            username: "testuser",
            password: "TestPassword123!"
        )
        
        // Create test alert
        let alert = Alert(
            id: 1,
            userId: testUser.id,
            spotId: testSpot.id,
            minWaveHeight: Decimal(2),
            maxWaveHeight: Decimal(6),
            maxWindSpeed: Decimal(15)
        )
        
        _ = try await networkManager.createAlert(alert)
        
        // Fetch alerts
        let alerts = try await networkManager.fetchAlerts(for: testUser.id)
        
        // Verify alerts
        XCTAssertFalse(alerts.isEmpty)
        XCTAssertEqual(alerts[0].spotId, testSpot.id)
        XCTAssertEqual(alerts[0].userId, testUser.id)
    }
    
    // MARK: - Authentication + Alert Integration Tests
    
    func testAuthenticationExpiration() async throws {
        // Login
        _ = try await networkManager.login(
            username: "testuser",
            password: "TestPassword123!"
        )
        
        // Simulate token expiration
        authService.clearTokens()
        
        // Try to fetch alerts
        do {
            _ = try await networkManager.fetchAlerts(for: testUser.id)
            XCTFail("Should throw error when token is expired")
        } catch NetworkError.unauthorized {
            // Expected error
        }
    }
}

// MARK: - Test Helpers
extension AuthAndAlertsIntegrationTests {
    func createTestAlert() -> Alert {
        Alert(
            id: Int.random(in: 1...1000),
            userId: testUser.id,
            spotId: testSpot.id,
            minWaveHeight: Decimal(2),
            maxWaveHeight: Decimal(6),
            maxWindSpeed: Decimal(15)
        )
    }
} 