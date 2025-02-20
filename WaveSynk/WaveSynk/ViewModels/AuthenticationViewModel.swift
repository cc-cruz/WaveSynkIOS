import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showPhoneVerification = false
    
    private let networkManager = NetworkManager.shared
    private let authService = AuthenticationService.shared
    
    init() {
        // Check for existing authentication
        isAuthenticated = authService.isAuthenticated
    }
    
    // MARK: - Authentication Methods
    func login(username: String, password: String) {
        Task {
            isLoading = true
            error = nil
            
            do {
                if authService.canUseBiometricAuthentication() {
                    // If biometrics available, verify before proceeding
                    guard try await authService.authenticateWithBiometrics() else {
                        error = "Biometric authentication failed"
                        isLoading = false
                        return
                    }
                }
                
                currentUser = try await networkManager.login(username: username, password: password)
                isAuthenticated = true
            } catch NetworkError.invalidCredentials {
                error = "Invalid username or password"
            } catch {
                error = "Failed to log in. Please try again."
            }
            
            isLoading = false
        }
    }
    
    func register(username: String, password: String, phone: String) {
        Task {
            isLoading = true
            error = nil
            
            do {
                currentUser = try await networkManager.register(username: username, 
                                                              password: password, 
                                                              phone: phone)
                showPhoneVerification = true
            } catch NetworkError.registrationError(let message) {
                error = message
            } catch {
                error = "Failed to create account. Please try again."
            }
            
            isLoading = false
        }
    }
    
    func verifyPhone(code: String) {
        Task {
            isLoading = true
            error = nil
            
            do {
                let verified = try await networkManager.verifyPhone(code: code)
                if verified {
                    showPhoneVerification = false
                    isAuthenticated = true
                } else {
                    error = "Invalid verification code"
                }
            } catch {
                error = "Failed to verify phone number. Please try again."
            }
            
            isLoading = false
        }
    }
    
    func resetPassword(username: String) {
        Task {
            isLoading = true
            error = nil
            
            do {
                try await networkManager.requestPasswordReset(username: username)
                // Show success message or navigate to next step
            } catch {
                error = "Failed to request password reset. Please try again."
            }
            
            isLoading = false
        }
    }
    
    func logout() {
        authService.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }
} 