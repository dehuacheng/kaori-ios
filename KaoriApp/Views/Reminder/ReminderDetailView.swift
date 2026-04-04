import SwiftUI

struct ReminderDetailView: View {
    let reminder: Reminder
    @Environment(ReminderStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var showPushSheet = false
    @State private var pushDate = Date()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(reminder.title)
                            .font(.title3.bold())
                            .strikethrough(reminder.isCompleted)
                        if reminder.isOverdue {
                            Text("overdue")
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red, in: Capsule())
                        }
                    }

                    if let desc = reminder.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(L.t("reminder.details")) {
                LabeledContent(L.t("reminder.dueDate"), value: reminder.dueDate)
                if reminder.dueDate != reminder.originalDate {
                    LabeledContent(L.t("reminder.originalDate"), value: reminder.originalDate)
                }
                LabeledContent(L.t("reminder.type"), value: reminder.isTodo ? L.t("reminder.typeTodo") : L.t("reminder.typeReminder"))
                LabeledContent(L.t("reminder.priority"), value: priorityLabel)
            }

            if reminder.isTodo {
                Section(L.t("reminder.actions")) {
                    Button {
                        Task {
                            try? await store.markDone(id: reminder.id, isDone: !reminder.isCompleted)
                            dismiss()
                        }
                    } label: {
                        Label(
                            reminder.isCompleted ? L.t("reminder.markUndone") : L.t("reminder.markDone"),
                            systemImage: reminder.isCompleted ? "arrow.uturn.backward" : "checkmark.circle"
                        )
                    }
                }
            }

            Section {
                Button {
                    pushDate = Date()
                    showPushSheet = true
                } label: {
                    Label(L.t("reminder.pushToLater"), systemImage: "calendar.badge.clock")
                }
            }
        }
        .navigationTitle(reminder.isTodo ? L.t("reminder.todoDetail") : L.t("reminder.reminderDetail"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(L.t("common.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(L.t("reminder.deleteReminder"), isPresented: $showDeleteConfirm) {
            Button(L.t("common.delete"), role: .destructive) {
                Task {
                    try? await store.delete(id: reminder.id)
                    dismiss()
                }
            }
            Button(L.t("common.cancel"), role: .cancel) {}
        }
        .sheet(isPresented: $showPushSheet) {
            NavigationStack {
                Form {
                    DatePicker(L.t("reminder.newDate"), selection: $pushDate, displayedComponents: .date)
                }
                .navigationTitle(L.t("reminder.pushToLater"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L.t("common.cancel")) { showPushSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L.t("common.save")) {
                            Task {
                                try? await store.push(id: reminder.id, newDate: dateFormatter.string(from: pushDate))
                                showPushSheet = false
                                dismiss()
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private var priorityLabel: String {
        switch reminder.priority {
        case 0: return L.t("reminder.priorityLow")
        case 2: return L.t("reminder.priorityHigh")
        default: return L.t("reminder.priorityNormal")
        }
    }
}
