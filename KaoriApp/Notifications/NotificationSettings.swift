import Foundation

@Observable
class NotificationSettings {
    // MARK: - Master Toggle

    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    // MARK: - Breakfast Reminder

    var breakfastReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(breakfastReminderEnabled, forKey: "breakfastReminderEnabled") }
    }
    var breakfastHour: Int {
        didSet { UserDefaults.standard.set(breakfastHour, forKey: "breakfastHour") }
    }
    var breakfastMinute: Int {
        didSet { UserDefaults.standard.set(breakfastMinute, forKey: "breakfastMinute") }
    }

    // MARK: - Lunch Reminder

    var lunchReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(lunchReminderEnabled, forKey: "lunchReminderEnabled") }
    }
    var lunchHour: Int {
        didSet { UserDefaults.standard.set(lunchHour, forKey: "lunchHour") }
    }
    var lunchMinute: Int {
        didSet { UserDefaults.standard.set(lunchMinute, forKey: "lunchMinute") }
    }

    // MARK: - Dinner Reminder

    var dinnerReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(dinnerReminderEnabled, forKey: "dinnerReminderEnabled") }
    }
    var dinnerHour: Int {
        didSet { UserDefaults.standard.set(dinnerHour, forKey: "dinnerHour") }
    }
    var dinnerMinute: Int {
        didSet { UserDefaults.standard.set(dinnerMinute, forKey: "dinnerMinute") }
    }

    // MARK: - Daily Summary

    var dailySummaryEnabled: Bool {
        didSet { UserDefaults.standard.set(dailySummaryEnabled, forKey: "dailySummaryEnabled") }
    }
    var dailySummaryHour: Int {
        didSet { UserDefaults.standard.set(dailySummaryHour, forKey: "dailySummaryHour") }
    }
    var dailySummaryMinute: Int {
        didSet { UserDefaults.standard.set(dailySummaryMinute, forKey: "dailySummaryMinute") }
    }

    // MARK: - Weekly Summary

    var weeklySummaryEnabled: Bool {
        didSet { UserDefaults.standard.set(weeklySummaryEnabled, forKey: "weeklySummaryEnabled") }
    }
    var weeklySummaryHour: Int {
        didSet { UserDefaults.standard.set(weeklySummaryHour, forKey: "weeklySummaryHour") }
    }
    var weeklySummaryMinute: Int {
        didSet { UserDefaults.standard.set(weeklySummaryMinute, forKey: "weeklySummaryMinute") }
    }
    var weeklySummaryWeekday: Int {
        didSet { UserDefaults.standard.set(weeklySummaryWeekday, forKey: "weeklySummaryWeekday") }
    }

    // MARK: - Computed

    var hasAnyEnabled: Bool {
        notificationsEnabled && (
            breakfastReminderEnabled || lunchReminderEnabled || dinnerReminderEnabled ||
            dailySummaryEnabled || weeklySummaryEnabled
        )
    }

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard

        // Use object(forKey:) to distinguish "never set" from "set to false"
        self.notificationsEnabled = defaults.object(forKey: "notificationsEnabled") as? Bool ?? false
        self.breakfastReminderEnabled = defaults.object(forKey: "breakfastReminderEnabled") as? Bool ?? true
        self.breakfastHour = defaults.object(forKey: "breakfastHour") as? Int ?? 9
        self.breakfastMinute = defaults.object(forKey: "breakfastMinute") as? Int ?? 0
        self.lunchReminderEnabled = defaults.object(forKey: "lunchReminderEnabled") as? Bool ?? true
        self.lunchHour = defaults.object(forKey: "lunchHour") as? Int ?? 13
        self.lunchMinute = defaults.object(forKey: "lunchMinute") as? Int ?? 0
        self.dinnerReminderEnabled = defaults.object(forKey: "dinnerReminderEnabled") as? Bool ?? true
        self.dinnerHour = defaults.object(forKey: "dinnerHour") as? Int ?? 20
        self.dinnerMinute = defaults.object(forKey: "dinnerMinute") as? Int ?? 0
        self.dailySummaryEnabled = defaults.object(forKey: "dailySummaryEnabled") as? Bool ?? true
        self.dailySummaryHour = defaults.object(forKey: "dailySummaryHour") as? Int ?? 21
        self.dailySummaryMinute = defaults.object(forKey: "dailySummaryMinute") as? Int ?? 30
        self.weeklySummaryEnabled = defaults.object(forKey: "weeklySummaryEnabled") as? Bool ?? true
        self.weeklySummaryHour = defaults.object(forKey: "weeklySummaryHour") as? Int ?? 10
        self.weeklySummaryMinute = defaults.object(forKey: "weeklySummaryMinute") as? Int ?? 0
        self.weeklySummaryWeekday = defaults.object(forKey: "weeklySummaryWeekday") as? Int ?? 1 // Sunday
    }
}
