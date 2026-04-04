import SwiftUI

/// Lists past AI summaries by date. Read-only browsing — consistent with
/// the Data section pattern (display data, don't generate).
struct SummaryListView: View {
    @Environment(Localizer.self) private var L
    @Environment(APIClient.self) private var api

    @State private var summaries: [SummaryDetail] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if isLoading && summaries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else if summaries.isEmpty {
                ContentUnavailableView(
                    L.t("summary.noSummary"),
                    systemImage: "sparkles",
                    description: Text(L.t("summary.noSummaryHint"))
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(summaries) { summary in
                    NavigationLink {
                        SummaryDetailView(
                            summaryType: summary.type == "weekly"
                                ? .weekly
                                : .daily(date: summary.date)
                        )
                        .toolbar(.hidden, for: .tabBar)
                    } label: {
                        HStack {
                            Image(systemName: summary.type == "weekly"
                                  ? "calendar.badge.clock"
                                  : "sparkles")
                                .foregroundStyle(summary.type == "weekly" ? .blue : .yellow)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(summaryDateLabel(summary.date))
                                    .font(.subheadline.bold())
                                Text(summary.summaryText.components(separatedBy: "\n").prefix(2).joined(separator: " "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Text(summary.type == "weekly"
                                 ? L.t("summary.weeklyTitle")
                                 : L.t("summary.dailyTitle"))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await deleteSummary(summary) }
                        } label: {
                            Label(L.t("common.delete"), systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(L.t("card.summary"))
        .task {
            await loadSummaries()
        }
        .refreshable {
            await loadSummaries()
        }
    }

    private func deleteSummary(_ summary: SummaryDetail) async {
        // Optimistic removal
        summaries.removeAll { $0.id == summary.id }
        do {
            let _: SummaryDeleteResponse = try await api.delete("/api/summary/\(summary.id)")
        } catch {
            // Reload on failure
            await loadSummaries()
        }
    }

    private func loadSummaries() async {
        isLoading = true
        defer { isLoading = false }
        do {
            summaries = try await api.get("/api/summary/list")
        } catch {
            // Keep existing list on failure
        }
    }

    private func summaryDateLabel(_ dateStr: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateStr) else { return dateStr }
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
