import SwiftUI

struct WeightCreateView: View {
    @Environment(WeightStore.self) private var store
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(\.dismiss) private var dismiss

    @State private var weightKg = ""
    @State private var weightDate = Date()
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var error: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    DatePicker("Date", selection: $weightDate, displayedComponents: .date)
                    TextField("Weight (kg)", text: $weightKg)
                        .keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await submit() }
                    }
                    .disabled(weightKg.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        guard let kg = Double(weightKg) else {
            error = "Invalid weight"
            return
        }
        isSubmitting = true
        error = nil
        do {
            try await store.log(
                date: dateFormatter.string(from: weightDate),
                weightKg: kg,
                notes: notes.isEmpty ? nil : notes
            )
            // Also save to Apple Health
            if healthKit.isAuthorized {
                try? await healthKit.saveWeight(kg: kg, date: weightDate)
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}
