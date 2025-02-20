import Foundation
import UserNotifications
import UIKit
import SwiftData

@MainActor
class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var navigationHandler: ((NotificationDestination) -> Void)?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func configure(with modelContext: ModelContext, navigationHandler: @escaping (NotificationDestination) -> Void) {
        self.modelContext = modelContext
        self.navigationHandler = navigationHandler
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            
            if granted {
                Task { @MainActor in
                    await UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Alert Notifications
    
    func scheduleAlertCheck() {
        // Cancel any existing background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        // Start new background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            if let task = self?.backgroundTask, task != .invalid {
                UIApplication.shared.endBackgroundTask(task)
                self?.backgroundTask = .invalid
            }
        }
        
        Task {
            await checkAlerts()
            
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }
    }
    
    private func checkAlerts() async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Fetch enabled alerts
            let descriptor = FetchDescriptor<Alert>(
                predicate: #Predicate<Alert> { alert in
                    alert.enabled == true
                }
            )
            
            let alerts = try modelContext.fetch(descriptor)
            
            for alert in alerts {
                if let spot = alert.spot,
                   let conditions = try? await NetworkManager.shared.fetchConditions(for: spot.id).first {
                    // Check if conditions match alert criteria
                    if alert.shouldTrigger(for: conditions) {
                        // Schedule local notification
                        await scheduleNotification(for: alert, with: conditions)
                        
                        // Update alert
                        alert.lastTriggered = Date()
                        alert.notificationsSent += 1
                    }
                }
            }
            
            try modelContext.save()
            
        } catch {
            print("Error checking alerts: \(error.localizedDescription)")
        }
    }
    
    private func scheduleNotification(for alert: Alert, with conditions: Condition) async {
        let content = UNMutableNotificationContent()
        content.title = "Surf's Up! 🏄‍♂️"
        content.body = createNotificationBody(for: alert, with: conditions)
        content.sound = .default
        
        // Add user info for deep linking
        content.userInfo = [
            "type": "alert",
            "alertId": alert.id,
            "spotId": alert.spotId
        ]
        
        // Create unique identifier for the notification
        let identifier = "alert-\(alert.id)-\(Date().timeIntervalSince1970)"
        
        // Schedule for immediate delivery
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Error scheduling notification: \(error.localizedDescription)")
        }
    }
    
    private func createNotificationBody(for alert: Alert, with conditions: Condition) -> String {
        let spotName = alert.spot?.name ?? "Your spot"
        return "\(spotName) has \(conditions.formattedWaveHeight) waves with \(conditions.formattedWindSpeed) \(conditions.windDirection) winds!"
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "alert":
            if let alertId = userInfo["alertId"] as? Int,
               let spotId = userInfo["spotId"] as? Int {
                navigationHandler?(.alert(alertId: alertId, spotId: spotId))
            }
        default:
            break
        }
    }
    
    // MARK: - Background Refresh
    
    func scheduleBackgroundRefresh() {
        // Schedule background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            Configuration.alertCheckInterval
        )
    }
    
    func handleBackgroundFetch(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            do {
                await checkAlerts()
                completionHandler(.newData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
}

// MARK: - Navigation Types
enum NotificationDestination {
    case alert(alertId: Int, spotId: Int)
} 