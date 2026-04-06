import SwiftUI

struct ChatView: View {
    let sessionId: String
    @Environment(AgentStore.self) private var store
    @Environment(Localizer.self) private var L
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.messages) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    // Invisible anchor at bottom
                    Color.clear.frame(height: 1).id("bottom")
                }
                .onAppear { scrollProxy = proxy }
                .onChange(of: store.messages.count) {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: store.streamingText) {
                    scrollToBottom(proxy: proxy)
                }
            }

            Divider()

            // Input bar
            HStack(alignment: .bottom, spacing: 8) {
                TextField(L.t("chat.placeholder"), text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($isInputFocused)
                    .onSubmit { sendMessage() }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: store.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color.accentColor : .secondary)
                }
                .disabled(!canSend && !store.isStreaming)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .navigationTitle(sessionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await store.loadSession(sessionId)
        }
        .onDisappear {
            store.cancelStreaming()
        }
    }

    private var sessionTitle: String {
        store.sessions.first(where: { $0.id == sessionId })?.title ?? L.t("chat.newChat")
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !store.isStreaming
    }

    private func sendMessage() {
        if store.isStreaming {
            store.cancelStreaming()
            return
        }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await store.sendMessage(text) }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}
