import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: Field?
    
    @State private var username = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var isFormValid = false
    
    // Validation states
    @State private var usernameError: String?
    @State private var passwordError: String?
    @State private var phoneError: String?
    
    let showLogin: () -> Void
    
    private enum Field {
        case username
        case password
        case phone
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Header
            VStack(spacing: 8) {
                DesignSystem.Typography.title("Create Account")
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Join WaveSynk to get personalized surf alerts")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            
            // Form Fields
            VStack(spacing: DesignSystem.Layout.spacing) {
                // Username Field
                VStack(alignment: .leading, spacing: 4) {
                    DesignSystem.StyledTextField(
                        title: "Username",
                        text: $username,
                        placeholder: "Choose a username"
                    )
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onChange(of: username) { _ in
                        validateUsername()
                    }
                    
                    if let error = usernameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 4) {
                    DesignSystem.StyledTextField(
                        title: "Password",
                        text: $password,
                        placeholder: "Create a password",
                        isSecure: true
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onChange(of: password) { _ in
                        validatePassword()
                    }
                    
                    if let error = passwordError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Phone Field
                VStack(alignment: .leading, spacing: 4) {
                    DesignSystem.StyledTextField(
                        title: "Phone Number",
                        text: $phone.phoneNumberFormatting(),
                        placeholder: "(555) 555-5555",
                        keyboardType: .phonePad
                    )
                    .focused($focusedField, equals: .phone)
                    .submitLabel(.done)
                    .onChange(of: phone) { _ in
                        validatePhone()
                    }
                    
                    if let error = phoneError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                if let error = viewModel.error {
                    DesignSystem.ErrorMessage(message: error)
                }
            }
            
            // Terms of Service
            Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
            
            // Sign Up Button
            DesignSystem.PrimaryButton(
                "Create account",
                isLoading: viewModel.isLoading
            ) {
                register()
            }
            .disabled(!isFormValid)
            
            Spacer()
            
            // Login Link
            VStack(spacing: 8) {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                DesignSystem.SecondaryButton(title: "Log in") {
                    showLogin()
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
                focusedField = .phone
            case .phone:
                if isFormValid {
                    register()
                }
            case .none:
                break
            }
        }
    }
    
    private func validateUsername() {
        // Username requirements: 3-20 characters, alphanumeric and underscores only
        let usernamePattern = "^[a-zA-Z0-9_]{3,20}$"
        if username.isEmpty {
            usernameError = "Username is required"
        } else if !username.range(of: usernamePattern, options: .regularExpression) != nil {
            usernameError = "Username must be 3-20 characters and contain only letters, numbers, and underscores"
        } else {
            usernameError = nil
        }
        updateFormValidation()
    }
    
    private func validatePassword() {
        // Password requirements: 8+ chars, 1 uppercase, 1 lowercase, 1 number
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
        } else if !hasUppercase || !hasLowercase || !hasNumber {
            passwordError = "Password must contain at least one uppercase letter, one lowercase letter, and one number"
        } else {
            passwordError = nil
        }
        updateFormValidation()
    }
    
    private func validatePhone() {
        if phone.isEmpty {
            phoneError = "Phone number is required"
        } else if !PhoneNumberFormatter.validate(phone) {
            phoneError = "Please enter a valid 10-digit phone number"
        } else {
            phoneError = nil
        }
        updateFormValidation()
    }
    
    private func updateFormValidation() {
        isFormValid = usernameError == nil && passwordError == nil && phoneError == nil &&
                     !username.isEmpty && !password.isEmpty && !phone.isEmpty
    }
    
    private func register() {
        guard isFormValid else { return }
        viewModel.register(
            username: username,
            password: password,
            phone: PhoneNumberFormatter.unformat(phone)
        )
    }
}

#Preview {
    RegisterView(showLogin: {})
        .environmentObject(AuthenticationViewModel())
} 