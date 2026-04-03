import SwiftUI

struct FinanceAccountListView: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore
    @State private var showAddSheet = false

    var body: some View {
        List {
            if financeStore.accounts.isEmpty && !financeStore.isLoading {
                ContentUnavailableView(
                    L.t("finance.noAccounts"),
                    systemImage: "chart.pie",
                    description: Text(L.t("finance.noAccountsHint"))
                )
            }

            let brokerageAccounts = financeStore.accounts.filter { $0.accountType == "brokerage" }
            if !brokerageAccounts.isEmpty {
                Section(L.t("finance.brokerage")) {
                    ForEach(brokerageAccounts) { account in
                        NavigationLink {
                            FinanceAccountDetailView(account: account)
                        } label: {
                            accountRow(account)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            for idx in offsets {
                                try? await financeStore.deleteAccount(brokerageAccounts[idx].id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L.t("finance.title"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            Task { await financeStore.loadAccounts() }
        }) {
            AddAccountSheet()
        }
        .task {
            await financeStore.loadAccounts()
        }
    }

    private func accountRow(_ account: FinancialAccount) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.body)
                Text(account.institution.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let count = account.holdingsCount {
                Text("\(count) " + L.t("finance.holdings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AddAccountSheet: View {
    @Environment(Localizer.self) private var L
    @Environment(FinanceStore.self) private var financeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var institution = "schwab"

    private let institutions = [
        ("schwab", "Charles Schwab"),
        ("fidelity", "Fidelity"),
        ("moomoo", "Moomoo"),
        ("other", "Other"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField(L.t("finance.accountName"), text: $name)
                Picker(L.t("finance.institution"), selection: $institution) {
                    ForEach(institutions, id: \.0) { key, label in
                        Text(label).tag(key)
                    }
                }
            }
            .navigationTitle(L.t("finance.addAccount"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.t("common.save")) {
                        Task {
                            _ = try? await financeStore.createAccount(
                                name: name, institution: institution
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
