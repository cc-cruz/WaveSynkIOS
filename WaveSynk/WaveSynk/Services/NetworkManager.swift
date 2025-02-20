import Foundation
import SwiftData

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case invalidCredentials
    case registrationError(String)
    case maxAlertsReached
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

@MainActor
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let authService = AuthenticationService.shared
    private let cacheService = CacheService.shared
    private let forecastService = ForecastService.shared
    
    private let baseURL = Configuration.baseURL
    
    private func createRequest(_ endpoint: String, method: String = "GET") throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthenticationService.shared.currentAccessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> User {
        // Simulate API call for MVP
        let user = User(
            id: 1,
            username: username,
            email: "\(username)@example.com",
            phone: nil,
            notificationsEnabled: true
        )
        
        // Set authentication tokens
        authService.setTokens(
            access: "mock_access_token",
            refresh: "mock_refresh_token"
        )
        
        return user
    }
    
    func register(username: String, password: String, phone: String) async throws -> User {
        // Simulate API call for MVP
        let user = User(
            id: Int.random(in: 1...1000),
            username: username,
            email: "\(username)@example.com",
            phone: phone,
            notificationsEnabled: true
        )
        
        // Set authentication tokens
        authService.setTokens(
            access: "mock_access_token",
            refresh: "mock_refresh_token"
        )
        
        return user
    }
    
    func verifyPhone(code: String) async throws -> Bool {
        // Simulate verification for MVP
        return code == "123456"
    }
    
    func requestPasswordReset(username: String) async throws {
        // Simulate password reset request for MVP
    }
    
    // MARK: - Spots
    
    func fetchSpots() async throws -> [Spot] {
        // Check cache first if offline mode is enabled
        if Configuration.enableOfflineMode {
            if let cachedSpots = try await cacheService.getCachedSpots() {
                return cachedSpots
            }
        }
        
        // Simulate API call for MVP
        let spots = [
            Spot(id: 1,
                 name: "Ocean Beach",
                 spitcastId: "OB",
                 latitude: Decimal(37.7558),
                 longitude: Decimal(-122.5130),
                 region: "San Francisco",
                 subRegion: "Northern California",
                 spotType: "Beach Break",
                 difficulty: "Advanced",
                 consistency: "Good"),
            
            Spot(id: 2,
                 name: "Pacifica State Beach",
                 spitcastId: "PAC",
                 latitude: Decimal(37.5989),
                 longitude: Decimal(-122.5022),
                 region: "San Francisco",
                 subRegion: "Northern California",
                 spotType: "Beach Break",
                 difficulty: "Intermediate",
                 consistency: "Fair")
        ]
        
        // Cache spots if offline mode is enabled
        if Configuration.enableOfflineMode {
            try await cacheService.cacheSpots(spots)
        }
        
        return spots
    }
    
    // MARK: - Alerts
    
    func fetchAlerts(for userId: Int) async throws -> [Alert] {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        // Simulate API call for MVP
        return []
    }
    
    func createAlert(_ alert: Alert) async throws -> Alert {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        // Check if user has reached max alerts
        let existingAlerts = try await fetchAlerts(for: alert.userId)
        if existingAlerts.count >= Configuration.maxAlertsPerUser {
            throw NetworkError.maxAlertsReached
        }
        
        // Simulate API call for MVP
        return alert
    }
    
    func updateAlert(_ alert: Alert) async throws -> Alert {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        // Simulate API call for MVP
        return alert
    }
    
    func deleteAlert(_ alert: Alert) async throws {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        // Simulate API call for MVP
    }
    
    // MARK: - Conditions and Forecasts
    
    func fetchConditions(for spotId: Int) async throws -> [Condition] {
        // Use ForecastService to get real conditions
        let spot = try await getSpot(id: spotId)
        let condition = try await forecastService.fetchCurrentConditions(for: spot)
        return [condition]
    }
    
    func fetchForecast(for spotId: Int) async throws -> [Forecast] {
        // Use ForecastService to get real forecast
        let spot = try await getSpot(id: spotId)
        return try await forecastService.fetchForecast(for: spot)
    }
    
    // MARK: - Push Notifications
    
    func registerPushToken(_ token: String) async throws {
        let request = try createRequest("/push/register", method: "POST")
        let body = [
            "device_token": token,
            "platform": "ios",
            "app_version": Bundle.main.appVersion
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Failed to register push token")
        }
    }
    
    func unregisterPushToken(_ token: String) async throws {
        let request = try createRequest("/push/unregister", method: "POST")
        let body = ["device_token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Failed to unregister push token")
        }
    }
    
    func updatePushPreferences(enabled: Bool) async throws {
        let request = try createRequest("/push/preferences", method: "PUT")
        let body = ["enabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Failed to update push preferences")
        }
    }
    
    // MARK: - Helpers
    
    private func getSpot(id: Int) async throws -> Spot {
        let spots = try await fetchSpots()
        guard let spot = spots.first(where: { $0.id == id }) else {
            throw NetworkError.invalidResponse
        }
        return spot
    }
} 