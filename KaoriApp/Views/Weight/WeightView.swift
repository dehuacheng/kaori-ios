import SwiftUI

struct WeightView: View {
    @Environment(WeightStore.self) private var store
    @State private var showCreate = false
    @State private var editingId: Int?
    @State private var editWeight = ""
    @State private var editNotes = ""
    @State private var showOlder = false

    private var oneWeekAgo: String {
        let date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private var recentWeights: [WeightEntry] {
        let cutoff = oneWeekAgo
        return store.weights.filter { $0.date >= cutoff }.reversed()
    }

    private var olderWeights: [WeightEntry] {
        let cutoff = oneWeekAgo
        return store.weights.filter { $0.date < cutoff }.reversed()
    }

    var body: some View {
        List {
            // Stats
            Section("Trends") {
                HStack(spacing: 24) {
                    if let latest = store.latest {
                        StatBox(label: "Latest", value: String(format: "%.1f", latest), unit: "kg")
                    }
                    if let avg = store.avg7d {
                        StatBox(label: "7d Avg", value: String(format: "%.1f", avg), unit: "kg")
                    }
                    if let delta = store.deltaWeek {
                        StatBox(
                            label: "Week",
                            value: String(format: "%+.1f", delta),
                            unit: "kg",
                            color: delta < 0 ? .green : delta > 0 ? .red : .primary
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Chart
            if store.weights.count >= 2 {
                Section("Chart") {
                    WeightChartView(weights: store.weights)
                        .frame(height: 180)
                }
            }

            // History — last 7 days
            Section("This Week") {
                ForEach(recentWeights) { entry in
                    if editingId == entry.id {
                        editRow(entry: entry)
                    } else {
                        weightRow(entry: entry)
                    }
                }
            }

            // Older entries — collapsed by default
            if !olderWeights.isEmpty {
                DisclosureGroup("Older (\(olderWeights.count))", isExpanded: $showOlder) {
                    ForEach(olderWeights) { entry in
                        if editingId == entry.id {
                            editRow(entry: entry)
                        } else {
                            weightRow(entry: entry)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Weight")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
        .sheet(isPresented: $showCreate, onDismiss: {
            Task { await store.load(force: true) }
        }) {
            WeightCreateView()
        }
        .refreshable {
            await store.load(force: true)
        }
        .task {
            await store.load()
        }
    }

    private func weightRow(entry: WeightEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: "%.1f kg", entry.weightKg))
                    .font(.subheadline.bold())
                Text(entry.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let n = entry.notes, !n.isEmpty {
                    Text(n)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                editingId = entry.id
                editWeight = String(format: "%.1f", entry.weightKg)
                editNotes = entry.notes ?? ""
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            Button {
                Task {
                    try? await store.delete(id: entry.id)
                    await store.load(force: true)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    private func editRow(entry: WeightEntry) -> some View {
        VStack(spacing: 8) {
            HStack {
                TextField("kg", text: $editWeight)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $editNotes)
            }
            HStack {
                Button("Cancel") {
                    editingId = nil
                }
                .buttonStyle(.bordered)
                Button("Save") {
                    Task {
                        if let kg = Double(editWeight) {
                            try? await store.update(
                                id: entry.id,
                                weightKg: kg,
                                notes: editNotes.isEmpty ? nil : editNotes
                            )
                            editingId = nil
                            await store.load(force: true)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

}

private struct StatBox: View {
    let label: String
    let value: String
    let unit: String
    var color: Color = .primary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
