import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @FocusState private var isUsernameFocused: Bool
    
    @State private var username = ""
    @State private var showSuccessMessage = false
    
    let showLogin: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Header
            VStack(spacing: 8) {
                DesignSystem.Typography.title("Reset Password")
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Enter your username to receive password reset instructions")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            
            if showSuccessMessage {
                // Success Message
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(DesignSystem.Colors.success)
                    
                    Text("Check your phone for instructions to reset your password")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    DesignSystem.PrimaryButton("Return to login", isLoading: false) {
                        showLogin()
                    }
                }
                .padding(.horizontal)
            } else {
                // Reset Form
                VStack(spacing: DesignSystem.Layout.spacing) {
                    DesignSystem.StyledTextField(
                        title: "Username",
                        text: $username,
                        placeholder: "Enter your username"
                    )
                    .focused($isUsernameFocused)
                    .submitLabel(.done)
                    
                    if let error = viewModel.error {
                        DesignSystem.ErrorMessage(message: error)
                    }
                }
                
                // Reset Button
                DesignSystem.PrimaryButton(
                    "Reset Password",
                    isLoading: viewModel.isLoading
                ) {
                    resetPassword()
                }
                .disabled(username.isEmpty)
            }
            
            Spacer()
            
            // Back to Login
            if !showSuccessMessage {
                VStack(spacing: 8) {
                    Text("Remember your password?")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    
                    DesignSystem.SecondaryButton(title: "Log in") {
                        showLogin()
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding(DesignSystem.Layout.spacing)
        .background(DesignSystem.Colors.background)
        .onAppear {
            isUsernameFocused = true
        }
    }
    
    private func resetPassword() {
        guard !username.isEmpty else { return }
        Task {
            viewModel.resetPassword(username: username)
            showSuccessMessage = true
        }
    }
}

#Preview {
    PasswordResetView(showLogin: {})
        .environmentObject(AuthenticationViewModel())
} 