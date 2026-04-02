import SwiftUI

struct WeightCreateView: View {
    @Environment(WeightStore.self) private var store
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(Localizer.self) private var L
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
                Section(L.t("weight.title")) {
                    DatePicker(L.t("weight.date"), selection: $weightDate, displayedComponents: .date)
                    TextField(L.t("weight.weightKg"), text: $weightKg)
                        .keyboardType(.decimalPad)
                    TextField(L.t("weight.notesOptional"), text: $notes)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle(L.t("weight.logWeight"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task { await submit() }
                    }
                    .disabled(weightKg.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() async {
        guard let kg = Double(weightKg) else {
            error = L.t("weight.invalidWeight")
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
