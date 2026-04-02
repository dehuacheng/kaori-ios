import SwiftUI

struct ExercisePickerView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    let workoutId: Int
    let exerciseCount: Int

    @State private var searchText = ""

    private var grouped: [(String, [ExerciseType])] {
        let filtered = searchText.isEmpty
            ? store.exerciseTypes
            : store.exerciseTypes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        let dict = Dictionary(grouping: filtered) { $0.category ?? "other" }
        let order = ["chest", "back", "legs", "shoulders", "arms", "core", "cardio", "full_body", "other"]
        return order.compactMap { cat in
            guard let types = dict[cat], !types.isEmpty else { return nil }
            return (cat, types)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, types in
                    Section(L.t("exerciseCategory.\(category)")) {
                        ForEach(types) { et in
                            Button {
                                Task { await selectExercise(et) }
                            } label: {
                                HStack {
                                    Text(categoryIcon(et.category))
                                        .frame(width: 28)
                                    Text(et.name)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: L.t("exercise.searchExercises"))
            .navigationTitle(L.t("exercise.addExercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
            }
            .task {
                await store.loadExerciseTypes()
            }
        }
    }

    private func selectExercise(_ et: ExerciseType) async {
        _ = try? await store.addExercise(
            workoutId: workoutId,
            exerciseTypeId: et.id,
            orderIndex: exerciseCount
        )
        dismiss()
    }

    private func categoryIcon(_ cat: String?) -> String {
        switch cat {
        case "chest": "🏋️"
        case "back": "🔙"
        case "legs": "🦵"
        case "shoulders", "arms": "💪"
        case "core": "🎯"
        case "cardio": "🏃"
        case "full_body": "🏋️"
        default: "📋"
        }
    }
}
