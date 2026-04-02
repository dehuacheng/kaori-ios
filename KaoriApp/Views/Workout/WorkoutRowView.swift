import SwiftUI

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activityLabel)
                        .font(.subheadline.bold())
                    if let count = workout.exerciseCount, count > 0 {
                        Text("\(count) exercise\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    if let dur = workout.durationMinutes {
                        Label("\(Int(dur)) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let cal = workout.caloriesBurned {
                        Label("\(Int(cal)) kcal", systemImage: "flame")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                if let summary = workout.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var activityLabel: String {
        activityDisplayName(workout.activityType)
    }

    private var iconName: String {
        activityIconName(workout.activityType)
    }
}
