import SwiftUI

struct OnboardingView: View {
    @StateObject private var controller = OnboardingController()
    
    var body: some View {
        Group {
            if controller.hasCompletedOnboarding {
                // Show the main app content
                DashboardView()
            } else if controller.showLoginFlow {
                // Show login/registration flow
                AuthenticationContainerView()
                    .environmentObject(controller)
            } else {
                // Show onboarding flow
                switch controller.currentPage {
                case .welcome:
                    WelcomeView(showLoginFlow: $controller.showLoginFlow)
                        .transition(.opacity)
                case .features:
                    FeatureCarouselView()
                        .transition(.opacity)
                case .permissions:
                    Text("Permissions Request")
                        .transition(.opacity)
                        // Replace with actual PermissionsView when implemented
                case .createAccount:
                    Text("Account Creation")
                        .transition(.opacity)
                        // Replace with actual AccountCreationView when implemented
                }
            }
        }
        .animation(.easeInOut, value: controller.currentPage)
        .animation(.easeInOut, value: controller.hasCompletedOnboarding)
        .animation(.easeInOut, value: controller.showLoginFlow)
        .environmentObject(controller)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshApp"))) { _ in
            controller.resetOnboarding()
        }
    }
}

#Preview {
    OnboardingView()
} 