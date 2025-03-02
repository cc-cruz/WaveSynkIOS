import Foundation
import SwiftUI

struct PhoneNumberFormatter {
    static func format(_ number: String) -> String {
        // Remove all non-numeric characters
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Handle US phone numbers (we can expand this later for international)
        if cleaned.count >= 10 {
            let areaCode = cleaned.prefix(3)
            let prefix = cleaned[cleaned.index(cleaned.startIndex, offsetBy: 3)..<cleaned.index(cleaned.startIndex, offsetBy: 6)]
            let number = cleaned[cleaned.index(cleaned.startIndex, offsetBy: 6)..<cleaned.index(cleaned.startIndex, offsetBy: min(10, cleaned.count))]
            
            return "(\(areaCode)) \(prefix)-\(number)"
        } else if cleaned.count >= 6 {
            let areaCode = cleaned.prefix(3)
            let prefix = cleaned[cleaned.index(cleaned.startIndex, offsetBy: 3)..<cleaned.index(cleaned.startIndex, offsetBy: 6)]
            return "(\(areaCode)) \(prefix)"
        } else if cleaned.count >= 3 {
            let areaCode = cleaned.prefix(3)
            return "(\(areaCode)"
        }
        
        return cleaned
    }
    
    static func validate(_ number: String) -> Bool {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleaned.count == 10 // Basic US phone number validation
    }
    
    static func unformat(_ number: String) -> String {
        return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    static func formatForDisplay(_ number: String) -> String {
        let cleaned = unformat(number)
        if cleaned.count == 10 {
            return format(cleaned)
        }
        return number
    }
}

// MARK: - Text Field Formatter
class PhoneNumberTextFieldFormatter: ObservableObject {
    @Published var text: String {
        didSet {
            if let filtered = filter(text) {
                text = filtered
            }
        }
    }
    
    init(text: String = "") {
        self.text = text
    }
    
    private func filter(_ input: String) -> String? {
        // Remove any non-numeric characters from the input
        let cleaned = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Don't allow more than 10 digits
        if cleaned.count > 10 {
            return PhoneNumberFormatter.format(String(cleaned.prefix(10)))
        }
        
        // Format the number
        return PhoneNumberFormatter.format(cleaned)
    }
}

// MARK: - Binding Extension
extension Binding where Value == String {
    func phoneNumberFormatting() -> Binding<String> {
        Binding<String>(
            get: {
                PhoneNumberFormatter.formatForDisplay(self.wrappedValue)
            },
            set: { newValue in
                self.wrappedValue = PhoneNumberFormatter.unformat(newValue)
            }
        )
    }
} 