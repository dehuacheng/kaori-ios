import SwiftUI

struct ReminderCardModule: CardModule {
    let cardType = "reminder"
    let displayNameKey = "card.reminder"
    let iconName = "checklist"
    let accentColor = Color.green
    let supportsManualCreation = true
    let hasFeedDetailView = true
    let hasDataListView = true
    let presentationStyle = CardPresentationStyle.sheet
    let feedSwipeActions: [CardSwipeAction] = []

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let reminder = item.payload as? Reminder else { return AnyView(EmptyView()) }
        return AnyView(ReminderFeedCard(reminder: reminder))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let reminder = item.payload as? Reminder else { return nil }
        return AnyView(ReminderDetailView(reminder: reminder))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        AnyView(ReminderCreateView())
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(ReminderListView())
    }

    @MainActor
    func feedTrailingSwipeContent(item: FeedItem) -> AnyView? {
        guard let reminder = item.payload as? Reminder else { return nil }
        return AnyView(ReminderTrailingSwipe(reminderId: reminder.id))
    }

    @MainActor
    func feedLeadingSwipeContent(item: FeedItem) -> AnyView? {
        guard let reminder = item.payload as? Reminder, reminder.isTodo else { return nil }
        return AnyView(ReminderLeadingSwipe(reminderId: reminder.id, isCompleted: reminder.isCompleted))
    }
}

// MARK: - Swipe action views

/// Swipe left → "Tomorrow" + "Delete" buttons
private struct ReminderTrailingSwipe: View {
    let reminderId: Int
    @Environment(FeedStore.self) private var feedStore
    @Environment(MealStore.self) private var mealStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(WorkoutStore.self) private var workoutStore

    private var tomorrow: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
    }

    var body: some View {
        Button(role: .destructive) {
            Task {
                let _: ReminderDeleteResponse? = try? await feedStore.api.delete("/api/reminders/\(reminderId)")
                feedStore.feedItems.removeAll { $0.id == "reminder-\(reminderId)" }
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }

        Button {
            Task {
                let body = ReminderPushBody(newDate: tomorrow)
                let _: ReminderPushResponse? = try? await feedStore.api.post("/api/reminders/\(reminderId)/push", body: body)
                feedStore.feedItems.removeAll { $0.id == "reminder-\(reminderId)" }
            }
        } label: {
            Label("Tomorrow", systemImage: "arrow.right.circle")
        }
        .tint(.orange)
    }
}

/// Swipe right → "Done"/"Undo" button
private struct ReminderLeadingSwipe: View {
    let reminderId: Int
    let isCompleted: Bool
    @Environment(FeedStore.self) private var feedStore

    var body: some View {
        Button {
            Task {
                let body = ReminderDoneBody(isDone: !isCompleted)
                let _: ReminderDoneResponse? = try? await feedStore.api.post("/api/reminders/\(reminderId)/done", body: body)
                await feedStore.refreshTodayQuick()
            }
        } label: {
            if isCompleted {
                Label("Undo", systemImage: "arrow.uturn.backward")
            } else {
                Label("Done", systemImage: "checkmark.circle")
            }
        }
        .tint(.green)
    }
}
