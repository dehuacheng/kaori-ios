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

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let reminder = try? context.decoder.decode(Reminder.self, from: rawData) else {
            return nil
        }
        return .reminder(reminder)
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let reminder = item.payload as? Reminder else { return }
        let _: ReminderDeleteResponse? = try? await context.api.delete("/api/reminders/\(reminder.id)")
    }
}

// MARK: - Swipe action views

/// Swipe left → "Tomorrow" + "Delete" buttons
private struct ReminderTrailingSwipe: View {
    let reminderId: Int
    @Environment(Localizer.self) private var L
    @Environment(FeedStore.self) private var feedStore

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
            Label(L.t("common.delete"), systemImage: "trash")
        }

        Button {
            Task {
                let body = ReminderPushBody(newDate: tomorrow)
                let _: ReminderPushResponse? = try? await feedStore.api.post("/api/reminders/\(reminderId)/push", body: body)
                feedStore.feedItems.removeAll { $0.id == "reminder-\(reminderId)" }
            }
        } label: {
            Label(L.t("feed.tomorrow"), systemImage: "arrow.right.circle")
        }
        .tint(.orange)
    }
}

/// Swipe right → "Done"/"Undo" button
private struct ReminderLeadingSwipe: View {
    let reminderId: Int
    let isCompleted: Bool
    @Environment(Localizer.self) private var L
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
                Label(L.t("reminder.markUndone"), systemImage: "arrow.uturn.backward")
            } else {
                Label(L.t("reminder.markDone"), systemImage: "checkmark.circle")
            }
        }
        .tint(.green)
    }
}
