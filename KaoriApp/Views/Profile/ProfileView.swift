import SwiftUI

struct ProfileView: View {
    @Environment(ProfileStore.self) private var store
    @State private var isEditing = false
    @State private var draft = ProfileUpdate()
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        Group {
            if let profile = store.profile {
                List {
                    if !isEditing {
                        readOnlyView(profile)
                    } else {
                        editView(profile)
                    }
                }
            } else if store.isLoading {
                ProgressView()
            } else {
                ContentUnavailableView("No Profile", systemImage: "person.crop.circle")
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                } else {
                    Button("Edit") { startEditing() }
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isEditing = false }
                }
            }
        }
        .refreshable {
            await store.load()
        }
        .task {
            await store.load()
        }
    }

    private func readOnlyView(_ profile: Profile) -> some View {
        Group {
            Section("Personal") {
                row("Name", profile.displayName ?? "—")
                row("Height", profile.heightCm.map { "\(Int($0)) cm" } ?? "—")
                row("Gender", profile.gender?.capitalized ?? "—")
                row("Birth Date", profile.birthDate ?? "—")
                if let age = profile.age {
                    row("Age", "\(age)")
                }
            }

            Section("Nutrition Settings") {
                row("Protein", profile.proteinPerKg.map { "\($0) g/kg" } ?? "—")
                row("Carbs", profile.carbsPerKg.map { "\($0) g/kg" } ?? "—")
                row("Calorie Adj.", profile.calorieAdjustmentPct.map { "\($0 >= 0 ? "+" : "")\($0)%" } ?? "—")
            }

            Section("Computed Targets") {
                if let weight = profile.latestWeightKg {
                    row("Current Weight", String(format: "%.1f kg", weight))
                }
                if let bmr = profile.bmr {
                    row("BMR", "\(bmr) kcal")
                }
                if let tdee = profile.estimatedTdee {
                    row("Est. TDEE", "\(tdee) kcal")
                }
                if let cal = profile.targetCalories {
                    row("Target Calories", "\(cal) kcal")
                }
                if let p = profile.targetProteinG {
                    row("Target Protein", "\(p) g")
                }
                if let c = profile.targetCarbsG {
                    row("Target Carbs", "\(c) g")
                }
            }

            if let notes = profile.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .font(.subheadline)
                }
            }
        }
    }

    private func editView(_ profile: Profile) -> some View {
        Group {
            Section("Personal") {
                TextField("Name", text: binding(\.displayName, default: ""))
                HStack {
                    Text("Height (cm)")
                    Spacer()
                    TextField("cm", value: binding(\.heightCm), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Picker("Gender", selection: binding(\.gender, default: "")) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                    Text("Other").tag("other")
                }
                TextField("Birth Date (YYYY-MM-DD)", text: binding(\.birthDate, default: ""))
                    .keyboardType(.numbersAndPunctuation)
            }

            Section("Nutrition Settings") {
                HStack {
                    Text("Protein (g/kg)")
                    Spacer()
                    TextField("g/kg", value: binding(\.proteinPerKg), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("Carbs (g/kg)")
                    Spacer()
                    TextField("g/kg", value: binding(\.carbsPerKg), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("Calorie Adj. (%)")
                    Spacer()
                    TextField("%", value: binding(\.calorieAdjustmentPct), format: .number)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section("Notes (LLM Context)") {
                TextField("Free-form notes for AI context", text: binding(\.notes, default: ""), axis: .vertical)
                    .lineLimit(3...6)
            }

            if let error {
                Section {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func startEditing() {
        guard let p = store.profile else { return }
        draft = ProfileUpdate(
            displayName: p.displayName,
            heightCm: p.heightCm,
            gender: p.gender,
            birthDate: p.birthDate,
            proteinPerKg: p.proteinPerKg,
            carbsPerKg: p.carbsPerKg,
            calorieAdjustmentPct: p.calorieAdjustmentPct,
            notes: p.notes
        )
        isEditing = true
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            try await store.update(draft)
            isEditing = false
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    // Binding helpers for draft fields
    private func binding(_ keyPath: WritableKeyPath<ProfileUpdate, String?>, default defaultValue: String) -> Binding<String> {
        Binding(
            get: { draft[keyPath: keyPath] ?? defaultValue },
            set: { draft[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func binding(_ keyPath: WritableKeyPath<ProfileUpdate, Double?>) -> Binding<Double?> {
        Binding(
            get: { draft[keyPath: keyPath] },
            set: { draft[keyPath: keyPath] = $0 }
        )
    }
}
