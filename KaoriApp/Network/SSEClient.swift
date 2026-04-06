import Foundation

/// Lightweight SSE client for agent chat streaming.
/// Sends a POST request and parses `data: {json}\n\n` lines.
class SSEClient {
    private let config: AppConfig

    init(config: AppConfig) {
        self.config = config
    }

    /// Stream chat events from the agent SSE endpoint.
    func streamChat(message: String, sessionId: String?) -> AsyncThrowingStream<ChatStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard let base = config.baseURL else {
                        continuation.finish(throwing: APIError.notConfigured)
                        return
                    }

                    let url = base.appendingPathComponent("api/agent/chat")
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.timeoutInterval = 300  // 5 min for long agent turns

                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    request.httpBody = try encoder.encode(
                        ChatMessageRequest(message: message, sessionId: sessionId)
                    )

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    if let http = response as? HTTPURLResponse {
                        switch http.statusCode {
                        case 200: break
                        case 401:
                            continuation.finish(throwing: APIError.unauthorized)
                            return
                        default:
                            continuation.finish(throwing: APIError.serverError(http.statusCode))
                            return
                        }
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let json = String(line.dropFirst(6))
                        if let event = Self.parseEvent(json) {
                            continuation.yield(event)
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private static func parseEvent(_ json: String) -> ChatStreamEvent? {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = dict["type"] as? String else {
            return nil
        }

        switch type {
        case "session":
            return .session(
                sessionId: dict["session_id"] as? String ?? "",
                title: dict["title"] as? String
            )
        case "thinking":
            return .thinking(text: dict["text"] as? String ?? "")
        case "text":
            return .text(text: dict["text"] as? String ?? "")
        case "tool_use":
            return .toolUse(name: dict["name"] as? String ?? "")
        case "tool_result":
            return .toolResult(
                name: dict["name"] as? String ?? "",
                output: dict["output"] as? String ?? ""
            )
        case "done":
            return .done(messageCount: dict["message_count"] as? Int ?? 0)
        case "error":
            return .error(message: dict["message"] as? String ?? "Unknown error")
        default:
            return nil
        }
    }
}
