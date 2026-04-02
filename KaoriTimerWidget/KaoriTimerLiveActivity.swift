import ActivityKit
import SwiftUI
import WidgetKit

struct KaoriTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KaoriTimerAttributes.self) { context in
            // Lock screen / StandBy banner
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.phase)
                        .font(.headline)
                        .foregroundStyle(phaseColor(context.state.phase))
                    if !context.attributes.presetName.isEmpty {
                        Text(context.attributes.presetName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if context.state.isPaused {
                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                        .font(.system(.title, design: .monospaced, weight: .bold))
                        .foregroundStyle(phaseColor(context.state.phase))
                        .multilineTextAlignment(.trailing)
                }

                Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.phase, systemImage: phaseIcon(context.state.phase))
                        .font(.subheadline.bold())
                        .foregroundStyle(phaseColor(context.state.phase))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if !context.attributes.presetName.isEmpty {
                            Text(context.attributes.presetName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if context.state.isPaused {
                            Text(formatTime(context.state.remainingSeconds))
                                .font(.system(.title2, design: .monospaced, weight: .bold))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                                .font(.system(.title2, design: .monospaced, weight: .bold))
                                .foregroundStyle(phaseColor(context.state.phase))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: phaseIcon(context.state.phase))
                    .foregroundStyle(phaseColor(context.state.phase))
            } compactTrailing: {
                if context.state.isPaused {
                    Text(formatTime(context.state.remainingSeconds))
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(timerInterval: Date.now...context.state.endTime, countsDown: true)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundStyle(phaseColor(context.state.phase))
                        .multilineTextAlignment(.trailing)
                }
            } minimal: {
                Image(systemName: phaseIcon(context.state.phase))
                    .foregroundStyle(phaseColor(context.state.phase))
            }
        }
    }

    private func phaseColor(_ phase: String) -> Color {
        switch phase {
        case "Work": .orange
        case "Rest": .green
        case "Done": .blue
        default: .secondary
        }
    }

    private func phaseIcon(_ phase: String) -> String {
        switch phase {
        case "Work": "flame.fill"
        case "Rest": "pause.circle.fill"
        case "Done": "checkmark.circle.fill"
        default: "timer"
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
