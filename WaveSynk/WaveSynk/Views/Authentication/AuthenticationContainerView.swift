import SwiftUI

enum AuthenticationScreen {
    case login
    case register
    case phoneVerification
    case passwordReset
}

struct AuthenticationContainerView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var currentScreen: AuthenticationScreen = .login
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentScreen {
                case .login:
                    LoginView(
                        showRegister: { currentScreen = .register },
                        showPasswordReset: { currentScreen = .passwordReset }
                    )
                    
                case .register:
                    RegisterView(
                        showLogin: { currentScreen = .login }
                    )
                    
                case .phoneVerification:
                    PhoneVerificationView(
                        onVerificationComplete: {
                            // Handle successful verification
                        }
                    )
                    
                case .passwordReset:
                    PasswordResetView(
                        showLogin: { currentScreen = .login }
                    )
                }
            }
            .environmentObject(viewModel)
        }
        .onChange(of: viewModel.showPhoneVerification) { newValue in
            if newValue {
                currentScreen = .phoneVerification
            }
        }
    }
}

#Preview {
    AuthenticationContainerView()
} 