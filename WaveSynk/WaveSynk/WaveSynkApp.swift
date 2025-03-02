import SwiftUI
import SwiftData
import UserNotifications

@main
struct WaveSynkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Spot.self,
            Alert.self,
            Forecast.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Check if we should show the direct welcome screen
                if UserDefaults.standard.bool(forKey: "showDirectWelcome") {
                    DirectWelcomeView()
                } else {
                    OnboardingView()
                }
                
                // Temporary buttons to control views
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            // Button to show normal onboarding flow
                            Button(action: {
                                // Reset onboarding state
                                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                UserDefaults.standard.set(false, forKey: "showDirectWelcome")
                                // Force app refresh
                                NotificationCenter.default.post(name: NSNotification.Name("RefreshApp"), object: nil)
                            }) {
                                Text("Show Onboarding")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            // Button to show direct welcome screen
                            Button(action: {
                                // Set flag to show direct welcome
                                UserDefaults.standard.set(true, forKey: "showDirectWelcome")
                                // Force app refresh
                                NotificationCenter.default.post(name: NSNotification.Name("RefreshApp"), object: nil)
                            }) {
                                Text("Show Welcome")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshApp"))) { _ in
                // This will force a view refresh
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Flag to determine if push notifications are available
    private var pushNotificationsAvailable: Bool {
        #if DEBUG
        // For development with personal team, disable push notifications
        return false
        #else
        return true
        #endif
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(Configuration.alertCheckInterval)
        
        // Configure notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        #if DEBUG
        // Extract certificate hashes for pinning (only in debug builds)
        extractCertificateHashes()
        #else
        // In production, set up certificate rotation
        setupCertificateRotation()
        #endif
        
        return true
    }
    
    #if DEBUG
    private func extractCertificateHashes() {
        Task {
            // Create a progress indicator
            print("Starting certificate hash extraction...")
            
            // Extract hashes for all environments
            let hosts = [
                "api.wavesynk.com",
                "dev-api.wavesynk.com",
                "staging-api.wavesynk.com"
            ]
            
            var successCount = 0
            
            for host in hosts {
                if let hash = await CertificateHashExtractor.extractPublicKeyHash(from: host) {
                    print("✅ Successfully extracted hash for \(host): \(hash)")
                    
                    // Add the hash to the trusted hashes
                    CertificatePinningService.shared.addTrustedHash(hash, for: host)
                    successCount += 1
                } else {
                    print("❌ Failed to extract hash for \(host)")
                }
            }
            
            print("Certificate extraction complete: \(successCount)/\(hosts.count) successful")
            
            // Schedule periodic certificate checks
            scheduleCertificateChecks()
        }
    }
    
    private func scheduleCertificateChecks() {
        // Schedule a task to check certificates periodically
        Task {
            // Wait for 24 hours before checking again
            try? await Task.sleep(nanoseconds: 24 * 60 * 60 * 1_000_000_000)
            
            // Only continue if the app is still running
            if !Task.isCancelled {
                await checkCertificates()
                scheduleCertificateChecks()
            }
        }
    }
    
    private func checkCertificates() async {
        print("Performing periodic certificate check...")
        
        let hosts = [
            "api.wavesynk.com",
            "dev-api.wavesynk.com",
            "staging-api.wavesynk.com"
        ]
        
        for host in hosts {
            if let hash = await CertificateHashExtractor.extractPublicKeyHash(from: host) {
                // Add the hash to the trusted hashes (it will only be added if it's new)
                CertificatePinningService.shared.addTrustedHash(hash, for: host)
            }
        }
    }
    #endif
    
    // MARK: - Certificate Rotation
    
    func setupCertificateRotation() {
        // Schedule certificate rotation checks
        Task {
            while true {
                // Check certificates every week
                try? await Task.sleep(nanoseconds: 7 * 24 * 60 * 60 * 1_000_000_000)
                
                // Fetch updated certificates from a secure endpoint
                await fetchUpdatedCertificates()
            }
        }
    }
    
    private func fetchUpdatedCertificates() async {
        // In a production app, this would fetch updated certificate hashes from a secure endpoint
        // For now, we'll just log that we would do this
        print("Would fetch updated certificate hashes from secure endpoint")
        
        // Example of how this might work:
        // 1. Make a request to a secure endpoint that provides certificate hashes
        // 2. Verify the response using a separate verification mechanism (e.g., code signing)
        // 3. Update the trusted hashes in the CertificatePinningService
        
        // For testing, we can use the CertificateHashExtractor to get current hashes
        #if DEBUG
        await checkCertificates()
        #endif
    }
    
    // MARK: - Push Notification Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Skip push notification handling when not available
        guard pushNotificationsAvailable else { return }
        
        Task { @MainActor in
            do {
                try await PushNotificationService.shared.setDeviceToken(deviceToken)
            } catch {
                print("Push notification registration failed: \(error.localizedDescription)")
                // In a production app, we might want to retry registration after a delay
                // or notify the user about the failure
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Skip push notification handling when not available
        guard pushNotificationsAvailable else { return }
        
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        // In a production app, we might want to show an alert to the user
        // or try to re-register after a delay
    }
    
    // MARK: - Background Fetch
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task { @MainActor in
            NotificationService.shared.handleBackgroundFetch(completionHandler)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Always show notifications when app is in foreground
        return [.banner, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Handle notification response
        await NotificationService.shared.userNotificationCenter(center, didReceive: response)
    }
    
    // MARK: - Error Handling
    
    private func handlePushNotificationError(_ error: Error) {
        let message: String
        
        switch error {
        case let pushError as PushNotificationError:
            message = pushError.localizedDescription
        case let networkError as NetworkError:
            message = networkError.localizedDescription
        default:
            message = error.localizedDescription
        }
        
        // In a production app, we would show this message to the user
        // through a notification system or alert
        print("Push notification error: \(message)")
    }
} 