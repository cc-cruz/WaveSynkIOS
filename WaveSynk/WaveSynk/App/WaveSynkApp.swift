//
//  WaveSynkApp.swift
//  WaveSynk
//
//  Created by Carson Cruz on 1/16/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct WaveSynkApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Spot.self,
            Condition.self,
            Alert.self,
            Forecast.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            Configuration.alertCheckInterval
        )
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to string
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // TODO: Send token to backend
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationService.shared.handleBackgroundFetch(completionHandler)
    }
}
