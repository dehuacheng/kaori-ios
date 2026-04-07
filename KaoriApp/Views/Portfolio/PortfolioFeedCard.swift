import SwiftUI

struct PortfolioFeedCard: View {
    let summary: PortfolioSummaryResponse
    @Environment(Localizer.self) private var L

    private var combined: PortfolioTotals? { summary.combined }
    private var isGain: Bool { (combined?.dayChange ?? 0) >= 0 }
    private var changeColor: Color { isGain ? .green : .red }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: isGain ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                    .foregroundStyle(changeColor)
                    .font(.body.bold())
                Text(L.t("finance.portfolio"))
                    .font(.subheadline.bold())
                    .foregroundStyle(changeColor)
                Spacer()
                if summary.isLive {
                    CardStateBadge(.live)
                }
            }

            if let combined {
                // Total value + day change
                HStack(alignment: .firstTextBaseline) {
                    Text(formatCurrency(combined.totalValue))
                        .font(.title2.bold())
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatChange(combined.dayChange))
                            .font(.subheadline.bold())
                            .foregroundStyle(changeColor)
                        Text(formatPercent(combined.dayChangePct))
                            .font(.caption)
                            .foregroundStyle(changeColor)
                    }
                }

                // Per-account breakdown (compact)
                if summary.accounts.count > 1 {
                    HStack(spacing: 0) {
                        ForEach(Array(summary.accounts.enumerated()), id: \.element.id) { idx, acct in
                            if idx > 0 {
                                Text(" · ")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Text("\(acct.name) \(formatCompactCurrency(acct.totalValue))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(" (\(formatPercent(acct.dayChangePct)))")
                                .font(.caption2)
                                .foregroundStyle(acct.dayChange >= 0 ? .green : .red)
                        }
                    }
                    .lineLimit(1)
                }

                // Top movers
                if !summary.topMovers.isEmpty {
                    HStack(spacing: 0) {
                        Text(L.t("portfolio.topMoversPrefix"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        ForEach(Array(summary.topMovers.prefix(3).enumerated()), id: \.offset) { idx, mover in
                            if idx > 0 {
                                Text("  ")
                                    .font(.caption2)
                            }
                            Text(mover.ticker)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text(" \(formatPercent(mover.changePct))")
                                .font(.caption2)
                                .foregroundStyle(mover.change >= 0 ? .green : .red)
                        }
                    }
                }
            }
        }
        .feedCard()
    }

    // MARK: - Formatters

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }

    private func formatChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        if abs(value) >= 1_000_000 {
            return String(format: "%@$%.1fM", sign, abs(value) / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%@$%.1fK", sign, abs(value) / 1_000)
        }
        return String(format: "%@$%.0f", sign, value)
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
}
