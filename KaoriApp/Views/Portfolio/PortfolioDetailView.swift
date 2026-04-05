import SwiftUI

struct PortfolioDetailView: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore

    let date: String
    @State private var summary: PortfolioSummaryResponse?
    @State private var isLoading = true

    var body: some View {
        List {
            if let summary, let combined = summary.combined {
                Section(L.t("finance.overview")) {
                    HStack {
                        Text(L.t("finance.totalValue"))
                        Spacer()
                        Text(formatCurrency(combined.totalValue))
                            .bold()
                    }
                    HStack {
                        Text(L.t("finance.dayChange"))
                        Spacer()
                        Text(formatChange(combined.dayChange) + " (\(formatPercent(combined.dayChangePct)))")
                            .foregroundStyle(combined.dayChange >= 0 ? .green : .red)
                    }
                    if let gain = combined.totalGain, let gainPct = combined.totalGainPct {
                        HStack {
                            Text(L.t("finance.totalGain"))
                            Spacer()
                            Text(formatChange(gain) + " (\(formatPercent(gainPct)))")
                                .foregroundStyle(gain >= 0 ? .green : .red)
                        }
                    }
                }

                if summary.accounts.count > 1 {
                    Section(L.t("finance.accounts")) {
                        ForEach(summary.accounts) { acct in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acct.name)
                                        .font(.body)
                                    Text(acct.institution.capitalized)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatCurrency(acct.totalValue))
                                        .font(.body)
                                    Text(formatChange(acct.dayChange) + " (\(formatPercent(acct.dayChangePct)))")
                                        .font(.caption)
                                        .foregroundStyle(acct.dayChange >= 0 ? .green : .red)
                                }
                            }
                        }
                    }
                }

                if !summary.topMovers.isEmpty {
                    Section(L.t("finance.topMovers")) {
                        ForEach(Array(summary.topMovers.enumerated()), id: \.offset) { _, mover in
                            HStack {
                                Text(mover.ticker)
                                    .font(.body.bold().monospaced())
                                Spacer()
                                Text(formatChange(mover.change))
                                    .foregroundStyle(mover.change >= 0 ? .green : .red)
                                Text(formatPercent(mover.changePct))
                                    .font(.caption)
                                    .foregroundStyle(mover.change >= 0 ? .green : .red)
                            }
                        }
                    }
                }
            } else if isLoading {
                FullViewLoading(message: L.t("shared.loading"))
            }
        }
        .navigationTitle(L.t("finance.portfolio"))
        .task {
            isLoading = true
            summary = try? await financeStore.getPortfolioSummary(date: date)
            isLoading = false
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formatChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@$%.0f", sign, value)
    }

    private func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.1f%%", sign, value)
    }
}
