import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: Field?
    
    @State private var username = ""
    @State private var password = ""
    
    let showRegister: () -> Void
    let showPasswordReset: () -> Void
    
    private enum Field {
        case username
        case password
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Logo and Title
            VStack(spacing: DesignSystem.Layout.spacing) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                DesignSystem.Typography.title("WaveSynk")
                    .foregroundColor(DesignSystem.Colors.dynamicPrimary)
            }
            .padding(.vertical, 32)
            
            // Form Fields
            VStack(spacing: DesignSystem.Layout.spacing) {
                DesignSystem.StyledTextField(
                    title: "Username",
                    text: $username,
                    placeholder: "Enter your username"
                )
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                
                DesignSystem.StyledTextField(
                    title: "Password",
                    text: $password,
                    placeholder: "Enter your password",
                    isSecure: true
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                
                if let error = viewModel.error {
                    DesignSystem.ErrorMessage(message: error)
                }
            }
            
            // Login Button
            DesignSystem.PrimaryButton(
                "Log in",
                isLoading: viewModel.isLoading
            ) {
                login()
            }
            .disabled(username.isEmpty || password.isEmpty)
            
            // Forgot Password
            Button(action: showPasswordReset) {
                Text("Forgot password?")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding(.top, 8)
            
            Spacer()
            
            // Register Link
            VStack(spacing: 8) {
                Text("Don't have an account?")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                DesignSystem.SecondaryButton(title: "Create account") {
                    showRegister()
                }
            }
            .padding(.bottom, 16)
        }
        .padding(DesignSystem.Layout.spacing)
        .background(DesignSystem.Colors.background)
        .onSubmit {
            switch focusedField {
            case .username:
                focusedField = .password
            case .password:
                login()
            case .none:
                break
            }
        }
    }
    
    private func login() {
        guard !username.isEmpty && !password.isEmpty else { return }
        viewModel.login(username: username, password: password)
    }
}

#Preview {
    LoginView(
        showRegister: {},
        showPasswordReset: {}
    )
    .environmentObject(AuthenticationViewModel())
} 