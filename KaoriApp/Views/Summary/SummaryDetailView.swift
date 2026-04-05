import SwiftUI

struct SummaryDetailView: View {
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api
    @Environment(FeedStore.self) private var feedStore

    let summaryType: SummaryType
    let initialText: String?

    private enum DetailPhase: Equatable {
        case loading
        case generating
        case content
        case empty
    }

    @State private var phase: DetailPhase = .loading
    @State private var summaryText: String?
    @State private var createdAt: String?
    @State private var sectionsCollapsed = false
    @State private var didRunInitialLoad = false
    @State private var didRequestAutoGeneration = false
    @State private var postGenerationReloadTask: Task<Void, Never>?

    init(summaryType: SummaryType, initialText: String? = nil) {
        let seededText = initialText.flatMap { $0.nilIfBlank }
        self.summaryType = summaryType
        self.initialText = seededText
        _summaryText = State(initialValue: seededText)
        _phase = State(initialValue: seededText == nil ? .loading : .content)
    }

    enum SummaryType {
        case daily(date: String)
        case weekly(date: String)

        var title: String {
            switch self {
            case .daily: return Localizer.localized("summary.dailyTitle")
            case .weekly: return Localizer.localized("summary.weeklyTitle")
            }
        }

        /// Anchor date used for regeneration tracking in FeedStore.
        var anchorDate: String {
            switch self {
            case .daily(let date): date
            case .weekly(let date): date
            }
        }

        var kind: SummaryKind {
            switch self {
            case .daily: .daily
            case .weekly: .weekly
            }
        }

        var endpoint: String {
            switch self {
            case .daily: "/api/summary/daily-detail"
            case .weekly: "/api/summary/weekly-detail"
            }
        }

        /// Query parameters for GET (load).
        var loadQuery: [String: String] {
            switch self {
            case .daily(let date): ["date": date]
            case .weekly: [:]
            }
        }
    }

    /// Whether FeedStore is currently generating a summary for this anchor date.
    private var feedStoreIsGenerating: Bool {
        feedStore.regeneratingSummaryDates.contains(summaryType.anchorDate)
    }

    var body: some View {
        Group {
            switch phase {
            case .loading:
                FullViewLoading(message: L.t("common.loading"))
            case .generating:
                FullViewLoading(message: L.t("summary.generating"))
            case .content:
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let summaryText {
                            SummarySectionsView(markdown: summaryText, allCollapsed: $sectionsCollapsed)
                        }

                        if let createdAt {
                            Text(L.t("summary.generatedAt", createdAt))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case .empty:
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(L.t("summary.noSummary"))
                        .foregroundStyle(.secondary)
                    Button(L.t("summary.generate")) {
                        triggerGeneration()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(summaryType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if phase == .content {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        triggerGeneration()
                    } label: {
                        Label(L.t("summary.regenerate"), systemImage: "arrow.clockwise")
                    }
                    .disabled(feedStoreIsGenerating)
                }
            }
        }
        .task {
            guard !didRunInitialLoad else { return }
            didRunInitialLoad = true
            await runInitialFlow()
        }
        .onChange(of: feedStoreIsGenerating) {
            if feedStoreIsGenerating {
                phase = .generating
            } else if phase == .generating {
                schedulePostGenerationReload()
            }
        }
        .onDisappear {
            postGenerationReloadTask?.cancel()
            postGenerationReloadTask = nil
        }
    }

    @MainActor
    private func runInitialFlow() async {
        if feedStoreIsGenerating {
            phase = .generating
            return
        }

        if initialText != nil {
            phase = .content
            _ = await loadSummary(showLoading: false)
            return
        }

        let didLoad = await loadSummary(showLoading: true)
        if !didLoad {
            await autoGenerateIfNeeded()
        }
    }

    @MainActor
    private func loadSummary(showLoading: Bool) async -> Bool {
        if showLoading {
            phase = .loading
        }

        guard let result = await fetchSummary() else { return false }
        applySummary(result)
        return true
    }

    @MainActor
    private func fetchSummary() async -> SummaryDetail? {
        do {
            let result: SummaryDetail = try await api.get(
                summaryType.endpoint,
                query: summaryType.loadQuery
            )
            return result.summaryText.nilIfBlank == nil ? nil : result
        } catch {
            return nil
        }
    }

    @MainActor
    private func applySummary(_ result: SummaryDetail) {
        summaryText = result.summaryText.nilIfBlank
        createdAt = result.createdAt.flatMap { $0.nilIfBlank }
        phase = .content
    }

    @MainActor
    private func autoGenerateIfNeeded() async {
        guard !didRequestAutoGeneration else {
            phase = .empty
            return
        }
        didRequestAutoGeneration = true
        phase = .generating
        guard !feedStoreIsGenerating else { return }
        _ = await feedStore.generateSummary(
            kind: summaryType.kind,
            date: summaryType.anchorDate
        )
        schedulePostGenerationReload()
    }

    @MainActor
    private func schedulePostGenerationReload() {
        guard postGenerationReloadTask == nil else { return }
        postGenerationReloadTask = Task {
            defer { postGenerationReloadTask = nil }
            await reloadSummaryAfterGeneration()
        }
    }

    @MainActor
    private func reloadSummaryAfterGeneration() async {
        let maxAttempts = 5

        for attempt in 0..<maxAttempts {
            if Task.isCancelled { return }
            if let result = await fetchSummary() {
                applySummary(result)
                return
            }
            if attempt < maxAttempts - 1 {
                try? await Task.sleep(for: .milliseconds(300))
            }
        }

        phase = .empty
    }

    @MainActor
    private func triggerGeneration() {
        postGenerationReloadTask?.cancel()
        postGenerationReloadTask = nil
        phase = .generating
        guard !feedStoreIsGenerating else { return }
        Task {
            _ = await feedStore.generateSummary(
                kind: summaryType.kind,
                date: summaryType.anchorDate
            )
            schedulePostGenerationReload()
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}
