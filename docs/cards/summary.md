# Card: Summary (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/SummaryCardModule.swift` |
| cardType | `"summary"` |
| icon | `sparkles` |
| accentColor | Yellow |
| supportsManualCreation | Yes |
| presentationStyle | `.sheet` |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | `[.regenerate]` |
| sortPriority | 0 (pinned at top) |

## FeedItem

Factory: `FeedItem.summary(...)`
Payload type: `SummaryPayload` (contains `text` + `date`)

## Views

| View | File | Purpose |
|------|------|---------|
| SummaryFeedCard | `Views/Summary/SummaryFeedCard.swift` | Compact card showing AI-generated daily summary |
| SummaryDetailView | `Views/Summary/SummaryDetailView.swift` | Full text view of the generated summary |
| SummaryListView | `Views/Summary/SummaryListView.swift` | Scrollable list of past summaries |
| SummaryGenerateView | `Views/Summary/SummaryGenerateView.swift` | Sheet for manually triggering summary generation |

## Store

`Stores/FeedStore.swift` — Summary generation methods live on FeedStore since summaries aggregate across all card types.

## Notes

- Supports both auto-generation (triggered via push notification at end of day) and manual generation from the "+" button.
- Swipe action is `.regenerate` instead of `.delete`, allowing the user to re-generate the summary with updated data.
- Pinned at the very top of the feed via `sortPriority=0`.
