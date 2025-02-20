import Foundation
import UserNotifications
import UIKit

enum PushNotificationError: LocalizedError {
    case registrationFailed(String)
    case unregistrationFailed(String)
    case permissionDenied
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .registrationFailed(let message):
            return "Failed to register device: \(message)"
        case .unregistrationFailed(let message):
            return "Failed to unregister device: \(message)"
        case .permissionDenied:
            return "Push notification permissions are required"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

@MainActor
class PushNotificationService {
    static let shared = PushNotificationService()
    
    private var deviceToken: String?
    private let networkManager = NetworkManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isRegistering = false
    
    private init() {
        // Check initial authorization status
        Task {
            await updateAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await updateAuthorizationStatus()
            
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            } else {
                throw PushNotificationError.permissionDenied
            }
        } catch {
            throw PushNotificationError.registrationFailed(error.localizedDescription)
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    // MARK: - Device Token Management
    
    func setDeviceToken(_ token: Data) async throws {
        isRegistering = true
        defer { isRegistering = false }
        
        // Convert token to string format
        let tokenParts = token.map { data in String(format: "%02.2hhx", data) }
        let tokenString = tokenParts.joined()
        
        do {
            try await networkManager.registerPushToken(tokenString)
            deviceToken = tokenString
        } catch {
            throw PushNotificationError.registrationFailed(error.localizedDescription)
        }
    }
    
    func clearDeviceToken() async throws {
        guard let token = deviceToken else { return }
        
        do {
            try await networkManager.unregisterPushToken(token)
            deviceToken = nil
        } catch {
            throw PushNotificationError.unregistrationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Status
    
    var isRegistered: Bool {
        deviceToken != nil
    }
    
    var canReceiveNotifications: Bool {
        authorizationStatus == .authorized && isRegistered
    }
} 