import SwiftUI

struct SetRowView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(Localizer.self) private var L
    let exerciseSet: ExerciseSet
    let workoutId: Int
    let exerciseId: Int
    let onUpdate: () async -> Void
    var startInEditMode: Bool = false

    @State private var isEditing = false
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var duration: String = ""

    var body: some View {
        if isEditing {
            editView
        } else {
            displayView
        }
    }

    init(exerciseSet: ExerciseSet, workoutId: Int, exerciseId: Int, startInEditMode: Bool = false, onUpdate: @escaping () async -> Void) {
        self.exerciseSet = exerciseSet
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.onUpdate = onUpdate
        self.startInEditMode = startInEditMode
        _isEditing = State(initialValue: startInEditMode)
        if startInEditMode {
            _reps = State(initialValue: exerciseSet.reps.map(String.init) ?? "")
            _weight = State(initialValue: exerciseSet.weightKg.map { String(format: "%.1f", $0) } ?? "")
            _duration = State(initialValue: exerciseSet.durationSeconds.map(String.init) ?? "")
        }
    }

    private var displayView: some View {
        HStack {
            Text(L.t("set.setNumber", exerciseSet.setNumber))
                .font(.subheadline.bold())
                .frame(width: 50, alignment: .leading)

            if let r = exerciseSet.reps {
                Text("\(r) reps")
                    .font(.subheadline)
            }
            if let w = exerciseSet.weightKg {
                Text("@ \(w, specifier: "%.1f") kg")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let d = exerciseSet.durationSeconds {
                Text("\(d)s")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                reps = exerciseSet.reps.map(String.init) ?? ""
                weight = exerciseSet.weightKg.map { String(format: "%.1f", $0) } ?? ""
                duration = exerciseSet.durationSeconds.map(String.init) ?? ""
                isEditing = true
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var editView: some View {
        HStack(spacing: 8) {
            Text("\(exerciseSet.setNumber)")
                .font(.subheadline.bold())
                .frame(width: 24)

            TextField(L.t("set.reps"), text: $reps)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)

            TextField(L.t("set.kg"), text: $weight)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)

            TextField(L.t("set.sec"), text: $duration)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)

            Button {
                Task { await saveEdit() }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)

            Button {
                isEditing = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
    }

    private func saveEdit() async {
        let body = SetUpdate(
            reps: Int(reps),
            weightKg: Double(weight),
            durationSeconds: Int(duration),
            notes: nil
        )
        try? await store.updateSet(
            workoutId: workoutId,
            exerciseId: exerciseId,
            setId: exerciseSet.id,
            body: body
        )
        isEditing = false
        await onUpdate()
    }
}
