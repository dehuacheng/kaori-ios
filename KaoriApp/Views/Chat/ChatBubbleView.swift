import SwiftUI
import MarkdownUI

struct ChatBubbleView: View {
    let message: ChatDisplayMessage

    var body: some View {
        switch message.role {
        case .user:
            UserBubble(text: message.text)
        case .assistant:
            AssistantBubble(message: message)
        }
    }
}

// MARK: - User Bubble

private struct UserBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

// MARK: - Assistant Bubble

private struct AssistantBubble: View {
    let message: ChatDisplayMessage

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // Thinking indicator (collapsible)
                if !message.thinkingText.isEmpty {
                    ThinkingView(text: message.thinkingText)
                }

                // Tool call indicators
                ForEach(message.toolCalls) { tc in
                    ToolCallPill(toolCall: tc)
                }

                // Main text
                if !message.text.isEmpty {
                    Markdown(message.text)
                        .markdownTheme(.kaori)
                }

                // Streaming cursor
                if message.isStreaming && message.text.isEmpty && message.thinkingText.isEmpty {
                    TypingIndicator()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Thinking View

private struct ThinkingView: View {
    let text: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "brain")
                Text("Thinking")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tool Call Pill

private struct ToolCallPill: View {
    let toolCall: ChatToolCall
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                if toolCall.output != nil {
                    withAnimation { isExpanded.toggle() }
                }
            } label: {
                HStack(spacing: 6) {
                    if toolCall.isLoading {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    Text(displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if toolCall.output != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if isExpanded, let output = toolCall.output {
                Text(output)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(20)
            }
        }
    }

    private var displayName: String {
        toolCall.name.replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .opacity(index <= dotCount ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

// MARK: - Kaori Markdown Theme

extension MarkdownUI.Theme {
    static let kaori = Theme()
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.9))
            BackgroundColor(Color(.tertiarySystemGroupedBackground))
        }
        .codeBlock { configuration in
            ScrollView(.horizontal, showsIndicators: false) {
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(.em(0.85))
                    }
                    .padding(12)
            }
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle { FontWeight(.bold); FontSize(.em(1.3)) }
                .padding(.bottom, 4)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle { FontWeight(.bold); FontSize(.em(1.15)) }
                .padding(.bottom, 2)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle { FontWeight(.semibold); FontSize(.em(1.05)) }
        }
}
