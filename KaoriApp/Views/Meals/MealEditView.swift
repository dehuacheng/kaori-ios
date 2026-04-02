import SwiftUI

struct MealEditView: View {
    let meal: Meal
    let onSave: () -> Void
    @Environment(MealStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var description: String
    @State private var notes: String
    @State private var mealType: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var isSubmitting = false
    @State private var error: String?

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

    init(meal: Meal, onSave: @escaping () -> Void) {
        self.meal = meal
        self.onSave = onSave
        _description = State(initialValue: meal.description ?? "")
        _notes = State(initialValue: meal.notes ?? "")
        _mealType = State(initialValue: meal.mealType ?? "snack")
        _calories = State(initialValue: meal.calories.map(String.init) ?? "")
        _protein = State(initialValue: meal.proteinG.map { String(format: "%.1f", $0) } ?? "")
        _carbs = State(initialValue: meal.carbsG.map { String(format: "%.1f", $0) } ?? "")
        _fat = State(initialValue: meal.fatG.map { String(format: "%.1f", $0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Nutrition Override") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("kcal", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("g", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("g", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("g", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await submit() } }
                        .disabled(isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil
        do {
            let body = MealUpdate(
                mealDate: nil,
                mealType: mealType,
                description: description.isEmpty ? nil : description,
                calories: Int(calories),
                proteinG: Double(protein),
                carbsG: Double(carbs),
                fatG: Double(fat),
                notes: notes.isEmpty ? nil : notes
            )
            _ = try await store.updateMeal(meal.id, body: body)
            onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
