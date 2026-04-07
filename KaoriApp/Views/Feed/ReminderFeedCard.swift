import SwiftUI

struct ReminderFeedCard: View {
    let reminder: Reminder
    @Environment(Localizer.self) private var L

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            if reminder.isTodo {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(reminder.isCompleted ? .green : .secondary)
            } else {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reminder.title)
                        .font(.subheadline.bold())
                        .strikethrough(reminder.isCompleted)
                        .foregroundStyle(reminder.isCompleted ? .secondary : .primary)

                    if reminder.isOverdue {
                        Text(L.t("reminder.overdue"))
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red, in: Capsule())
                    }

                    if reminder.priority == 2 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                if let desc = reminder.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if reminder.dueDate != reminder.originalDate {
                    Text(L.t("reminder.fromDate", reminder.originalDate))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .feedCard()
    }
}
