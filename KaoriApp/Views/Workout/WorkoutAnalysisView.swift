import SwiftUI

struct WorkoutAnalysisView: View {
    @Environment(Localizer.self) private var L
    let analysis: WorkoutAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let summary = analysis.summary {
                Text(summary)
                    .font(.subheadline)
            }

            // Metrics
            HStack(spacing: 0) {
                if let cal = analysis.estimatedCalories {
                    MetricTile(value: "\(Int(cal))", label: L.t("workoutAnalysis.kcal"))
                }
                if let vol = analysis.totalVolumeKg {
                    MetricTile(value: "\(Int(vol))", label: L.t("workoutAnalysis.kgVol"))
                }
                if let sets = analysis.totalSets {
                    MetricTile(value: "\(sets)", label: L.t("workoutAnalysis.sets"))
                }
                if let intensity = analysis.intensity {
                    MetricTile(value: intensity.replacingOccurrences(of: "_", with: " ").capitalized, label: L.t("workoutAnalysis.intensity"))
                }
            }

            // Muscle groups
            if let groups = analysis.muscleGroups, !groups.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(groups, id: \.self) { group in
                        Text(group)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.fill.tertiary)
                            .clipShape(Capsule())
                    }
                }
            }

            // Trainer sections
            if let notes = analysis.trainerNotes, !notes.isEmpty {
                AnalysisSection(title: L.t("workoutAnalysis.trainerNotes"), icon: "figure.strengthtraining.traditional", color: .yellow, text: notes)
            }
            if let progress = analysis.progressNotes, !progress.isEmpty {
                AnalysisSection(title: L.t("workoutAnalysis.progress"), icon: "chart.line.uptrend.xyaxis", color: .green, text: progress)
            }
            if let recs = analysis.recommendations, !recs.isEmpty {
                AnalysisSection(title: L.t("workoutAnalysis.recommendations"), icon: "lightbulb", color: .blue, text: recs)
            }
        }
    }
}

private struct MetricTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AnalysisSection: View {
    let title: String
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quinary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Simple flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
