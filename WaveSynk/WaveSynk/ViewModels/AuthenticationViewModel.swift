import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showPhoneVerification = false
    
    private let authService = AuthenticationService.shared
    private let networkManager = NetworkManager.shared
    
    init() {
        // Check for existing authentication
        isAuthenticated = authService.isAuthenticated
    }
    
    // MARK: - Authentication Methods
    func login(username: String, password: String) {
        Task {
            self.isLoading = true
            self.error = nil
            
            do {
                if self.authService.canUseBiometricAuthentication() {
                    // If biometrics available, verify before proceeding
                    guard try await self.authService.authenticateWithBiometrics() else {
                        self.error = NetworkError.authenticationFailed
                        self.isLoading = false
                        return
                    }
                }
                
                self.currentUser = try await self.networkManager.login(username: username, password: password)
                self.isAuthenticated = true
            } catch NetworkError.invalidCredentials {
                self.error = NetworkError.invalidCredentials
            } catch {
                self.error = error
            }
            
            self.isLoading = false
        }
    }
    
    func register(username: String, password: String, phone: String) {
        Task {
            self.isLoading = true
            self.error = nil
            
            do {
                self.currentUser = try await self.networkManager.register(username: username, 
                                                              password: password, 
                                                              phone: phone)
                self.showPhoneVerification = true
            } catch NetworkError.registrationError(let message) {
                self.error = NetworkError.registrationError(message)
            } catch {
                self.error = error
            }
            
            self.isLoading = false
        }
    }
    
    func verifyPhone(code: String) {
        Task {
            self.isLoading = true
            self.error = nil
            
            do {
                let verified = try await self.networkManager.verifyPhone(code: code)
                if verified {
                    self.showPhoneVerification = false
                    self.isAuthenticated = true
                } else {
                    self.error = NetworkError.invalidVerificationCode
                }
            } catch {
                self.error = error
            }
            
            self.isLoading = false
        }
    }
    
    func resetPassword(username: String) {
        Task {
            self.isLoading = true
            self.error = nil
            
            do {
                try await self.networkManager.requestPasswordReset(username: username)
                // Show success message or navigate to next step
            } catch {
                self.error = error
            }
            
            self.isLoading = false
        }
    }
    
    func logout() {
        authService.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }
} 