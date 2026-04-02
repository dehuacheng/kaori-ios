import SwiftUI

struct ProfileView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(Localizer.self) private var L
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
                ContentUnavailableView(L.t("common.noProfile"), systemImage: "person.crop.circle")
            }
        }
        .navigationTitle(L.t("profile.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button(L.t("common.save")) { Task { await save() } }
                        .disabled(isSaving)
                } else {
                    Button(L.t("common.edit")) { startEditing() }
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L.t("common.cancel")) { isEditing = false }
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
            Section(L.t("profile.personal")) {
                row(L.t("profile.name"), profile.displayName ?? "—")
                row(L.t("profile.height"), profile.heightCm.map { "\(Int($0)) cm" } ?? "—")
                row(L.t("profile.gender"), profile.gender.map { L.t("gender.\($0)") } ?? "—")
                row(L.t("profile.birthDate"), profile.birthDate ?? "—")
                if let age = profile.age {
                    row(L.t("profile.age"), "\(age)")
                }
            }

            Section(L.t("profile.nutritionSettings")) {
                row(L.t("profile.protein"), profile.proteinPerKg.map { "\($0) g/kg" } ?? "—")
                row(L.t("profile.carbs"), profile.carbsPerKg.map { "\($0) g/kg" } ?? "—")
                row(L.t("profile.calorieAdj"), profile.calorieAdjustmentPct.map { "\($0 >= 0 ? "+" : "")\($0)%" } ?? "—")
            }

            Section(L.t("profile.computedTargets")) {
                if let weight = profile.latestWeightKg {
                    row(L.t("profile.currentWeight"), String(format: "%.1f kg", weight))
                }
                if let bmr = profile.bmr {
                    row(L.t("profile.bmr"), "\(bmr) kcal")
                }
                if let tdee = profile.estimatedTdee {
                    row(L.t("profile.estTdee"), "\(tdee) kcal")
                }
                if let cal = profile.targetCalories {
                    row(L.t("profile.targetCalories"), "\(cal) kcal")
                }
                if let p = profile.targetProteinG {
                    row(L.t("profile.targetProtein"), "\(p) g")
                }
                if let c = profile.targetCarbsG {
                    row(L.t("profile.targetCarbs"), "\(c) g")
                }
            }

            if let notes = profile.notes, !notes.isEmpty {
                Section(L.t("profile.notesSection")) {
                    Text(notes)
                        .font(.subheadline)
                }
            }
        }
    }

    private func editView(_ profile: Profile) -> some View {
        Group {
            Section(L.t("profile.personal")) {
                TextField(L.t("profile.name"), text: binding(\.displayName, default: ""))
                HStack {
                    Text(L.t("profile.heightCm"))
                    Spacer()
                    TextField("cm", value: binding(\.heightCm), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                Picker(L.t("profile.gender"), selection: binding(\.gender, default: "")) {
                    Text(L.t("profile.male")).tag("male")
                    Text(L.t("profile.female")).tag("female")
                    Text(L.t("profile.other")).tag("other")
                }
                TextField(L.t("profile.birthDateFormat"), text: binding(\.birthDate, default: ""))
                    .keyboardType(.numbersAndPunctuation)
            }

            Section(L.t("profile.nutritionSettings")) {
                HStack {
                    Text(L.t("profile.proteinGKg"))
                    Spacer()
                    TextField("g/kg", value: binding(\.proteinPerKg), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text(L.t("profile.carbsGKg"))
                    Spacer()
                    TextField("g/kg", value: binding(\.carbsPerKg), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text(L.t("profile.calorieAdjPct"))
                    Spacer()
                    TextField("%", value: binding(\.calorieAdjustmentPct), format: .number)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            Section(L.t("profile.notesLLM")) {
                TextField(L.t("profile.notesPlaceholder"), text: binding(\.notes, default: ""), axis: .vertical)
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
