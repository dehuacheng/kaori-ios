import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    /// Display name in the language's own script (so users can always find their language)
    var displayName: String {
        switch self {
        case .english: "English"
        case .chinese: "简体中文"
        }
    }
}
