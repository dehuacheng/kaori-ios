import UserNotifications

@Observable
class NotificationManager {
    var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            await MainActor.run { isAuthorized = false }
            return false
        }
    }

    func checkPermission() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule All

    func rescheduleAll(settings: NotificationSettings) {
        center.removeAllPendingNotificationRequests()

        guard settings.notificationsEnabled else { return }

        if settings.breakfastReminderEnabled {
            scheduleRepeating(
                id: "kaori.reminder.breakfast",
                title: Localizer.localized("notification.breakfastTitle"),
                body: Localizer.localized("notification.breakfastBody"),
                hour: settings.breakfastHour,
                minute: settings.breakfastMinute
            )
        }

        if settings.lunchReminderEnabled {
            scheduleRepeating(
                id: "kaori.reminder.lunch",
                title: Localizer.localized("notification.lunchTitle"),
                body: Localizer.localized("notification.lunchBody"),
                hour: settings.lunchHour,
                minute: settings.lunchMinute
            )
        }

        if settings.dinnerReminderEnabled {
            scheduleRepeating(
                id: "kaori.reminder.dinner",
                title: Localizer.localized("notification.dinnerTitle"),
                body: Localizer.localized("notification.dinnerBody"),
                hour: settings.dinnerHour,
                minute: settings.dinnerMinute
            )
        }

        if settings.dailySummaryEnabled {
            scheduleDailySummary(
                body: Localizer.localized("notification.fallbackDaily"),
                hour: settings.dailySummaryHour,
                minute: settings.dailySummaryMinute
            )
        }

        if settings.weeklySummaryEnabled {
            scheduleWeeklySummary(
                body: Localizer.localized("notification.fallbackWeekly"),
                hour: settings.weeklySummaryHour,
                minute: settings.weeklySummaryMinute,
                weekday: settings.weeklySummaryWeekday
            )
        }
    }

    // MARK: - Fixed Repeating Notifications

    private func scheduleRepeating(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Daily Summary

    func scheduleDailySummary(body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = Localizer.localized("notification.dailySummaryTitle")
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "kaori.summary.daily", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Weekly Summary

    func scheduleWeeklySummary(body: String, hour: Int, minute: Int, weekday: Int) {
        let content = UNMutableNotificationContent()
        content.title = Localizer.localized("notification.weeklySummaryTitle")
        content.body = body
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "kaori.summary.weekly", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Replace Summary Content

    func replaceDailySummary(body: String, settings: NotificationSettings) {
        guard settings.notificationsEnabled && settings.dailySummaryEnabled else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["kaori.summary.daily"])
        scheduleDailySummary(
            body: body,
            hour: settings.dailySummaryHour,
            minute: settings.dailySummaryMinute
        )
    }

    func replaceWeeklySummary(body: String, settings: NotificationSettings) {
        guard settings.notificationsEnabled && settings.weeklySummaryEnabled else { return }
        center.removePendingNotificationRequests(withIdentifiers: ["kaori.summary.weekly"])
        scheduleWeeklySummary(
            body: body,
            hour: settings.weeklySummaryHour,
            minute: settings.weeklySummaryMinute,
            weekday: settings.weeklySummaryWeekday
        )
    }

    // MARK: - Cancel

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
