import Foundation

@Observable
class DocumentStore {
    var documents: [Document] = []
    var isLoading = false
    var isUploading = false
    var error: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    @MainActor
    func load(force: Bool = false) async {
        guard force || documents.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            let result: [Document] = try await api.get("/api/documents")
            documents = result
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func upload(filesData: [(data: Data, filename: String, mimeType: String)]) async throws -> DocumentUploadResponse {
        await MainActor.run { isUploading = true }
        defer { Task { @MainActor in isUploading = false } }

        let files = filesData.map { (data: $0.data, fieldName: "files", filename: $0.filename, mimeType: $0.mimeType) }
        let response: DocumentUploadResponse = try await api.postMultipartFiles(
            "/api/documents/upload", files: files
        )
        await load(force: true)
        return response
    }

    func getDocument(_ id: Int) async throws -> Document {
        return try await api.get("/api/documents/\(id)")
    }

    func search(query: String) async throws -> [Document] {
        return try await api.get("/api/documents/search", query: ["q": query])
    }

    func delete(id: Int) async throws {
        let _: DocumentDeleteResponse = try await api.delete("/api/documents/\(id)")
        await load(force: true)
    }
}
