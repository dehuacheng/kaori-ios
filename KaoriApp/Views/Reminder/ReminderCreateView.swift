import SwiftUI

struct ReminderCreateView: View {
    @Environment(ReminderStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var itemType = "todo"
    @State private var priority = 1
    @State private var isSubmitting = false
    @State private var error: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section(L.t("reminder.details")) {
                    TextField(L.t("reminder.titleField"), text: $title)
                    TextField(L.t("reminder.descriptionOptional"), text: $description)
                }

                Section {
                    DatePicker(L.t("reminder.dueDate"), selection: $dueDate, displayedComponents: .date)

                    Picker(L.t("reminder.type"), selection: $itemType) {
                        Text(L.t("reminder.typeTodo")).tag("todo")
                        Text(L.t("reminder.typeReminder")).tag("reminder")
                    }

                    Picker(L.t("reminder.priority"), selection: $priority) {
                        Text(L.t("reminder.priorityLow")).tag(0)
                        Text(L.t("reminder.priorityNormal")).tag(1)
                        Text(L.t("reminder.priorityHigh")).tag(2)
                    }
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L.t("reminder.newReminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task { await submit() }
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil
        do {
            try await store.create(
                title: title,
                description: description.isEmpty ? nil : description,
                dueDate: dateFormatter.string(from: dueDate),
                itemType: itemType,
                priority: priority
            )
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
