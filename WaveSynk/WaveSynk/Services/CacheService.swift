import Foundation
import SwiftData

@MainActor
class CacheService {
    static let shared = CacheService()
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    // MARK: - Cache Keys
    private enum CacheKey {
        static let lastRefresh = "lastRefreshTimestamp"
        static let spotCache = "spotCache"
        static let forecastCache = "forecastCache"
    }
    
    // MARK: - Public Methods
    
    /// Checks if we need to refresh data based on configuration
    func shouldRefreshData() -> Bool {
        guard let lastRefresh = defaults.object(forKey: CacheKey.lastRefresh) as? Date else {
            return true
        }
        
        return Date().timeIntervalSince(lastRefresh) >= Configuration.minimumRefreshInterval
    }
    
    /// Updates the last refresh timestamp
    func updateLastRefresh() {
        defaults.set(Date(), forKey: CacheKey.lastRefresh)
    }
    
    /// Saves spots to persistent storage
    func cacheSpots(_ spots: [Spot]) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(spots)
        
        // Save to file system for offline access
        let url = try spotsCacheURL()
        try data.write(to: url)
        
        // Update metadata
        defaults.set(Date(), forKey: CacheKey.spotCache)
    }
    
    /// Retrieves cached spots
    func getCachedSpots() async throws -> [Spot]? {
        guard Configuration.enableOfflineMode else { return nil }
        
        let url = try spotsCacheURL()
        guard let lastCache = defaults.object(forKey: CacheKey.spotCache) as? Date,
              Date().timeIntervalSince(lastCache) < Configuration.maxCacheAge,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Spot].self, from: data)
    }
    
    /// Saves forecasts to persistent storage
    func cacheForecast(_ forecast: [Forecast], for spotId: Int) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(forecast)
        
        // Save to file system
        let url = try forecastCacheURL(for: spotId)
        try data.write(to: url)
        
        // Update metadata
        let key = "\(CacheKey.forecastCache)_\(spotId)"
        defaults.set(Date(), forKey: key)
    }
    
    /// Retrieves cached forecast for a spot
    func getCachedForecast(for spotId: Int) async throws -> [Forecast]? {
        guard Configuration.enableOfflineMode else { return nil }
        
        let url = try forecastCacheURL(for: spotId)
        let key = "\(CacheKey.forecastCache)_\(spotId)"
        
        guard let lastCache = defaults.object(forKey: key) as? Date,
              Date().timeIntervalSince(lastCache) < Configuration.maxCacheAge,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Forecast].self, from: data)
    }
    
    /// Clears all cached data
    func clearCache() throws {
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        
        // Clear cache directory
        let cacheURL = try cacheDirectoryURL()
        try? fileManager.removeItem(at: cacheURL)
        try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    private func cacheDirectoryURL() throws -> URL {
        try fileManager.url(for: .cachesDirectory,
                          in: .userDomainMask,
                          appropriateFor: nil,
                          create: true)
        .appendingPathComponent("WaveSynk", isDirectory: true)
    }
    
    private func spotsCacheURL() throws -> URL {
        try cacheDirectoryURL().appendingPathComponent("spots.json")
    }
    
    private func forecastCacheURL(for spotId: Int) throws -> URL {
        try cacheDirectoryURL().appendingPathComponent("forecast_\(spotId).json")
    }
}

// MARK: - Cache Cleanup
extension CacheService {
    /// Performs cache maintenance
    func performMaintenance() async {
        do {
            let cacheURL = try cacheDirectoryURL()
            let contents = try fileManager.contentsOfDirectory(at: cacheURL,
                                                             includingPropertiesForKeys: [.contentModificationDateKey])
            
            for url in contents {
                guard let modificationDate = try url.resourceValues(forKeys: [.contentModificationDateKey])
                    .contentModificationDate else {
                    continue
                }
                
                // Remove files older than maxCacheAge
                if Date().timeIntervalSince(modificationDate) > Configuration.maxCacheAge {
                    try? fileManager.removeItem(at: url)
                }
            }
        } catch {
            // Log error but don't throw - cache cleanup is not critical
            print("Cache maintenance failed: \(error)")
        }
    }
} 