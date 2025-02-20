import Foundation
import Security
import LocalAuthentication

@MainActor
class AuthenticationService {
    static let shared = AuthenticationService()
    private init() {}
    
    // MARK: - Properties
    private let keychainService = "com.wavesynk.auth"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userKey = "currentUser"
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenRefreshTask: Task<Void, Never>?
    
    // MARK: - Public Interface
    var isAuthenticated: Bool {
        accessToken != nil
    }
    
    func configure() {
        // Load tokens from keychain on app launch
        accessToken = getKeychainValue(for: accessTokenKey)
        refreshToken = getKeychainValue(for: refreshTokenKey)
        
        if refreshToken != nil {
            scheduleTokenRefresh()
        }
    }
    
    func setTokens(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
        
        // Store in keychain
        saveKeychainValue(access, for: accessTokenKey)
        saveKeychainValue(refresh, for: refreshTokenKey)
        
        scheduleTokenRefresh()
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
        
        // Remove from keychain
        deleteKeychainValue(for: accessTokenKey)
        deleteKeychainValue(for: refreshTokenKey)
    }
    
    // MARK: - Token Refresh
    private func scheduleTokenRefresh() {
        tokenRefreshTask?.cancel()
        
        tokenRefreshTask = Task {
            while !Task.isCancelled {
                // Wait for 50 minutes (assuming 1-hour token lifetime)
                try? await Task.sleep(nanoseconds: UInt64(50 * 60 * 1e9))
                
                guard let refreshToken = self.refreshToken else { break }
                
                do {
                    let (newAccess, newRefresh) = try await refreshTokens(refreshToken)
                    setTokens(access: newAccess, refresh: newRefresh)
                } catch {
                    // If refresh fails, log out user
                    clearTokens()
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                    break
                }
            }
        }
    }
    
    private func refreshTokens(_ refreshToken: String) async throws -> (access: String, refresh: String) {
        // TODO: Implement actual token refresh API call
        // This is a placeholder that should be replaced with actual API call
        throw NSError(domain: "Not Implemented", code: -1)
    }
    
    // MARK: - Biometric Authentication
    func canUseBiometricAuthentication() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        let reason = "Log in to WaveSynk"
        
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
    
    // MARK: - Keychain Helpers
    private func saveKeychainValue(_ value: String, for key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getKeychainValue(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteKeychainValue(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
} 