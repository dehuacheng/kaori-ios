import SwiftUI

struct TimerPresetPickerView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(Localizer.self) private var L
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
                                        Label("\(preset.restSeconds)s \(L.t("timerPreset.rest"))", systemImage: "pause.circle")
                                        if preset.workSeconds > 0 {
                                            Label("\(preset.workSeconds)s \(L.t("timerPreset.work"))", systemImage: "play.circle")
                                        }
                                        Label("\(preset.sets) \(L.t("timerPreset.sets"))", systemImage: "repeat")
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
                                Label(L.t("common.delete"), systemImage: "trash")
                            }
                        }
                    }

                    if store.timerPresets.isEmpty {
                        Text(L.t("timerPreset.noPresets"))
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if showCreate {
                        TextField(L.t("timerPreset.name"), text: $newName)
                        HStack {
                            Text(L.t("timerPreset.restSec"))
                            Spacer()
                            TextField("60", text: $newRest)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        HStack {
                            Text(L.t("timerPreset.workSec"))
                            Spacer()
                            TextField("0", text: $newWork)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        HStack {
                            Text(L.t("timerPreset.sets"))
                            Spacer()
                            TextField("3", text: $newSets)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                        Button(L.t("timerPreset.savePreset")) {
                            Task { await savePreset() }
                        }
                        .disabled(newName.isEmpty)
                    } else {
                        Button {
                            showCreate = true
                        } label: {
                            Label(L.t("timerPreset.createPreset"), systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle(L.t("timerPreset.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
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
