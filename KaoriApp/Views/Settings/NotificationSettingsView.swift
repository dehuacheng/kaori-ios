import SwiftUI

struct NotificationSettingsView: View {
    @Environment(Localizer.self) private var L
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(NotificationSettings.self) private var settings

    @State private var permissionDenied = false

    var body: some View {
        @Bindable var settings = settings

        Form {
            // MARK: - Master Toggle
            Section {
                Toggle(L.t("notification.enabled"), isOn: $settings.notificationsEnabled)
                    .onChange(of: settings.notificationsEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let granted = await notificationManager.requestPermission()
                                if !granted {
                                    settings.notificationsEnabled = false
                                    permissionDenied = true
                                } else {
                                    notificationManager.rescheduleAll(settings: settings)
                                    BackgroundTaskManager.scheduleDailySummaryFetch()
                                }
                            }
                        } else {
                            notificationManager.cancelAll()
                        }
                    }

                if permissionDenied {
                    Text(L.t("notification.permissionDenied"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text(L.t("notification.master"))
            }

            if settings.notificationsEnabled {
                // MARK: - Meal Reminders
                Section {
                    reminderRow(
                        label: L.t("notification.breakfast"),
                        enabled: $settings.breakfastReminderEnabled,
                        hour: $settings.breakfastHour,
                        minute: $settings.breakfastMinute
                    )
                    reminderRow(
                        label: L.t("notification.lunch"),
                        enabled: $settings.lunchReminderEnabled,
                        hour: $settings.lunchHour,
                        minute: $settings.lunchMinute
                    )
                    reminderRow(
                        label: L.t("notification.dinner"),
                        enabled: $settings.dinnerReminderEnabled,
                        hour: $settings.dinnerHour,
                        minute: $settings.dinnerMinute
                    )
                } header: {
                    Text(L.t("notification.mealReminders"))
                }

                // MARK: - Summaries
                Section {
                    // Daily summary
                    reminderRow(
                        label: L.t("notification.dailySummary"),
                        enabled: $settings.dailySummaryEnabled,
                        hour: $settings.dailySummaryHour,
                        minute: $settings.dailySummaryMinute
                    )

                    // Weekly summary
                    Toggle(L.t("notification.weeklySummary"), isOn: $settings.weeklySummaryEnabled)
                        .onChange(of: settings.weeklySummaryEnabled) { _, _ in reschedule() }

                    if settings.weeklySummaryEnabled {
                        Picker(L.t("notification.day"), selection: $settings.weeklySummaryWeekday) {
                            Text(L.t("notification.sunday")).tag(1)
                            Text(L.t("notification.monday")).tag(2)
                            Text(L.t("notification.tuesday")).tag(3)
                            Text(L.t("notification.wednesday")).tag(4)
                            Text(L.t("notification.thursday")).tag(5)
                            Text(L.t("notification.friday")).tag(6)
                            Text(L.t("notification.saturday")).tag(7)
                        }
                        .onChange(of: settings.weeklySummaryWeekday) { _, _ in reschedule() }

                        timePicker(
                            hour: $settings.weeklySummaryHour,
                            minute: $settings.weeklySummaryMinute
                        )
                    }
                } header: {
                    Text(L.t("notification.summaries"))
                } footer: {
                    Text(L.t("notification.summaryFooter"))
                        .font(.caption)
                }
            }
        }
        .navigationTitle(L.t("notification.title"))
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private func reminderRow(
        label: String,
        enabled: Binding<Bool>,
        hour: Binding<Int>,
        minute: Binding<Int>
    ) -> some View {
        Toggle(label, isOn: enabled)
            .onChange(of: enabled.wrappedValue) { _, _ in reschedule() }

        if enabled.wrappedValue {
            timePicker(hour: hour, minute: minute)
        }
    }

    private func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        DatePicker(
            L.t("notification.time"),
            selection: timeBinding(hour: hour, minute: minute),
            displayedComponents: .hourAndMinute
        )
        .onChange(of: hour.wrappedValue) { _, _ in reschedule() }
        .onChange(of: minute.wrappedValue) { _, _ in reschedule() }
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = hour.wrappedValue
                components.minute = minute.wrappedValue
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                hour.wrappedValue = components.hour ?? 0
                minute.wrappedValue = components.minute ?? 0
            }
        )
    }

    private func reschedule() {
        notificationManager.rescheduleAll(settings: settings)
        BackgroundTaskManager.scheduleDailySummaryFetch()
    }
}
