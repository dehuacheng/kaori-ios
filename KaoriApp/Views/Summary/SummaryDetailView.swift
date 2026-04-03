import SwiftUI

struct SummaryDetailView: View {
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api

    let summaryType: SummaryType

    @State private var summaryText: String?
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var createdAt: String?
    @State private var sectionsCollapsed = false

    enum SummaryType {
        case daily(date: String)
        case weekly

        var title: String {
            switch self {
            case .daily: return Localizer.localized("summary.dailyTitle")
            case .weekly: return Localizer.localized("summary.weeklyTitle")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading || isGenerating {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(isGenerating
                            ? L.t("summary.generating")
                            : L.t("common.loading"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if let text = summaryText {
                    SummarySectionsView(markdown: text, allCollapsed: $sectionsCollapsed)
                        .textSelection(.enabled)

                    if let createdAt {
                        Text(L.t("summary.generatedAt", createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(L.t("summary.noSummary"))
                            .foregroundStyle(.secondary)
                        Button(L.t("summary.generate")) {
                            Task { await generate() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding()
        }
        .navigationTitle(summaryType.title)
        .toolbar {
            if summaryText != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await generate() }
                    } label: {
                        Label(L.t("summary.regenerate"), systemImage: "arrow.clockwise")
                    }
                    .disabled(isGenerating)
                }
            }
        }
        .task {
            await loadOrGenerate()
        }
    }

    private func loadOrGenerate() async {
        isLoading = true
        defer { isLoading = false }

        do {
            switch summaryType {
            case .daily(let date):
                let result: SummaryDetail = try await api.get(
                    "/api/summary/daily-detail",
                    query: ["date": date]
                )
                summaryText = result.summaryText
                createdAt = result.createdAt
            case .weekly:
                let result: SummaryDetail = try await api.get("/api/summary/weekly-detail")
                summaryText = result.summaryText
                createdAt = result.createdAt
            }
        } catch {
            // No existing summary — auto-generate
            await generate()
        }
    }

    private func generate() async {
        isGenerating = true
        defer { isGenerating = false }

        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let lang = langRaw.hasPrefix("zh") ? "zh" : "en"

        do {
            switch summaryType {
            case .daily(let date):
                let result: SummaryDetail = try await api.post(
                    "/api/summary/daily-detail",
                    query: ["language": lang, "date": date]
                )
                summaryText = result.summaryText
                createdAt = result.createdAt
            case .weekly:
                let result: SummaryDetail = try await api.post(
                    "/api/summary/weekly-detail",
                    query: ["language": lang]
                )
                summaryText = result.summaryText
                createdAt = result.createdAt
            }
        } catch {
            summaryText = "Error: \(error.localizedDescription)"
        }
    }
}
