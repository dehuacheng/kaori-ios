import Foundation

@Observable
class FinanceStore {
    var accounts: [FinancialAccount] = []
    var isLoading = false

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func loadAccounts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: AccountsResponse = try await api.get("/api/finance/accounts")
            accounts = response.accounts
        } catch {
            accounts = []
        }
    }

    func loadAccountsQuick() async throws -> [FinancialAccount] {
        let response: AccountsResponse = try await api.get("/api/finance/accounts", query: ["type": "brokerage"])
        return response.accounts
    }

    func createAccount(name: String, accountType: String = "brokerage", institution: String, notes: String? = nil) async throws -> FinancialAccount {
        let body = AccountCreate(name: name, accountType: accountType, institution: institution, notes: notes)
        let account: FinancialAccount = try await api.post("/api/finance/accounts", body: body)
        await loadAccounts()
        return account
    }

    func deleteAccount(_ id: Int) async throws {
        let _: [String: Bool] = try await api.delete("/api/finance/accounts/\(id)")
        await loadAccounts()
    }

    func getHoldings(accountId: Int) async throws -> [PortfolioHolding] {
        let response: HoldingsResponse = try await api.get("/api/finance/accounts/\(accountId)/holdings")
        return response.holdings
    }

    func createHolding(accountId: Int, ticker: String, shares: Double, costBasis: Double? = nil) async throws -> PortfolioHolding {
        let body = HoldingCreate(ticker: ticker, shares: shares, costBasis: costBasis, notes: nil)
        return try await api.post("/api/finance/accounts/\(accountId)/holdings", body: body)
    }

    func deleteHolding(_ id: Int) async throws {
        let _: [String: Bool] = try await api.delete("/api/finance/holdings/\(id)")
    }

    func bulkReplaceHoldings(accountId: Int, holdings: [HoldingBulkEntry]) async throws {
        let body = HoldingBulkRequest(holdings: holdings)
        let _: [String: Int] = try await api.post("/api/finance/accounts/\(accountId)/holdings/bulk", body: body)
    }

    func getPortfolioSummary(date: String) async throws -> PortfolioSummaryResponse {
        return try await api.get("/api/finance/portfolio/summary", query: ["date": date])
    }

    func refreshPrices() async throws {
        let _: [String: Int] = try await api.post("/api/finance/portfolio/refresh-prices", query: [:])
    }

    func uploadImport(accountId: Int, images: [Data]) async throws -> ImportResponse {
        let files = images.enumerated().map { idx, data in
            (data: data, fieldName: "files", filename: "screenshot_\(idx).jpg", mimeType: "image/jpeg")
        }
        return try await api.postMultipartFiles(
            "/api/finance/accounts/\(accountId)/import",
            files: files
        )
    }

    func getImportAnalysis(_ analysisId: Int) async throws -> ImportAnalysis {
        return try await api.get("/api/finance/imports/\(analysisId)")
    }

    func confirmImport(analysisId: Int, holdings: [HoldingBulkEntry]) async throws {
        let body = HoldingBulkRequest(holdings: holdings)
        let _: [String: Int] = try await api.post("/api/finance/imports/\(analysisId)/confirm", body: body)
    }
}
