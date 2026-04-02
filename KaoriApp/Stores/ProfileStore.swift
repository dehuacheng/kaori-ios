import Foundation

@Observable
class ProfileStore {
    var profile: Profile?
    var isLoading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func load() async {
        isLoading = true
        error = nil
        do {
            profile = try await api.get("/api/profile")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func update(_ body: ProfileUpdate) async throws {
        let updated: Profile = try await api.put("/api/profile", body: body)
        await MainActor.run { profile = updated }
    }
}
