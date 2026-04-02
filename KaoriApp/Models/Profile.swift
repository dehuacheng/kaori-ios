import Foundation

struct Profile: Codable {
    let id: Int
    let displayName: String?
    let heightCm: Double?
    let gender: String?
    let birthDate: String?
    let proteinPerKg: Double?
    let carbsPerKg: Double?
    let calorieAdjustmentPct: Double?
    let llmMode: String?
    let notes: String?
    let updatedAt: String?
    // Computed by server
    let age: Int?
    let latestWeightKg: Double?
    let bmr: Int?
    let estimatedTdee: Int?
    let targetCalories: Int?
    let targetProteinG: Int?
    let targetCarbsG: Int?
}

struct ProfileUpdate: Codable {
    var displayName: String?
    var heightCm: Double?
    var gender: String?
    var birthDate: String?
    var proteinPerKg: Double?
    var carbsPerKg: Double?
    var calorieAdjustmentPct: Double?
    var llmMode: String?
    var notes: String?
}

enum LLMMode: String, CaseIterable, Identifiable {
    case claudeCli = "claude_cli"
    case claudeApi = "claude_api"
    case codexCli = "codex_cli"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .claudeCli: "Claude CLI"
        case .claudeApi: "Claude API"
        case .codexCli: "Codex / ChatGPT"
        }
    }

    var description: String {
        switch self {
        case .claudeCli: "No API key needed"
        case .claudeApi: "Requires ANTHROPIC_API_KEY"
        case .codexCli: "Uses ChatGPT subscription"
        }
    }
}
