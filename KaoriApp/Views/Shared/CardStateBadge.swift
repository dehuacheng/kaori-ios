import SwiftUI

// MARK: - CardState

enum CardState {
    case loading
    case processing
    case live
    case failed
    case ai
    case manual
    case agent
}

// MARK: - CardStateBadge

struct CardStateBadge: View {
    let state: CardState
    @Environment(Localizer.self) private var L

    init(_ state: CardState) {
        self.state = state
    }

    var body: some View {
        Label {
            Text(label)
        } icon: {
            icon
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(bgColor)
        .foregroundStyle(fgColor)
        .clipShape(Capsule())
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }

    private var label: String {
        switch state {
        case .loading: L.t("shared.loading")
        case .processing: L.t("shared.analyzing")
        case .live: L.t("shared.live")
        case .failed: L.t("shared.failed")
        case .ai: L.t("shared.ai")
        case .manual: L.t("shared.manual")
        case .agent: L.t("shared.kaori")
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .loading:
            Image(systemName: "arrow.trianglehead.2.clockwise")
        case .processing:
            Image(systemName: "sparkles")
        case .live:
            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
        case .ai:
            Image(systemName: "sparkles")
        case .manual:
            Image(systemName: "pencil")
        case .agent:
            Image(systemName: "heart.fill")
        }
    }

    private var fgColor: Color {
        switch state {
        case .loading: .secondary
        case .processing: .orange
        case .live: .green
        case .failed: .red
        case .ai: .blue
        case .manual: .green
        case .agent: .pink
        }
    }

    private var bgColor: Color {
        switch state {
        case .loading: .gray.opacity(0.15)
        case .processing: .yellow.opacity(0.2)
        case .live: .green.opacity(0.15)
        case .failed: .red.opacity(0.2)
        case .ai: .blue.opacity(0.15)
        case .manual: .green.opacity(0.15)
        case .agent: .pink.opacity(0.15)
        }
    }
}

// MARK: - Processing Overlay Modifier

struct ProcessingOverlayModifier: ViewModifier {
    let isProcessing: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isProcessing ? 0.5 : 1.0)
            .overlay {
                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isProcessing)
    }
}

extension View {
    func processingOverlay(_ isProcessing: Bool) -> some View {
        modifier(ProcessingOverlayModifier(isProcessing: isProcessing))
    }
}

// MARK: - Full View Loading

struct FullViewLoading: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Full View Error

struct FullViewError: View {
    let message: String
    var onRetry: (() -> Void)?
    @Environment(Localizer.self) private var L

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let onRetry {
                Button {
                    onRetry()
                } label: {
                    Text(L.t("common.retry"))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
