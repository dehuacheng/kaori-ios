import Foundation

/// Manages card type enable/disable preferences via the backend API.
@Observable
class CardPreferenceStore {
    var preferences: [CardPreferenceItem] = []
    var isLoading = false

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    /// Whether a specific card type is enabled.
    func isEnabled(_ cardType: String) -> Bool {
        preferences.first { $0.cardType == cardType }?.enabled ?? true
    }

    /// Load all card preferences from backend.
    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            preferences = try await api.get("/api/feed/card-preferences")
        } catch {
            // On failure, assume all enabled
        }
    }

    /// Toggle a card type on/off.
    func toggle(_ cardType: String, enabled: Bool) async {
        // Optimistic update
        if let idx = preferences.firstIndex(where: { $0.cardType == cardType }) {
            preferences[idx].enabled = enabled
        }
        do {
            let _: CardPreferenceItem = try await api.put(
                "/api/feed/card-preferences/\(cardType)",
                body: CardPreferenceUpdate(enabled: enabled)
            )
        } catch {
            // Revert on failure
            if let idx = preferences.firstIndex(where: { $0.cardType == cardType }) {
                preferences[idx].enabled = !enabled
            }
        }
    }
}

struct CardPreferenceItem: Codable, Identifiable {
    let id: Int
    var cardType: String
    var enabled: Bool
    var pinned: Bool
    var pinOrder: Int
    var updatedAt: String?
}

private struct CardPreferenceUpdate: Codable {
    let enabled: Bool
}
