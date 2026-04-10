import BackgroundTasks
import UserNotifications

enum BackgroundTaskManager {
    static let dailySummaryTaskId = "com.dehuacheng.kaori.app.daily-summary"
    static let agentPostCheckId = "com.dehuacheng.kaori.app.agent-post-check"

    // MARK: - Registration

    static func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: dailySummaryTaskId,
            using: nil
        ) { task in
            handleDailySummaryTask(task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: agentPostCheckId,
            using: nil
        ) { task in
            handleAgentPostCheckTask(task as! BGAppRefreshTask)
        }
    }

    // MARK: - Scheduling

    static func scheduleDailySummaryFetch() {
        let settings = NotificationSettings()
        guard settings.notificationsEnabled && settings.dailySummaryEnabled else { return }

        let request = BGAppRefreshTaskRequest(identifier: dailySummaryTaskId)
        // Schedule 1 hour before the daily summary notification time
        let fetchHour = settings.dailySummaryHour > 0 ? settings.dailySummaryHour - 1 : 23
        request.earliestBeginDate = nextDate(hour: fetchHour, minute: settings.dailySummaryMinute)
        try? BGTaskScheduler.shared.submit(request)
    }

    // MARK: - Handler

    private static func handleDailySummaryTask(_ task: BGAppRefreshTask) {
        let settings = NotificationSettings()
        guard settings.notificationsEnabled && settings.dailySummaryEnabled else {
            task.setTaskCompleted(success: true)
            scheduleDailySummaryFetch()
            return
        }

        let urlSession = URLSession(configuration: .default)
        let serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        let token = UserDefaults.standard.string(forKey: "token") ?? ""

        guard !serverURL.isEmpty, !token.isEmpty,
              let baseURL = URL(string: serverURL) else {
            task.setTaskCompleted(success: false)
            scheduleDailySummaryFetch()
            return
        }

        // Determine language from app setting
        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let langParam = langRaw.hasPrefix("zh") ? "zh" : "en"

        let url = baseURL.appendingPathComponent("api/summary/daily")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "language", value: langParam)]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            defer {
                task.setTaskCompleted(success: error == nil)
                scheduleDailySummaryFetch()
            }

            guard let data,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else { return }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let summary = json["summary"] as? String,
                  !summary.isEmpty else { return }

            // Replace the daily summary notification with LLM content
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["kaori.summary.daily"])

            let content = UNMutableNotificationContent()
            content.title = Localizer.localized("notification.dailySummaryTitle")
            content.body = summary
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = settings.dailySummaryHour
            dateComponents.minute = settings.dailySummaryMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let notifRequest = UNNotificationRequest(
                identifier: "kaori.summary.daily",
                content: content,
                trigger: trigger
            )
            center.add(notifRequest)
        }

        task.expirationHandler = {
            dataTask.cancel()
        }

        dataTask.resume()
    }

    // MARK: - Agent Post Check

    static func scheduleAgentPostCheck() {
        let request = BGAppRefreshTaskRequest(identifier: agentPostCheckId)
        // Check every ~15 minutes
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleAgentPostCheckTask(_ task: BGAppRefreshTask) {
        let serverURL = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        let token = UserDefaults.standard.string(forKey: "token") ?? ""

        guard !serverURL.isEmpty, !token.isEmpty,
              let baseURL = URL(string: serverURL) else {
            task.setTaskCompleted(success: false)
            scheduleAgentPostCheck()
            return
        }

        let url = baseURL.appendingPathComponent("api/post/agent-unread")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let urlSession = URLSession(configuration: .default)
        let dataTask = urlSession.dataTask(with: request) { data, response, error in
            defer {
                task.setTaskCompleted(success: error == nil)
                scheduleAgentPostCheck()
            }

            guard let data,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else { return }

            guard let posts = try? JSONDecoder().decode([AgentPostNotification].self, from: data),
                  !posts.isEmpty else { return }

            // Show notification for the first unread agent post
            let post = posts[0]
            let content = UNMutableNotificationContent()
            content.title = post.title ?? Localizer.localized("notification.agentPostTitle")
            content.body = String(post.content.prefix(200))
            content.sound = .default
            content.userInfo = ["type": "agent_post", "post_id": post.id]

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let notifRequest = UNNotificationRequest(
                identifier: "kaori.agent.post.\(post.id)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(notifRequest)
        }

        task.expirationHandler = {
            dataTask.cancel()
        }

        dataTask.resume()
    }

    // MARK: - Helpers

    private static func nextDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let candidate = calendar.date(from: components) else { return now }
        return candidate > now ? candidate : calendar.date(byAdding: .day, value: 1, to: candidate)!
    }
}

/// Lightweight model for decoding agent post notifications
private struct AgentPostNotification: Codable {
    let id: Int
    let title: String?
    let content: String
}
