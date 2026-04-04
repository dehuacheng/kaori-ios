import Foundation

struct DailySummaryResponse: Codable {
    let date: String
    let summary: String?
    let streak: Int
    let totals: DailySummaryTotals
    let mealsLogged: Int
    let workoutsLogged: Int
}

struct DailySummaryTotals: Codable {
    let calories: Int
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
}

struct WeeklyWeightSummaryResponse: Codable {
    let date: String
    let summary: String?
}

struct StreakResponse: Codable {
    let streak: Int
}

struct SummaryDetail: Codable, Identifiable {
    let id: Int
    let type: String
    let date: String
    let summaryText: String
    let llmBackend: String?
    let model: String?
    let createdAt: String?
}

struct SummaryDetailEmpty: Codable {
    let date: String?
    let summaryText: String?
}

struct SummaryDeleteResponse: Codable {
    let id: Int
    let deleted: Bool
}
