import SwiftUI
import HealthKit

struct WorkoutImportView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State var workouts: [HKWorkout]
    @State var existingWorkouts: [Workout]
    @State private var importingUUID: UUID?
    @State private var importedCount = 0

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                if workouts.isEmpty {
                    Section {
                        Text(L.t("workoutImport.noWorkouts"))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    if importedCount > 0 {
                        Section {
                            Label(L.t("workoutImport.importedCount", importedCount), systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                    }

                    Section {
                        ForEach(workouts, id: \.uuid) { workout in
                            workoutRow(workout)
                                .swipeActions(edge: .trailing) {
                                    if !isDuplicate(workout) {
                                        Button(L.t("workoutImport.skip")) {
                                            skip(workout)
                                        }
                                        .tint(.gray)
                                    }
                                }
                        }
                    } footer: {
                        Text(L.t("workoutImport.footer"))
                    }
                }
            }
            .navigationTitle(L.t("workoutImport.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.t("common.done")) { dismiss() }
                }
            }
        }
    }

    /// Check if an HK workout already exists in the Kaori backend
    private func isDuplicate(_ hkWorkout: HKWorkout) -> Bool {
        let hkDate = dateFormatter.string(from: hkWorkout.startDate)
        let hkActivity = HealthKitManager.activityTypeString(from: hkWorkout.workoutActivityType)
        let hkDuration = hkWorkout.duration / 60

        return existingWorkouts.contains { w in
            w.date == hkDate
            && w.activityType == hkActivity
            && (w.durationMinutes == nil || abs((w.durationMinutes ?? 0) - hkDuration) < 5)
        }
    }

    private func workoutRow(_ workout: HKWorkout) -> some View {
        let dup = isDuplicate(workout)

        return HStack(spacing: 12) {
            Image(systemName: activityIcon(workout.workoutActivityType))
                .font(.title3)
                .foregroundColor(dup ? .gray : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(L.t("activity.\(HealthKitManager.activityTypeString(from: workout.workoutActivityType))"))
                        .font(.subheadline.bold())
                    if dup {
                        Text(L.t("workoutImport.imported"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Text(workout.startDate, style: .date)
                    Text(workout.startDate, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    let minutes = Int(workout.duration / 60)
                    Label("\(minutes) min", systemImage: "clock")

                    if let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()), cal > 0 {
                        Label("\(Int(cal)) kcal", systemImage: "flame")
                    }

                    if let dist = workout.totalDistance?.doubleValue(for: .meter()), dist > 0 {
                        Label(formatDistance(dist), systemImage: "location")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if dup {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if importingUUID == workout.uuid {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(L.t("workoutImport.import")) {
                    Task { await importWorkout(workout) }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
            }
        }
        .opacity(dup ? 0.6 : 1)
        .padding(.vertical, 2)
    }

    private func importWorkout(_ workout: HKWorkout) async {
        importingUUID = workout.uuid
        do {
            try await store.importHealthKitWorkout(workout)
            // Add to existing workouts so the row immediately shows as imported
            let hkDate = dateFormatter.string(from: workout.startDate)
            let activity = HealthKitManager.activityTypeString(from: workout.workoutActivityType)
            let duration = workout.duration / 60
            let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie())
            let stub = Workout(
                id: 0, date: hkDate, notes: nil, activityType: activity,
                durationMinutes: duration, caloriesBurned: cal,
                summary: nil, exerciseCount: nil, source: "healthkit", createdAt: nil
            )
            withAnimation {
                existingWorkouts.append(stub)
                importedCount += 1
            }
        } catch {
            // Failed, leave in list
        }
        importingUUID = nil
    }

    private func skip(_ workout: HKWorkout) {
        store.dismissHealthKitWorkout(workout)
        withAnimation {
            workouts.removeAll { $0.uuid == workout.uuid }
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", meters / 1000)
        }
        return String(format: "%.0f m", meters)
    }

    private func activityIcon(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: "dumbbell"
        case .functionalStrengthTraining: "figure.strengthtraining.functional"
        case .running: "figure.run"
        case .cycling: "figure.outdoor.cycle"
        case .swimming: "figure.pool.swim"
        case .yoga: "figure.yoga"
        case .pilates: "figure.pilates"
        case .hiking: "figure.hiking"
        case .crossTraining: "figure.cross.training"
        case .highIntensityIntervalTraining: "bolt.heart"
        case .coreTraining: "figure.core.training"
        case .walking: "figure.walk"
        case .elliptical: "figure.elliptical"
        case .rowing: "figure.rowing"
        case .flexibility: "figure.flexibility"
        case .dance: "figure.dance"
        default: "figure.mixed.cardio"
        }
    }
}
