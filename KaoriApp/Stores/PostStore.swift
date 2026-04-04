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

    func create(date: String?, title: String?, content: String, photos: [Data]? = nil) async throws {
        var fields: [String: String] = ["content": content]
        if let date { fields["post_date"] = date }
        if let title { fields["title"] = title }

        if let photos, photos.count > 1 {
            let files = photos.enumerated().map { (i, data) in
                (data: data, fieldName: "photos", filename: "photo\(i).jpg", mimeType: "image/jpeg")
            }
            let _: PostCreateResponse = try await api.postMultipartFiles("/api/post", fields: fields, files: files)
        } else {
            let _: PostCreateResponse = try await api.postMultipart("/api/post", fields: fields, imageData: photos?.first)
        }
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
