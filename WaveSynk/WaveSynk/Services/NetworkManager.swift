import Foundation
import SwiftData

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(String)
    case invalidCredentials
    case registrationError(String)
    case maxAlertsReached
    case connectionError
    case decodingError(String)
    case rateLimitExceeded
    case resourceNotFound(String)
    case badRequest(String)
    case tokenExpired
    case certificateValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again."
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .unauthorized:
            return "You are not authorized to perform this action. Please log in again."
        case .serverError(let message):
            return message
        case .invalidCredentials:
            return "Invalid username or password. Please try again."
        case .registrationError(let message):
            return message
        case .maxAlertsReached:
            return "You have reached the maximum number of alerts allowed."
        case .connectionError:
            return "Unable to connect to the server. Please check your internet connection."
        case .decodingError(let message):
            return "Error processing server response: \(message)"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .resourceNotFound(let resource):
            return "\(resource) not found."
        case .badRequest(let message):
            return "Invalid request: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .certificateValidationFailed:
            return "Security validation failed. Please ensure you're using the official app and try again."
        }
    }
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
    private let certificatePinningService = CertificatePinningService.shared
    
    private let baseURL = Configuration.baseURL
    
    // Use the pinned URLSession for all requests
    private var secureSession: URLSession {
        return certificatePinningService.session
    }
    
    private func createRequest(_ endpoint: String, method: String = "GET") throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("WaveSynk-iOS/\(Configuration.Version.full)", forHTTPHeaderField: "User-Agent")
        
        // Add authentication token if available
        if let token = authService.currentAccessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Set timeout
        request.timeoutInterval = 30.0
        
        return request
    }
    
    // MARK: - Request Execution with Retry
    
    private func executeRequest<T: Decodable>(_ request: URLRequest, retries: Int = 2) async throws -> T {
        // Use the common method to get data and response
        let (data, response) = try await executeRequestData(request, retries: retries)
        
        // Parse the response data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
    
    // Special version for empty responses
    private func executeRequest(_ request: URLRequest, retries: Int = 2) async throws {
        // Just execute the request and ignore the data
        _ = try await executeRequestData(request, retries: retries)
    }
    
    // Common method to execute a request and return data and response
    private func executeRequestData(_ request: URLRequest, retries: Int = 2) async throws -> (Data, HTTPURLResponse) {
        do {
            // Use the secure session with certificate pinning
            let (data, response) = try await secureSession.data(for: request)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                return (data, httpResponse)
                
            case 400:
                // Bad request
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["message"] {
                    throw NetworkError.badRequest(errorMessage)
                } else {
                    throw NetworkError.badRequest("Invalid request")
                }
                
            case 401:
                // Unauthorized - token might be expired
                if let token = authService.currentRefreshToken {
                    do {
                        // Try to refresh token
                        let (newAccess, newRefresh) = try await authService.refreshTokens(token)
                        authService.setTokens(access: newAccess, refresh: newRefresh)
                        
                        // Retry with new token
                        var newRequest = request
                        newRequest.setValue("Bearer \(newAccess)", forHTTPHeaderField: "Authorization")
                        return try await executeRequestData(newRequest, retries: retries - 1)
                    } catch {
                        throw NetworkError.tokenExpired
                    }
                } else {
                    throw NetworkError.unauthorized
                }
                
            case 404:
                throw NetworkError.resourceNotFound(request.url?.lastPathComponent ?? "Resource")
                
            case 429:
                // Rate limit exceeded
                if retries > 0 {
                    // Wait and retry
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    return try await executeRequestData(request, retries: retries - 1)
                } else {
                    throw NetworkError.rateLimitExceeded
                }
                
            case 500...599:
                // Server error
                if retries > 0 {
                    // Wait and retry
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    return try await executeRequestData(request, retries: retries - 1)
                } else {
                    throw NetworkError.serverError("Server error occurred. Please try again later.")
                }
                
            default:
                throw NetworkError.invalidResponse
            }
        } catch let urlError as URLError {
            // Handle URL session errors
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.connectionError
            case .timedOut:
                if retries > 0 {
                    // Retry on timeout
                    return try await executeRequestData(request, retries: retries - 1)
                } else {
                    throw NetworkError.connectionError
                }
            case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot, .serverCertificateHasBadDate:
                // Certificate pinning failed
                throw NetworkError.certificateValidationFailed
            default:
                throw NetworkError.serverError(urlError.localizedDescription)
            }
        } catch let networkError as NetworkError {
            // Re-throw network errors
            throw networkError
        } catch {
            // Handle other errors
            throw NetworkError.serverError(error.localizedDescription)
        }
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> User {
        let request = try createRequest("/auth/login", method: "POST")
        
        // Create request body
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform request
        let authResponse = try await executeRequest(request)
        
        // Store tokens
        authService.setTokens(
            access: authResponse.accessToken,
            refresh: authResponse.refreshToken
        )
        
        return authResponse.user
    }
    
    func register(username: String, password: String, phone: String) async throws -> User {
        let request = try createRequest("/auth/register", method: "POST")
        
        // Create request body
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "phone": phone
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform request
        let authResponse = try await executeRequest(request)
        
        // Store tokens
        authService.setTokens(
            access: authResponse.accessToken,
            refresh: authResponse.refreshToken
        )
        
        return authResponse.user
    }
    
    func verifyPhone(code: String) async throws -> Bool {
        let request = try createRequest("/auth/verify", method: "POST")
        
        // Create request body
        let body: [String: Any] = [
            "code": code
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform request
        do {
            let response: [String: Bool] = try await executeRequest(request)
            return response["verified"] ?? false
        } catch NetworkError.badRequest {
            // Invalid code
            return false
        } catch {
            throw error
        }
    }
    
    func requestPasswordReset(username: String) async throws {
        let request = try createRequest("/auth/reset-password", method: "POST")
        
        // Create request body
        let body: [String: Any] = [
            "username": username
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform request
        try await executeRequest(request)
    }
    
    // MARK: - Spots
    
    func fetchSpots() async throws -> [Spot] {
        // Check cache first if offline mode is enabled
        if Configuration.enableOfflineMode {
            if let cachedSpots = try await cacheService.getCachedSpots() {
                return cachedSpots
            }
        }
        
        let request = try createRequest("/spots")
        
        // Perform request
        let spots = try await executeRequest(request)
        
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
        
        let request = try createRequest("/alerts/user/\(userId)")
        
        // Perform request
        let alerts = try await executeRequest(request)
        
        return alerts
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
        
        let request = try createRequest("/alerts", method: "POST")
        
        // Create encoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Encode alert
        request.httpBody = try encoder.encode(alert)
        
        // Perform request
        let alertResponse = try await executeRequest(request)
        
        return alertResponse
    }
    
    func updateAlert(_ alert: Alert) async throws -> Alert {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        let request = try createRequest("/alerts/\(alert.id)", method: "PUT")
        
        // Create encoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        // Encode alert
        request.httpBody = try encoder.encode(alert)
        
        // Perform request
        let alertResponse = try await executeRequest(request)
        
        return alertResponse
    }
    
    func deleteAlert(_ alert: Alert) async throws {
        guard authService.isAuthenticated else {
            throw NetworkError.unauthorized
        }
        
        let request = try createRequest("/alerts/\(alert.id)", method: "DELETE")
        
        // Perform request
        try await executeRequest(request)
    }
    
    // MARK: - Conditions and Forecasts
    
    func fetchConditions(for spotId: Int) async throws -> [Condition] {
        let request = try createRequest("/conditions/spot/\(spotId)")
        
        do {
            let conditions: [Condition] = try await executeRequest(request)
            return conditions
        } catch NetworkError.resourceNotFound {
            // If no conditions found, try to get them from the forecast service
            let spot = try await getSpot(id: spotId)
            let condition = try await forecastService.fetchCurrentConditions(for: spot)
            return [condition]
        } catch {
            throw error
        }
    }
    
    func fetchForecast(for spotId: Int) async throws -> [Forecast] {
        // Check cache first if offline mode is enabled
        if Configuration.enableOfflineMode {
            if let cachedForecast = try await cacheService.getCachedForecast(for: spotId) {
                return cachedForecast
            }
        }
        
        let request = try createRequest("/forecasts/spot/\(spotId)")
        
        do {
            let forecasts: [Forecast] = try await executeRequest(request)
            
            // Cache forecasts if offline mode is enabled
            if Configuration.enableOfflineMode {
                try await cacheService.cacheForecast(forecasts, for: spotId)
            }
            
            return forecasts
        } catch NetworkError.resourceNotFound {
            // If no forecasts found, try to get them from the forecast service
            let spot = try await getSpot(id: spotId)
            let forecasts = try await forecastService.fetchForecast(for: spot)
            
            // Cache forecasts if offline mode is enabled
            if Configuration.enableOfflineMode {
                try await cacheService.cacheForecast(forecasts, for: spotId)
            }
            
            return forecasts
        } catch {
            throw error
        }
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
        
        try await executeRequest(request)
    }
    
    func unregisterPushToken(_ token: String) async throws {
        let request = try createRequest("/push/unregister", method: "POST")
        let body = ["device_token": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        try await executeRequest(request)
    }
    
    func updatePushPreferences(enabled: Bool) async throws {
        let request = try createRequest("/push/preferences", method: "PUT")
        let body = ["enabled": enabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        try await executeRequest(request)
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