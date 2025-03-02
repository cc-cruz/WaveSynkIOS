import SwiftUI

class OnboardingController: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var currentPage: OnboardingPage = .welcome
    @Published var showLoginFlow: Bool = false
    
    init() {
        // Check if user has already completed onboarding
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentPage = .welcome
        showLoginFlow = false
    }
    
    func goToNextPage() {
        switch currentPage {
        case .welcome:
            currentPage = .features
        case .features:
            currentPage = .permissions
        case .permissions:
            currentPage = .createAccount
        case .createAccount:
            completeOnboarding()
        }
    }
}

enum OnboardingPage {
    case welcome
    case features
    case permissions
    case createAccount
} 