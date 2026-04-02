import SwiftUI

struct AnalysisStatusBadge: View {
    let status: String?
    let isEstimated: Int?

    var body: some View {
        switch status {
        case "pending", "analyzing":
            Label("Analyzing", systemImage: "sparkles")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case "failed":
            Label("Failed", systemImage: "exclamationmark.triangle")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        default:
            if isEstimated == 1 {
                Label("AI", systemImage: "sparkles")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            } else if isEstimated == 0 {
                Label("Manual", systemImage: "pencil")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
        }
    }
}
