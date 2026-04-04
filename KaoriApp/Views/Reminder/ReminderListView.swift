import SwiftUI

struct ReminderListView: View {
    @Environment(ReminderStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var showCreate = false

    private var activeReminders: [Reminder] {
        store.reminders.filter { !$0.isCompleted }
    }

    private var completedReminders: [Reminder] {
        store.reminders.filter { $0.isCompleted }
    }

    var body: some View {
        List {
            if store.reminders.isEmpty && !store.isLoading {
                Section {
                    Text(L.t("reminder.noReminders"))
                        .foregroundStyle(.secondary)
                }
            }

            if !activeReminders.isEmpty {
                Section(L.t("reminder.active")) {
                    ForEach(activeReminders) { reminder in
                        NavigationLink {
                            ReminderDetailView(reminder: reminder)
                        } label: {
                            reminderRow(reminder)
                        }
                    }
                }
            }

            if !completedReminders.isEmpty {
                Section(L.t("reminder.completed")) {
                    ForEach(completedReminders) { reminder in
                        NavigationLink {
                            ReminderDetailView(reminder: reminder)
                        } label: {
                            reminderRow(reminder)
                        }
                    }
                }
            }
        }
        .navigationTitle(L.t("reminder.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate, onDismiss: {
            Task { await store.load(force: true) }
        }) {
            ReminderCreateView()
        }
        .refreshable {
            await store.load(force: true)
        }
        .task {
            await store.load()
        }
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        HStack(spacing: 10) {
            if reminder.isTodo {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            } else {
                Image(systemName: "bell.fill")
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(reminder.title)
                    .font(.subheadline)
                    .strikethrough(reminder.isCompleted)
                HStack(spacing: 4) {
                    Text(reminder.dueDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if reminder.isOverdue {
                        Text("overdue")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                    if reminder.priority == 2 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}
