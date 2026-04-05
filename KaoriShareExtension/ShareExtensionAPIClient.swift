import Foundation

enum ShareAPIError: LocalizedError {
    case notConfigured
    case networkUnavailable
    case unauthorized
    case serverError(Int)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Not configured"
        case .networkUnavailable: return "Server unreachable"
        case .unauthorized: return "Unauthorized"
        case .serverError(let code): return "Server error (\(code))"
        case .unknown(let error): return error.localizedDescription
        }
    }
}

struct ShareExtensionAPIClient {

    func createPost(content: String, date: String, imageData: Data?) async throws {
        guard SharedConfig.isConfigured, let baseURL = SharedConfig.baseURL else {
            throw ShareAPIError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/post")
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("Bearer \(SharedConfig.token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // content field
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"content\"\r\n\r\n")
        body.appendString("\(content)\r\n")

        // post_date field
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"post_date\"\r\n\r\n")
        body.appendString("\(date)\r\n")

        // optional photo
        if let imageData {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n")
            body.appendString("Content-Type: image/jpeg\r\n\r\n")
            body.append(imageData)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .notConnectedToInternet ||
                                            error.code == .cannotConnectToHost ||
                                            error.code == .timedOut {
            throw ShareAPIError.networkUnavailable
        } catch {
            throw ShareAPIError.unknown(error)
        }

        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200..<300: return
        case 401: throw ShareAPIError.unauthorized
        default: throw ShareAPIError.serverError(http.statusCode)
        }
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}
