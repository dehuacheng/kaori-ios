import SwiftUI

struct ImportedWorkoutDetailView: View {
    let workoutId: Int
    let meta: ImportedWorkoutMeta

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 8) {
                    Image(systemName: activityIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(.orange)
                    Text(meta.activityDisplayName)
                        .font(.title2.bold())
                    Text(meta.startDate, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            // Key metrics grid
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    metricCard(
                        icon: "clock",
                        value: formatDuration(meta.durationSeconds),
                        label: "Duration"
                    )

                    if let cal = meta.caloriesBurned, cal > 0 {
                        metricCard(
                            icon: "flame.fill",
                            value: "\(Int(cal))",
                            label: "Calories",
                            color: .orange
                        )
                    }

                    if let dist = meta.distanceMeters, dist > 0 {
                        metricCard(
                            icon: "location.fill",
                            value: formatDistance(dist),
                            label: "Distance",
                            color: .blue
                        )
                    }

                    if let dist = meta.distanceMeters, dist > 0, meta.durationSeconds > 0 {
                        let paceMinPerKm = (meta.durationSeconds / 60) / (dist / 1000)
                        metricCard(
                            icon: "speedometer",
                            value: formatPace(paceMinPerKm),
                            label: "Avg Pace",
                            color: .green
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            // Time
            Section("Time") {
                HStack {
                    Label("Start", systemImage: "play.circle")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(meta.startDate, style: .time)
                }
                HStack {
                    Label("End", systemImage: "stop.circle")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(meta.endDate, style: .time)
                }
            }

            // Speed (for cycling, running, etc.)
            if let dist = meta.distanceMeters, dist > 0, meta.durationSeconds > 0 {
                Section("Details") {
                    let speedKmh = (dist / 1000) / (meta.durationSeconds / 3600)
                    HStack {
                        Label("Avg Speed", systemImage: "gauge.with.needle")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f km/h", speedKmh))
                    }
                    HStack {
                        Label("Distance", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.0f m", dist))
                    }
                }
            }

            // Source
            Section {
                Label("Imported from Apple Health", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(meta.activityDisplayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Metric Card

    private func metricCard(icon: String, value: String, label: String, color: Color = .primary) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Formatting

    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    private func formatPace(_ minPerKm: Double) -> String {
        let mins = Int(minPerKm)
        let secs = Int((minPerKm - Double(mins)) * 60)
        return String(format: "%d'%02d\"/km", mins, secs)
    }

    private var activityIcon: String {
        switch meta.activityType {
        case "traditionalStrengthTraining": "dumbbell"
        case "functionalStrengthTraining": "figure.strengthtraining.functional"
        case "running": "figure.run"
        case "cycling": "figure.outdoor.cycle"
        case "swimming": "figure.pool.swim"
        case "yoga": "figure.yoga"
        case "pilates": "figure.pilates"
        case "hiking": "figure.hiking"
        case "crossTraining": "figure.cross.training"
        case "highIntensityIntervalTraining": "bolt.heart"
        case "coreTraining": "figure.core.training"
        case "walking": "figure.walk"
        default: "figure.mixed.cardio"
        }
    }
}
