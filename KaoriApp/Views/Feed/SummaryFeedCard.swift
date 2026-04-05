import SwiftUI

/// Wrapper that reads FeedStore from environment to pass regenerating state.
struct SummaryFeedCardWrapper: View {
    @Environment(FeedStore.self) private var feedStore
    let text: String
    let date: String

    var body: some View {
        SummaryFeedCard(
            text: text,
            date: date,
            isRegenerating: feedStore.regeneratingSummaryDates.contains(date)
        )
    }
}

struct SummaryFeedCard: View {
    let text: String
    let date: String
    var isRegenerating: Bool = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Daily Summary")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                Spacer()
                if isRegenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        withAnimation { isExpanded.toggle() }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : 3)
                .opacity(isRegenerating ? 0.4 : 1.0)
        }
        .feedCard()
    }
}
