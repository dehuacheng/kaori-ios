import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        BackgroundTaskManager.registerTasks()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification tap when app is in foreground or background
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        if id == "kaori.summary.daily" {
            NotificationRouter.shared.pendingDestination = .dailySummary
        } else if id == "kaori.summary.weekly" {
            NotificationRouter.shared.pendingDestination = .weeklySummary
        } else if userInfo["type"] as? String == "agent_post",
                  let postId = userInfo["post_id"] as? Int {
            NotificationRouter.shared.pendingDestination = .agentPost(postId)
        }
        completionHandler()
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
