import SwiftUI

struct TimerView: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(TimerEngine.self) private var engine
    @Environment(Localizer.self) private var L
    @Environment(\.dismiss) private var dismiss
    @State private var showPresetPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Quick preset picker
                if !store.timerPresets.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.timerPresets) { preset in
                                Button {
                                    engine.configure(preset: preset)
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(preset.name)
                                            .font(.caption.bold())
                                        Text("\(preset.restSeconds)s · \(preset.sets)x")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(engine.presetName == preset.name ? Color.orange : Color(.systemGray5))
                                    .foregroundStyle(engine.presetName == preset.name ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Preset label
                if !engine.presetName.isEmpty {
                    Text(engine.presetName)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Phase label
                Text(L.t("timer.phase.\(engine.phase.rawValue.lowercased())"))
                    .font(.title3.bold())
                    .foregroundStyle(phaseColor)

                // Countdown
                ZStack {
                    Circle()
                        .stroke(.fill.tertiary, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: engine.progress)
                    VStack(spacing: 4) {
                        Text(engine.displayTime)
                            .font(.system(size: 64, weight: .bold, design: .monospaced))
                        Text(L.t("timer.setOf", engine.currentSet, engine.totalSets))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 240, height: 240)

                Spacer()

                // Controls
                HStack(spacing: 32) {
                    if engine.phase != .idle && engine.phase != .done {
                        Button {
                            engine.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .frame(width: 56, height: 56)
                                .background(.fill.tertiary)
                                .clipShape(Circle())
                        }
                    }

                    Button {
                        if engine.phase == .idle || engine.phase == .done {
                            if engine.totalSets == 0 {
                                showPresetPicker = true
                            } else {
                                engine.start()
                            }
                        } else if engine.isRunning {
                            engine.pause()
                        } else {
                            engine.resume()
                        }
                    } label: {
                        Image(systemName: controlIcon)
                            .font(.title)
                            .frame(width: 72, height: 72)
                            .background(phaseColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }

                    if engine.phase == .work || engine.phase == .rest {
                        Button {
                            engine.skip()
                        } label: {
                            Image(systemName: "forward.fill")
                                .font(.title2)
                                .frame(width: 56, height: 56)
                                .background(.fill.tertiary)
                                .clipShape(Circle())
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle(L.t("timer.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L.t("timer.stop")) {
                        engine.reset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPresetPicker = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .sheet(isPresented: $showPresetPicker) {
                TimerPresetPickerView { preset in
                    engine.configure(preset: preset)
                    showPresetPicker = false
                }
            }
            .task {
                await store.loadTimerPresets()
            }
        }
    }

    private var controlIcon: String {
        switch engine.phase {
        case .idle, .done: "play.fill"
        default: engine.isRunning ? "pause.fill" : "play.fill"
        }
    }

    private var phaseColor: Color {
        switch engine.phase {
        case .idle: .secondary
        case .work: .orange
        case .rest: .green
        case .done: .blue
        }
    }
}
