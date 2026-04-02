import SwiftUI

struct MealCreateView: View {
    @Environment(MealStore.self) private var store
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
                Section("Photo") {
                    PhotoPickerButton(imageData: $imageData)
                }

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

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || (description.isEmpty && imageData == nil))
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ProgressView("Saving...")
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
