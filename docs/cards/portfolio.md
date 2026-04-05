# Card: Portfolio (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/PortfolioCardModule.swift` |
| cardType | `"portfolio"` |
| icon | `chart.line.uptrend.xyaxis` |
| accentColor | Green |
| supportsManualCreation | No |
| presentationStyle | N/A |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | `[]` (none) |
| sortPriority | 1 (pinned) |

## FeedItem

Factory: `FeedItem.portfolio(...)`
Payload type: `PortfolioSummaryResponse`

## Views

| View | File | Purpose |
|------|------|---------|
| PortfolioFeedCard | `Views/Portfolio/PortfolioFeedCard.swift` | Compact card showing portfolio P&L in the daily feed |
| PortfolioDetailView | `Views/Portfolio/PortfolioDetailView.swift` | Full breakdown of holdings and performance |

## Store

`Stores/FinanceStore.swift` — Manages portfolio data fetching, caching, and auto-refresh logic.

## State Indicators

- Feed card header: `CardStateBadge(.live)` when market data is fresh
- Detail view: `FullViewLoading` during initial data fetch

## Notes

- Auto-refreshes every 60 seconds on market days to keep prices current.
- Hidden on weekends when markets are closed.
- Pinned near the top of the feed via `sortPriority=1`.
