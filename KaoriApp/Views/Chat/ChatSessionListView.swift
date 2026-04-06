import SwiftUI

struct ChatSessionListView: View {
    @Environment(AgentStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.sessions.isEmpty && !store.isLoading {
                    ContentUnavailableView {
                        Label(L.t("chat.noSessions"), systemImage: "bubble.left.and.text.bubble.right")
                    } description: {
                        Text(L.t("chat.noSessionsHint"))
                    } actions: {
                        Button(L.t("chat.newChat")) {
                            Task { await startNewChat() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            NavigationLink(value: session.id) {
                                SessionRow(session: session)
                            }
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationTitle(L.t("chat.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await startNewChat() }
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(for: String.self) { sessionId in
                ChatView(sessionId: sessionId)
            }
            .task {
                await store.loadSessions()
            }
        }
    }

    private func startNewChat() async {
        if let session = await store.createSession() {
            path = [session.id]
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            let session = store.sessions[index]
            Task { await store.deleteSession(session.id) }
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: AgentSession
    @Environment(Localizer.self) private var L

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title ?? L.t("chat.untitled"))
                .font(.body)
                .lineLimit(1)

            HStack(spacing: 8) {
                if let time = formatSessionTime(session.updatedAt ?? session.createdAt) {
                    Text(time)
                }
                if session.messageCount > 0 {
                    Text("\(session.messageCount) \(L.t("chat.messages"))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func formatSessionTime(_ ts: String?) -> String? {
        guard let date = parseUTCTimestamp(ts) else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
