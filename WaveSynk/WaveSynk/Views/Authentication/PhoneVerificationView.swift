import SwiftUI

struct PhoneVerificationView: View {
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @FocusState private var isCodeFocused: Bool
    
    @State private var verificationCode = ""
    
    let onVerificationComplete: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Header
            VStack(spacing: 8) {
                DesignSystem.Typography.title("Verify Phone")
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Enter the verification code sent to your phone")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            
            // Code Input
            VStack(spacing: DesignSystem.Layout.spacing) {
                DesignSystem.StyledTextField(
                    title: "Verification Code",
                    text: $verificationCode,
                    placeholder: "Enter 6-digit code",
                    keyboardType: .numberPad
                )
                .focused($isCodeFocused)
                .onChange(of: verificationCode) { newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        verificationCode = String(newValue.prefix(6))
                    }
                    // Auto-submit when 6 digits entered
                    if newValue.count == 6 {
                        verify()
                    }
                }
                
                if let error = viewModel.error {
                    DesignSystem.ErrorMessage(message: error)
                }
            }
            
            // Verify Button
            DesignSystem.PrimaryButton(
                "Verify",
                isLoading: viewModel.isLoading
            ) {
                verify()
            }
            .disabled(verificationCode.count != 6)
            
            // Resend Code
            Button(action: {
                // TODO: Implement resend code functionality
            }) {
                Text("Didn't receive a code?")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(DesignSystem.Layout.spacing)
        .background(DesignSystem.Colors.background)
        .onAppear {
            isCodeFocused = true
        }
    }
    
    private func verify() {
        guard verificationCode.count == 6 else { return }
        viewModel.verifyPhone(code: verificationCode)
    }
}

#Preview {
    PhoneVerificationView(onVerificationComplete: {})
        .environmentObject(AuthenticationViewModel())
} 