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
            DashboardView()
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(Configuration.alertCheckInterval)
        
        // Configure notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: - Push Notification Registration
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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