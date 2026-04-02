import SwiftUI

struct TimerPresetPickerView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let onSelect: (TimerPreset) -> Void

    @State private var showCreate = false
    @State private var newName = ""
    @State private var newRest = "60"
    @State private var newWork = "0"
    @State private var newSets = "3"

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.timerPresets) { preset in
                        Button {
                            onSelect(preset)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 8) {
                                        Label("\(preset.restSeconds)s rest", systemImage: "pause.circle")
                                        if preset.workSeconds > 0 {
                                            Label("\(preset.workSeconds)s work", systemImage: "play.circle")
                                        }
                                        Label("\(preset.sets) sets", systemImage: "repeat")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    try? await store.deleteTimerPreset(preset.id)
                                    await store.loadTimerPresets()
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    if store.timerPresets.isEmpty {
                        Text("No presets yet")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if showCreate {
                        TextField("Name", text: $newName)
                        HStack {
                            Text("Rest (sec)")
                            Spacer()
                            TextField("60", text: $newRest)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        HStack {
                            Text("Work (sec)")
                            Spacer()
                            TextField("0", text: $newWork)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        HStack {
                            Text("Sets")
                            Spacer()
                            TextField("3", text: $newSets)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        Button("Save Preset") {
                            Task { await savePreset() }
                        }
                        .disabled(newName.isEmpty)
                    } else {
                        Button {
                            showCreate = true
                        } label: {
                            Label("Create Preset", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle("Timer Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await store.loadTimerPresets()
            }
        }
    }

    private func savePreset() async {
        let body = TimerPresetCreate(
            name: newName,
            restSeconds: Int(newRest) ?? 60,
            workSeconds: Int(newWork) ?? 0,
            sets: Int(newSets) ?? 3,
            notes: nil
        )
        _ = try? await store.createTimerPreset(body: body)
        await store.loadTimerPresets()
        newName = ""
        showCreate = false
    }
}
