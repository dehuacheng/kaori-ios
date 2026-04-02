import SwiftUI

struct MealCreateView: View {
    @Environment(MealStore.self) private var store
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss

    @State private var description = ""
    @State private var notes = ""
    @State private var mealType = "snack"
    @State private var imageData: Data?
    @State private var isSubmitting = false
    @State private var error: String?

    private let mealTypes = ["breakfast", "lunch", "dinner", "snack"]

    var body: some View {
        NavigationStack {
            Form {
                Section(L.t("meal.photo")) {
                    PhotoPickerButton(imageData: $imageData)
                }

                Section(L.t("meal.details")) {
                    Picker(L.t("meal.mealType"), selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { type in
                            Text(L.t("mealType.\(type)")).tag(type)
                        }
                    }
                    TextField(L.t("meal.description"), text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    TextField(L.t("meal.notes"), text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L.t("meal.logMeal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || (description.isEmpty && imageData == nil))
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ProgressView(L.t("meal.saving"))
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        error = nil

        // Capture values before dismiss
        let desc = description.isEmpty ? nil : description
        let photo = imageData
        let type = mealType
        let n = notes.isEmpty ? nil : notes

        // Dismiss immediately — upload continues in background
        dismiss()

        do {
            _ = try await store.createMeal(
                description: desc, photo: photo, mealType: type, notes: n
            )
            await store.loadMeals()
        } catch {
            // Upload failed after dismiss — store the error for next open
            print("Meal upload failed: \(error)")
        }
    }
}
