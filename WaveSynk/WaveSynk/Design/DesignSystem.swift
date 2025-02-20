import SwiftUI

enum DesignSystem {
    // MARK: - Colors
    enum Colors {
        // Primary Brand Colors
        static let primary = Color(hex: "0891B2")    // Ocean Blue
        static let secondary = Color(hex: "164E63")  // Deep Ocean
        static let accent = Color(hex: "06B6D4")     // Wave Blue
        
        // Supporting Colors
        static let success = Color(hex: "059669")    // Seaweed Green
        static let warning = Color(hex: "D97706")    // Sunset Orange
        static let error = Color(hex: "DC2626")      // Alert Red
        
        // Neutral Colors
        static let sand = Color(hex: "F5F5F4")       // Light Sand
        static let darkSand = Color(hex: "292524")   // Dark Sand
        
        // Semantic colors that adapt to light/dark mode
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        
        // Dynamic theme colors
        static var dynamicPrimary: Color {
            Color(uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? 
                    UIColor(hex: "0891B2") : UIColor(hex: "164E63")
            })
        }
        
        // Gradient Colors
        static let oceanGradient = LinearGradient(
            colors: [Color(hex: "0891B2"), Color(hex: "164E63")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let sunsetGradient = LinearGradient(
            colors: [Color(hex: "D97706"), Color(hex: "DC2626")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    enum Typography {
        static func title(_ text: String) -> Text {
            Text(text)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        
        static func heading(_ text: String) -> Text {
            Text(text)
                .font(.title2)
                .fontWeight(.semibold)
        }
        
        static func body(_ text: String) -> Text {
            Text(text)
                .font(.body)
        }
        
        static func caption(_ text: String) -> Text {
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Layout
    enum Layout {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let minimumTapTarget: CGFloat = 44
    }
    
    // MARK: - Buttons
    struct PrimaryButton: View {
        let title: String
        let action: () -> Void
        let isLoading: Bool
        
        init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
            self.title = title
            self.isLoading = isLoading
            self.action = action
        }
        
        var body: some View {
            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 8)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: Layout.minimumTapTarget)
                .foregroundColor(.white)
                .background(Colors.primary)
                .cornerRadius(Layout.cornerRadius)
            }
            .disabled(isLoading)
        }
    }
    
    struct SecondaryButton: View {
        let title: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.minimumTapTarget)
                    .foregroundColor(Colors.primary)
                    .background(Colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .stroke(Colors.primary, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Text Fields
    struct StyledTextField: View {
        let title: String
        let text: Binding<String>
        let placeholder: String
        var isSecure: Bool = false
        var keyboardType: UIKeyboardType = .default
        var autocapitalization: TextInputAutocapitalization = .never
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Colors.secondaryText)
                
                if isSecure {
                    SecureField(placeholder, text: text)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(autocapitalization)
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
        }
    }
    
    struct CustomTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding()
                .background(Colors.secondaryBackground)
                .cornerRadius(Layout.cornerRadius)
        }
    }
    
    // MARK: - Alerts and Messages
    struct ErrorMessage: View {
        let message: String
        
        var body: some View {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(Layout.cornerRadius)
        }
    }
}

// MARK: - Color Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
} 