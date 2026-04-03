import SwiftUI

struct WorkoutDetailView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(APIClient.self) private var api
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    let workoutId: Int

    @State private var workout: WorkoutDetail?
    @State private var analysis: WorkoutAnalysis?
    @State private var isLoading = true
    @State private var showExercisePicker = false
    @State private var showTimer = false
    @State private var isSummarizing = false
    @State private var workoutStartTime = Date()
    @State private var newlyAddedSetIds: Set<Int> = []
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if let workout {
                workoutContent(workout)
            } else if isLoading {
                ProgressView(L.t("workout.loading"))
            } else {
                Text(L.t("workout.notFound"))
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L.t("workout.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let workout, !workout.exercises.isEmpty {
                        Button {
                            Task { await finishWorkout() }
                        } label: {
                            Label(L.t("workout.finishSummarize"), systemImage: "checkmark.circle")
                        }
                        .disabled(isSummarizing)
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(L.t("workout.deleteWorkout"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert(L.t("workout.deleteWorkout"), isPresented: $showDeleteConfirm) {
            Button(L.t("common.delete"), role: .destructive) {
                Task {
                    try? await store.deleteWorkout(workoutId)
                    await store.loadWorkouts()
                    dismiss()
                }
            }
            Button(L.t("common.cancel"), role: .cancel) {}
        }
        .task { await loadWorkout() }
    }

    @ViewBuilder
    private func workoutContent(_ workout: WorkoutDetail) -> some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                // Summarizing indicator
                if isSummarizing {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text(L.t("workout.analyzingWorkout"))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                }

                // Analysis section
                if let analysis {
                    Section(L.t("workout.aiAnalysis")) {
                        WorkoutAnalysisView(analysis: analysis)
                    }
                }

                // Exercises
                ForEach(workout.exercises) { exercise in
                    Section {
                        ForEach(exercise.sets) { s in
                            SetRowView(
                                exerciseSet: s,
                                workoutId: workout.id,
                                exerciseId: exercise.id,
                                startInEditMode: newlyAddedSetIds.contains(s.id),
                                onUpdate: { await loadWorkout() }
                            )
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    let s = exercise.sets[index]
                                    try? await store.deleteSet(
                                        workoutId: workout.id,
                                        exerciseId: exercise.id,
                                        setId: s.id
                                    )
                                }
                                await loadWorkout()
                            }
                        }

                        Button(L.t("workout.addSet")) {
                            Task { await addSet(to: exercise, in: workout) }
                        }
                        .font(.subheadline)
                    } header: {
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.subheadline.bold())
                            if let cat = exercise.exerciseCategory {
                                Text(cat)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.fill.tertiary)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteExercise(
                                        workoutId: workout.id,
                                        exerciseId: exercise.id
                                    )
                                    await loadWorkout()
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Actions
                Section {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label(L.t("workout.addExercise"), systemImage: "plus.circle")
                    }
                }

            }

            // Floating timer button
            Button {
                showTimer = true
            } label: {
                Image(systemName: "timer")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4, y: 2)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showExercisePicker, onDismiss: {
            Task { await loadWorkout() }
        }) {
            ExercisePickerView(workoutId: workout.id, exerciseCount: workout.exercises.count)
        }
        .sheet(isPresented: $showTimer) {
            TimerView()
        }
    }

    @MainActor
    private func loadWorkout() async {
        do {
            workout = try await store.getWorkout(workoutId)
            analysis = try? await store.getAnalysis(workoutId)
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func addSet(to exercise: WorkoutExercise, in workout: WorkoutDetail) async {
        let nextNumber = (exercise.sets.last?.setNumber ?? 0) + 1
        let body = SetCreate(setNumber: nextNumber, reps: nil, weightKg: nil, durationSeconds: nil, notes: nil)
        if let response = try? await store.addSet(workoutId: workout.id, exerciseId: exercise.id, body: body) {
            newlyAddedSetIds.insert(response.id)
        }
        await loadWorkout()
    }

    @MainActor
    private func finishWorkout() async {
        guard let workout else { return }
        isSummarizing = true
        let endTime = Date()
        let duration = endTime.timeIntervalSince(workoutStartTime) / 60
        let update = WorkoutUpdate(notes: nil, activityType: nil, durationMinutes: duration)
        _ = try? await store.updateWorkout(workout.id, body: update)
        let summary = try? await store.summarize(workout.id)
        await loadWorkout()
        isSummarizing = false

        // Save to HealthKit
        let activityType = HealthKitManager.workoutActivityType(from: workout.activityType)
        try? await healthKit.saveWorkout(
            activityType: activityType,
            start: workoutStartTime,
            end: endTime,
            calories: summary?.estimatedCalories
        )
    }
}
