import SwiftUI

/// Wrapper that reads FeedStore from environment to pass regenerating state.
struct SummaryFeedCardWrapper: View {
    @Environment(FeedStore.self) private var feedStore
    let text: String
    let date: String
    let kind: SummaryKind

    var body: some View {
        SummaryFeedCard(
            text: text,
            date: date,
            kind: kind,
            isRegenerating: feedStore.regeneratingSummaryDates.contains(date)
        )
    }
}

struct SummaryFeedCard: View {
    let text: String
    let date: String
    let kind: SummaryKind
    var isRegenerating: Bool = false

    private var bodyText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return text
        }
        return Localizer.localized(isRegenerating ? "summary.generating" : "summary.noSummary")
    }

    private var headerIcon: String {
        kind == .weekly ? "calendar.badge.clock" : "sparkles"
    }

    private var headerColor: Color {
        kind == .weekly ? .blue : .purple
    }

    private var headerTitle: String {
        kind == .weekly
            ? Localizer.localized("summary.weeklyTitle")
            : Localizer.localized("summary.dailyTitle")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: headerIcon)
                    .foregroundStyle(headerColor)
                Text(headerTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(headerColor)
                if isRegenerating {
                    CardStateBadge(.processing)
                }
                Spacer()
            }

            Text(bodyText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .processingOverlay(isRegenerating)
        }
        .feedCard()
    }
}
