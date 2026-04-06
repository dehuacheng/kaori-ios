import Foundation

@Observable
class AgentStore {
    var sessions: [AgentSession] = []
    var messages: [ChatDisplayMessage] = []
    var activeSessionId: String?
    var streamingText: String = ""
    var thinkingText: String = ""
    var isStreaming = false
    var isLoading = false
    var error: String?

    // Memory
    var memoryEntries: [AgentMemoryEntry] = []
    var isLoadingMemory = false

    // Prompts
    var prompts: [AgentPrompt] = []
    var isLoadingPrompts = false

    // Active tool calls during streaming
    var activeToolCalls: [ChatToolCall] = []

    private let api: APIClient
    private let sse: SSEClient
    private var streamTask: Task<Void, Never>?

    init(api: APIClient, config: AppConfig) {
        self.api = api
        self.sse = SSEClient(config: config)
    }

    // MARK: - Sessions

    @MainActor
    func loadSessions() async {
        isLoading = true
        do {
            sessions = try await api.get("/api/agent/sessions")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    func createSession() async -> AgentSession? {
        do {
            let session: AgentSession = try await api.post(
                "/api/agent/sessions",
                body: SessionCreateRequest()
            )
            sessions.insert(session, at: 0)
            return session
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    @MainActor
    func deleteSession(_ id: String) async {
        do {
            let _: DeleteResponse = try await api.delete("/api/agent/sessions/\(id)")
            sessions.removeAll { $0.id == id }
            if activeSessionId == id {
                activeSessionId = nil
                messages = []
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func updateSessionTitle(_ id: String, title: String) async {
        do {
            let updated: AgentSession = try await api.put(
                "/api/agent/sessions/\(id)",
                body: SessionUpdateRequest(title: title)
            )
            if let idx = sessions.firstIndex(where: { $0.id == id }) {
                sessions[idx] = updated
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    @MainActor
    func archiveSession(_ id: String) async {
        do {
            let updated: AgentSession = try await api.put(
                "/api/agent/sessions/\(id)",
                body: SessionUpdateRequest(status: "archived")
            )
            sessions.removeAll { $0.id == id }
            _ = updated
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Load Session Messages

    @MainActor
    func loadSession(_ id: String) async {
        activeSessionId = id
        isLoading = true
        do {
            let detail: AgentSessionDetail = try await api.get("/api/agent/sessions/\(id)")
            messages = ChatHistoryParser.buildDisplayMessages(from: detail.messages)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Send Message (SSE Streaming)

    @MainActor
    func sendMessage(_ text: String) async {
        guard !isStreaming else { return }

        // Append user message optimistically
        let userMsg = ChatDisplayMessage(
            id: "user-\(UUID().uuidString)",
            role: .user,
            text: text,
            timestamp: Date()
        )
        messages.append(userMsg)

        // Start streaming
        isStreaming = true
        streamingText = ""
        thinkingText = ""
        activeToolCalls = []
        error = nil

        // Create placeholder assistant message
        let assistantId = "assistant-\(UUID().uuidString)"
        let assistantMsg = ChatDisplayMessage(
            id: assistantId,
            role: .assistant,
            text: "",
            isStreaming: true,
            timestamp: Date()
        )
        messages.append(assistantMsg)

        streamTask = Task {
            do {
                for try await event in sse.streamChat(
                    message: text,
                    sessionId: activeSessionId
                ) {
                    await handleStreamEvent(event, assistantId: assistantId)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
            await MainActor.run {
                finishStreaming(assistantId: assistantId)
            }
        }
    }

    @MainActor
    private func handleStreamEvent(_ event: ChatStreamEvent, assistantId: String) {
        switch event {
        case .session(let sessionId, let title):
            if activeSessionId == nil {
                activeSessionId = sessionId
            }
            // Update session in list if title changed
            if let title, let idx = sessions.firstIndex(where: { $0.id == sessionId }) {
                sessions[idx].title = title
            }

        case .thinking(let text):
            thinkingText += text
            updateAssistantMessage(assistantId)

        case .text(let text):
            streamingText += text
            updateAssistantMessage(assistantId)

        case .toolUse(let name):
            let tc = ChatToolCall(name: name, isLoading: true)
            activeToolCalls.append(tc)
            updateAssistantMessage(assistantId)

        case .toolResult(let name, let output):
            // Mark the matching tool call as complete with output
            if let idx = activeToolCalls.lastIndex(where: { $0.name == name && $0.isLoading }) {
                activeToolCalls[idx].isLoading = false
                activeToolCalls[idx].output = output
            }
            updateAssistantMessage(assistantId)

        case .done(let messageCount):
            // Mark tool calls as complete
            for i in activeToolCalls.indices {
                activeToolCalls[i].isLoading = false
            }
            // Update session message count
            if let sid = activeSessionId,
               let idx = sessions.firstIndex(where: { $0.id == sid }) {
                sessions[idx].messageCount = messageCount
            }

        case .error(let message):
            error = message
        }
    }

    @MainActor
    private func updateAssistantMessage(_ id: String) {
        guard let idx = messages.lastIndex(where: { $0.id == id }) else { return }
        messages[idx].text = streamingText
        messages[idx].thinkingText = thinkingText
        messages[idx].toolCalls = activeToolCalls
    }

    @MainActor
    private func finishStreaming(assistantId: String) {
        isStreaming = false
        if let idx = messages.lastIndex(where: { $0.id == assistantId }) {
            messages[idx].isStreaming = false
            messages[idx].toolCalls = activeToolCalls
        }
        streamingText = ""
        thinkingText = ""
        activeToolCalls = []
        streamTask = nil
    }

    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
    }

    // MARK: - Memory

    @MainActor
    func loadMemory() async {
        isLoadingMemory = true
        do {
            memoryEntries = try await api.get("/api/agent/memory")
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMemory = false
    }

    func upsertMemory(key: String, value: String, category: String = "general") async throws {
        let _: AgentMemoryEntry = try await api.put(
            "/api/agent/memory/\(key)",
            body: MemoryUpsertRequest(value: value, category: category)
        )
        await loadMemory()
    }

    func deleteMemory(key: String) async throws {
        let _: DeleteResponse = try await api.delete("/api/agent/memory/\(key)")
        await loadMemory()
    }

    // MARK: - Prompts

    @MainActor
    func loadPrompts() async {
        isLoadingPrompts = true
        do {
            prompts = try await api.get("/api/agent/prompts")
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingPrompts = false
    }

    func activatePrompt(_ id: Int) async throws {
        // Activate uses PUT with empty body
        let _: AgentPrompt = try await api.put(
            "/api/agent/prompts/\(id)/activate",
            body: [String: String]()
        )
        await loadPrompts()
    }

    func deletePrompt(_ id: Int) async throws {
        let _: DeleteResponse = try await api.delete("/api/agent/prompts/\(id)")
        await loadPrompts()
    }
}
