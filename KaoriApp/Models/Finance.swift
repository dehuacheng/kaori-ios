import Foundation

// MARK: - Portfolio Summary (for feed card)

struct PortfolioSummaryResponse: Codable {
    let date: String
    let isLive: Bool
    let combined: PortfolioTotals?
    let accounts: [AccountSummary]
    let topMovers: [StockMover]
    let lastUpdated: String?
}

struct PortfolioTotals: Codable {
    let totalValue: Double
    let totalCost: Double?
    let dayChange: Double
    let dayChangePct: Double
    let totalGain: Double?
    let totalGainPct: Double?
}

struct AccountSummary: Codable, Identifiable {
    let accountId: Int
    let name: String
    let institution: String
    let totalValue: Double
    let dayChange: Double
    let dayChangePct: Double
    var id: Int { accountId }
}

struct StockMover: Codable {
    let ticker: String
    let changePct: Double
    let change: Double
}

// MARK: - Financial Account

struct FinancialAccount: Codable, Identifiable {
    let id: Int
    let name: String
    let accountType: String
    let institution: String
    let syncMethod: String
    let lastSyncedAt: String?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
    let holdingsCount: Int?
}

struct AccountsResponse: Codable {
    let accounts: [FinancialAccount]
}

struct AccountCreate: Codable {
    let name: String
    let accountType: String
    let institution: String
    let notes: String?
}

struct AccountUpdate: Codable {
    let name: String?
    let notes: String?
}

// MARK: - Holdings

struct PortfolioHolding: Codable, Identifiable {
    let id: Int
    let accountId: Int
    let ticker: String
    let shares: Double
    let costBasis: Double?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?
}

struct HoldingsResponse: Codable {
    let accountId: Int
    let holdings: [PortfolioHolding]
}

struct HoldingCreate: Codable {
    let ticker: String
    let shares: Double
    let costBasis: Double?
    let notes: String?
}

struct HoldingBulkEntry: Codable {
    var ticker: String
    var shares: Double
    var costBasis: Double?
    var description: String?
}

struct HoldingBulkRequest: Codable {
    let holdings: [HoldingBulkEntry]
}

// MARK: - Import Analysis

struct ImportAnalysis: Codable, Identifiable {
    let id: Int
    let accountId: Int
    let importType: String
    let status: String
    let extracted: ExtractedData?
    let extractedJson: String?
    let createdAt: String?
    let completedAt: String?
    let errorMessage: String?
}

struct ImportResponse: Codable {
    let analysisId: Int
    let status: String
}

struct ExtractedData: Codable {
    let positions: [ExtractedPosition]
    let statementDate: String?
    let accountType: String?
    let confidence: String?
}

struct ExtractedPosition: Codable {
    var ticker: String
    var shares: Double?
    var costBasis: Double?
    var marketValue: Double?
    var description: String?
}
