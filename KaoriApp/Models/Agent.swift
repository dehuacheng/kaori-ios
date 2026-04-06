import Foundation

// MARK: - Response Models (matching backend JSON)

struct AgentSession: Codable, Identifiable {
    let id: String
    var title: String?
    var status: String
    let backend: String?
    let model: String?
    var messageCount: Int
    var tokenCountApprox: Int
    let createdAt: String?
    let updatedAt: String?
}

struct AgentMessage: Codable, Identifiable {
    let id: Int
    let sessionId: String
    let seq: Int
    let role: String
    let content: String  // JSON-encoded message dict
    let tokenCountApprox: Int
    let createdAt: String?
}

struct AgentSessionDetail: Codable {
    let session: AgentSession
    let messages: [AgentMessage]
}

struct AgentMemoryEntry: Codable, Identifiable {
    let id: Int
    let key: String
    let value: String
    let category: String
    let source: String?
    let createdAt: String?
    let updatedAt: String?
}

struct AgentPrompt: Codable, Identifiable {
    let id: Int
    let name: String
    let promptText: String
    var isActive: Bool
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Request Models

struct SessionCreateRequest: Codable {
    var backend: String?
    var model: String?
}

struct SessionUpdateRequest: Codable {
    var title: String?
    var status: String?
}

struct MemoryUpsertRequest: Codable {
    let value: String
    var category: String = "general"
}

struct ChatMessageRequest: Codable {
    let message: String
    var sessionId: String?
}

// MARK: - SSE Event Types

enum ChatStreamEvent {
    case session(sessionId: String, title: String?)
    case thinking(text: String)
    case text(text: String)
    case toolUse(name: String)
    case toolResult(name: String, output: String)
    case done(messageCount: Int)
    case error(message: String)
}

// MARK: - Display Models (for chat UI)

struct ChatDisplayMessage: Identifiable {
    let id: String
    let role: ChatRole
    var text: String
    var thinkingText: String = ""
    var isStreaming: Bool = false
    var toolCalls: [ChatToolCall] = []
    let timestamp: Date?
}

enum ChatRole {
    case user
    case assistant
}

struct ChatToolCall: Identifiable {
    let id = UUID()
    let name: String
    var isLoading: Bool = true
    var output: String?
}

// MARK: - History Parsing

enum ChatHistoryParser {
    /// Build display messages from the full message list.
    /// Processes sequentially to associate tool results with their tool calls.
    static func buildDisplayMessages(from messages: [AgentMessage]) -> [ChatDisplayMessage] {
        var result: [ChatDisplayMessage] = []
        // Maps tool_call_id -> (index in result, index in toolCalls)
        var pendingToolCalls: [String: (Int, Int)] = [:]

        for msg in messages {
            guard let data = msg.content.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            let msgRole = dict["role"] as? String ?? msg.role

            // --- User message ---
            if msgRole == "user" {
                // Check if it's a tool_result wrapper (Anthropic format)
                if let blocks = dict["content"] as? [[String: Any]],
                   let first = blocks.first,
                   first["type"] as? String == "tool_result" {
                    // Attach outputs to pending tool calls
                    for block in blocks {
                        let tcId = block["tool_use_id"] as? String ?? ""
                        let output = block["_output"] as? String
                            ?? block["content"] as? String ?? ""
                        if let (resultIdx, tcIdx) = pendingToolCalls[tcId],
                           resultIdx < result.count,
                           tcIdx < result[resultIdx].toolCalls.count {
                            result[resultIdx].toolCalls[tcIdx].output = output
                            result[resultIdx].toolCalls[tcIdx].isLoading = false
                        }
                    }
                    continue
                }

                // Regular user message
                let text: String
                if let s = dict["content"] as? String {
                    text = s
                } else { continue }
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                // Skip compaction summary messages
                if text.hasPrefix("[Earlier conversation summary:") { continue }

                result.append(ChatDisplayMessage(
                    id: "msg-\(msg.id)", role: .user, text: text,
                    timestamp: parseUTCTimestamp(msg.createdAt)
                ))
                continue
            }

            // --- Tool result (OpenAI format: role="tool") ---
            if msgRole == "tool" || msg.role == "tool_result" {
                let tcId = dict["tool_call_id"] as? String ?? ""
                let output = dict["_output"] as? String
                    ?? dict["content"] as? String ?? ""
                if let (resultIdx, tcIdx) = pendingToolCalls[tcId],
                   resultIdx < result.count,
                   tcIdx < result[resultIdx].toolCalls.count {
                    result[resultIdx].toolCalls[tcIdx].output = output
                    result[resultIdx].toolCalls[tcIdx].isLoading = false
                }
                continue
            }

            // --- Assistant message ---
            if msgRole == "assistant" {
                var text = ""
                var toolCalls: [ChatToolCall] = []
                let thinkingText = dict["_thinking"] as? String ?? ""

                // Extract text + tool_use from content
                if let stringContent = dict["content"] as? String {
                    text = stringContent
                } else if let arrayContent = dict["content"] as? [[String: Any]] {
                    // Anthropic format
                    for block in arrayContent {
                        let blockType = block["type"] as? String
                        if blockType == "text" {
                            text += block["text"] as? String ?? ""
                        } else if blockType == "tool_use" {
                            let name = block["name"] as? String ?? ""
                            let tcId = block["id"] as? String ?? ""
                            let tc = ChatToolCall(name: name, isLoading: false)
                            pendingToolCalls[tcId] = (result.count, toolCalls.count)
                            toolCalls.append(tc)
                        }
                    }
                }

                // OpenAI format tool_calls
                if let tcArray = dict["tool_calls"] as? [[String: Any]] {
                    for tc in tcArray {
                        let tcId = tc["id"] as? String ?? ""
                        let fn = tc["function"] as? [String: Any]
                        let name = fn?["name"] as? String ?? ""
                        let toolCall = ChatToolCall(name: name, isLoading: false)
                        pendingToolCalls[tcId] = (result.count, toolCalls.count)
                        toolCalls.append(toolCall)
                    }
                }

                // Skip empty messages (no text, no tools, no thinking)
                let hasContent = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !toolCalls.isEmpty || !thinkingText.isEmpty
                guard hasContent else { continue }

                result.append(ChatDisplayMessage(
                    id: "msg-\(msg.id)", role: .assistant, text: text,
                    thinkingText: thinkingText, toolCalls: toolCalls,
                    timestamp: parseUTCTimestamp(msg.createdAt)
                ))
            }
        }

        return result
    }
}
