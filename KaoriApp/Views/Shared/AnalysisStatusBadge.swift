import SwiftUI

struct AnalysisStatusBadge: View {
    let status: String?
    let isEstimated: Int?
    @Environment(Localizer.self) private var L

    var body: some View {
        switch status {
        case "pending", "analyzing":
            Label(L.t("shared.analyzing"), systemImage: "sparkles")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.yellow.opacity(0.2))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case "failed":
            Label(L.t("shared.failed"), systemImage: "exclamationmark.triangle")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        default:
            if isEstimated == 1 {
                Label(L.t("shared.ai"), systemImage: "sparkles")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            } else if isEstimated == 0 {
                Label(L.t("shared.manual"), systemImage: "pencil")
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
