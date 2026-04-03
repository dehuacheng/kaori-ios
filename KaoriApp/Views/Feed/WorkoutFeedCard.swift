import SwiftUI

struct WorkoutFeedCard: View {
    let workout: Workout
    var displayTime: String?
    @Environment(Localizer.self) private var L

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(L.t("activity.\(workout.activityType ?? "workout")"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Spacer()
                if let time = displayTime {
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                if let dur = workout.durationMinutes, dur > 0 {
                    Text("\(Int(dur)) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let count = workout.exerciseCount, count > 0 {
                    Text(L.t("workout.exerciseCount", count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let cal = workout.caloriesBurned, cal > 0 {
                    Text("\(Int(cal)) kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let summary = workout.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .feedCard()
    }
}
