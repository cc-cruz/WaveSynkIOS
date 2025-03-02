import Foundation

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        // Read from Info.plist or environment variable
        return .production
        #endif
    }
}

enum Configuration {
    // MARK: - Version Control
    enum Version {
        static let major = 1
        static let minor = 0
        static let patch = 0
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        static var current: String {
            "\(major).\(minor).\(patch)"
        }
        
        static var full: String {
            "\(current) (\(build))"
        }
        
        static var isPreRelease: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
        
        static var minimumOSVersion: String {
            "15.0"
        }
        
        static var apiVersion: String {
            "v1"
        }
    }

    // MARK: - API Configuration
    static var baseURL: String {
        switch AppEnvironment.current {
        case .development:
            return "https://dev-api.wavesynk.com/\(Version.apiVersion)"
        case .staging:
            return "https://staging-api.wavesynk.com/\(Version.apiVersion)"
        case .production:
            return "https://api.wavesynk.com/\(Version.apiVersion)"
        }
    }
    
    // MARK: - API Keys
    static var noaaApiKey: String {
        // In a real app, these would be stored securely and possibly fetched from a secure server
        // For MVP, we'll use environment-specific keys
        switch AppEnvironment.current {
        case .development:
            return ProcessInfo.processInfo.environment["NOAA_API_KEY"] ?? "dev_key"
        case .staging:
            return ProcessInfo.processInfo.environment["NOAA_API_KEY"] ?? "staging_key"
        case .production:
            return ProcessInfo.processInfo.environment["NOAA_API_KEY"] ?? "prod_key"
        }
    }
    
    // MARK: - Feature Flags
    static let useMLForecasts = false // Will be enabled in future versions
    static let enableOfflineMode = true
    static let maxCacheAge: TimeInterval = 3600 // 1 hour
    
    // MARK: - App Settings
    static let minimumRefreshInterval: TimeInterval = 300 // 5 minutes
    static let defaultLocationRadius: Double = 50 // kilometers
    static let maxFavoriteSpots = 10
    
    // MARK: - Forecast Settings
    static let forecastDays = 5
    static let hourlyForecastPoints = 24 // Next 24 hours
    static let minimumConfidenceThreshold = 70 // Minimum confidence score to show forecast
    
    // MARK: - Cache Settings
    static let spotCacheSize = 100 // Number of spots to cache
    static let forecastCacheSize = 50 // Number of forecasts to cache
    
    // MARK: - Alert Settings
    static let maxAlertsPerUser = 5 // For MVP
    static let alertCheckInterval: TimeInterval = 900 // 15 minutes
    
    // MARK: - Error Messages
    static let errorMessages = [
        "network": "Unable to connect. Please check your internet connection.",
        "forecast": "Unable to fetch forecast data. Please try again later.",
        "location": "Unable to determine your location. Please check your location settings.",
        "auth": "Authentication failed. Please log in again.",
        "general": "Something went wrong. Please try again."
    ]
} 