import Foundation

@Observable
class APIClient {
    private let config: AppConfig
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    var isConnected = false

    init(config: AppConfig) {
        self.config = config
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Health Check

    func healthCheck() async -> Bool {
        let result = await healthCheckDetailed()
        return result == nil
    }

    /// Returns nil on success, or an error description on failure.
    func healthCheckDetailed() async -> String? {
        guard let base = config.baseURL else {
            return "Invalid URL: '\(config.serverURL)'"
        }
        let url = base.appendingPathComponent("api/health")
        do {
            let (_, response) = try await session.data(from: url)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code == 200 {
                await MainActor.run { isConnected = true }
                return nil
            } else {
                await MainActor.run { isConnected = false }
                return "Server returned HTTP \(code) at \(url)"
            }
        } catch {
            await MainActor.run { isConnected = false }
            return "Request to \(url) failed: \(error.localizedDescription)"
        }
    }

    // MARK: - GET

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let url = try buildURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - POST JSON

    func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - POST (no body)

    func post<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let url = try buildURL(path: path, query: query)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - PUT JSON

    func put<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - DELETE

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let url = try buildURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - Multipart Upload

    func postMultipart<T: Decodable>(
        _ path: String,
        fields: [String: String],
        imageData: Data? = nil,
        imageFieldName: String = "photo"
    ) async throws -> T {
        let url = try buildURL(path: path)
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        if let imageData {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(imageFieldName)\"; filename=\"photo.jpg\"\r\n")
            body.append("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await perform(request)
        try checkStatus(response)
        return try decode(data)
    }

    // MARK: - Photo URL

    func photoURL(for path: String) -> URL? {
        config.baseURL?.appendingPathComponent("/photos/\(path)")
    }

    // MARK: - Private Helpers

    private func buildURL(path: String, query: [String: String] = [:]) throws -> URL {
        guard let base = config.baseURL else { throw APIError.notConfigured }
        var components = URLComponents(url: base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let result = try await session.data(for: request)
            await MainActor.run { isConnected = true }
            return result
        } catch let error as URLError where error.code == .notConnectedToInternet ||
                                            error.code == .cannotConnectToHost ||
                                            error.code == .timedOut {
            await MainActor.run { isConnected = false }
            throw APIError.networkUnavailable
        } catch {
            throw APIError.unknown(error)
        }
    }

    private func checkStatus(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        default: throw APIError.serverError(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}
