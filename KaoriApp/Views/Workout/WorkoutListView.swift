import SwiftUI

struct WorkoutListView: View {
    @Environment(WorkoutStore.self) private var store
    @State private var navigateToWorkout: Int?
    @State private var showTimer = false

    var body: some View {
        @Bindable var store = store

        ZStack(alignment: .bottomTrailing) {
        List {
            Section {
                if store.workouts.isEmpty && !store.isLoading {
                    Text("No workouts")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.workouts) { workout in
                        NavigationLink(value: workout.id) {
                            WorkoutRowView(workout: workout)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteWorkout(workout.id)
                                    await store.loadWorkouts()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(store.currentDateDisplay)
        .navigationDestination(for: Int.self) { workoutId in
            if let meta = WorkoutStore.importedMeta(forWorkoutId: workoutId) {
                ImportedWorkoutDetailView(workoutId: workoutId, meta: meta)
            } else {
                WorkoutDetailView(workoutId: workoutId)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 16) {
                    Button {
                        store.navigateDay(offset: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Button {
                        store.navigateDay(offset: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    if !store.isToday {
                        Button("Today") {
                            store.currentDate = WorkoutStore.todayString()
                        }
                        .font(.caption)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await createWorkout() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await store.loadWorkouts()
        }
        .onChange(of: store.currentDate) {
            Task { await store.loadWorkouts() }
        }
        .task {
            await store.loadWorkouts()
        }
        .sheet(isPresented: $showTimer) {
            TimerView()
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
        } // ZStack
    }

    private func createWorkout() async {
        do {
            let workout = try await store.createWorkout()
            await store.loadWorkouts()
            navigateToWorkout = workout.id
        } catch {
            // Error handled by store
        }
    }
}
