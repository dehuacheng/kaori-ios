import Foundation

@Observable
class PostStore {
    var posts: [Post] = []
    var isLoading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func load(force: Bool = false) async {
        guard force || posts.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            let result: [Post] = try await api.get("/api/post")
            posts = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func create(date: String?, title: String?, content: String) async throws {
        let body = PostCreateBody(date: date, title: title, content: content)
        let _: PostCreateResponse = try await api.post("/api/post", body: body)
        await load(force: true)
    }

    func update(id: Int, title: String?, content: String?, isPinned: Bool? = nil) async throws {
        let body = PostUpdateBody(title: title, content: content, isPinned: isPinned)
        let _: PostUpdateResponse = try await api.put("/api/post/\(id)", body: body)
        await load(force: true)
    }

    func delete(id: Int) async throws {
        let _: PostDeleteResponse = try await api.delete("/api/post/\(id)")
        await load(force: true)
    }
}
