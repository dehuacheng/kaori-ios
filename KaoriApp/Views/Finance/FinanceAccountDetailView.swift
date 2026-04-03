import SwiftUI
import PhotosUI

struct FinanceAccountDetailView: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore

    let account: FinancialAccount
    @State private var holdings: [PortfolioHolding] = []
    @State private var isLoading = true
    @State private var showAddHolding = false
    @State private var showImport = false

    var body: some View {
        List {
            Section(L.t("finance.holdings")) {
                if holdings.isEmpty && !isLoading {
                    Text(L.t("finance.noHoldings"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(holdings) { holding in
                        HStack {
                            Text(holding.ticker)
                                .font(.body.bold().monospaced())
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.2f shares", holding.shares))
                                    .font(.caption)
                                if let cost = holding.costBasis {
                                    Text(String(format: "$%.2f avg", cost))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            for idx in offsets {
                                try? await financeStore.deleteHolding(holdings[idx].id)
                            }
                            holdings = (try? await financeStore.getHoldings(accountId: account.id)) ?? []
                        }
                    }
                }
            }

            Section(L.t("finance.actions")) {
                Button {
                    showImport = true
                } label: {
                    Label(L.t("finance.importHoldings"), systemImage: "camera.viewfinder")
                }
                Button {
                    showAddHolding = true
                } label: {
                    Label(L.t("finance.addHolding"), systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(account.name)
        .sheet(isPresented: $showAddHolding, onDismiss: { Task { await reload() } }) {
            AddHoldingSheet(accountId: account.id)
        }
        .sheet(isPresented: $showImport, onDismiss: { Task { await reload() } }) {
            HoldingsImportView(account: account)
        }
        .task { await reload() }
    }

    private func reload() async {
        isLoading = true
        holdings = (try? await financeStore.getHoldings(accountId: account.id)) ?? []
        isLoading = false
    }
}

struct AddHoldingSheet: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore
    @Environment(\.dismiss) private var dismiss

    let accountId: Int
    @State private var ticker = ""
    @State private var shares = ""
    @State private var costBasis = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(L.t("finance.ticker"), text: $ticker)
                    .textInputAutocapitalization(.characters)
                TextField(L.t("finance.shares"), text: $shares)
                    .keyboardType(.decimalPad)
                TextField(L.t("finance.costBasis"), text: $costBasis)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle(L.t("finance.addHolding"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task {
                            guard let sharesNum = Double(shares) else { return }
                            let cost = Double(costBasis)
                            _ = try? await financeStore.createHolding(
                                accountId: accountId,
                                ticker: ticker,
                                shares: sharesNum,
                                costBasis: cost
                            )
                            dismiss()
                        }
                    }
                    .disabled(ticker.isEmpty || shares.isEmpty)
                }
            }
        }
    }
}
