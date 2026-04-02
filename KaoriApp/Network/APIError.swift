import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int)
    case networkUnavailable
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Server not configured"
        case .invalidURL: "Invalid server URL"
        case .unauthorized: "Invalid token"
        case .notFound: "Not found"
        case .serverError(let code): "Server error (\(code))"
        case .networkUnavailable: "Server unreachable"
        case .decodingError(let err): "Decoding error: \(err.localizedDescription)"
        case .unknown(let err): err.localizedDescription
        }
    }
}
