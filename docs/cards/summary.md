# Card: Summary (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/SummaryCardModule.swift` |
| cardType | `"summary"` |
| icon | `sparkles` |
| accentColor | Yellow (daily) / Blue (weekly) |
| supportsManualCreation | Yes |
| presentationStyle | N/A (direct action, no sheet) |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | `[.delete, .regenerate]` |
| sortPriority | 0 (pinned at top) |

## FeedItem

Factory: `FeedItem.summary(id:text:date:kind:)`
Payload type: `SummaryPayload` (contains `summaryId`, `text`, `date`, `kind: SummaryKind`)

`SummaryKind` is `.daily` or `.weekly`, carried end-to-end from backend response through payload to detail view routing.
Summary feed rows keep a stable identity per date (`summary-YYYY-MM-DD`) whether they are still generating or already persisted.

## Views

| View | File | Purpose |
|------|------|---------|
| SummaryFeedCard | `Views/Feed/SummaryFeedCard.swift` | Passive preview card — no interactive controls |
| SummaryDetailView | `Views/Summary/SummaryDetailView.swift` | Full text view with collapsible sections |
| SummaryListView | `Views/Summary/SummaryListView.swift` | Scrollable list of past summaries |
| SummaryGenerateView | `Views/Summary/SummaryGenerateView.swift` | Legacy sheet (not used from "+" menu) |

## Store

`Stores/FeedStore.swift` — Summary generation methods live on FeedStore since summaries aggregate across all card types. All generation flows through `FeedStore.generateSummary(kind:date:)` — the canonical entry point that handles daily/weekly routing, language selection, and feed-item replacement.

## State Indicators

- Feed card header: `CardStateBadge(.processing)` during regeneration
- Feed card body: `.processingOverlay()` dims text during regeneration
- Detail view: `FullViewLoading` for loading and generation states

## Feed Card Design

The summary feed card is **preview-only** — no nested `Button`, `Toggle`, or interactive controls. Header icon and color are driven by `SummaryKind`:
- Daily: sparkles icon, purple
- Weekly: calendar.badge.clock icon, blue

Text is shown with `lineLimit(3)`. Tap navigates to the full detail view. Expand/collapse behavior lives in the detail view only (via `SummarySectionsView`).

**Why no nested controls:** A `Button` inside a feed card conflicts with FeedView's outer `Button` that handles tap-to-navigate. This can corrupt NavigationStack state, making all feed cards unclickable after returning from the detail view.

## Creation Flow ("+" menu)

Tapping "+" → Summary does NOT open a sheet. Instead:
1. `KaoriApp.handleAddAction` calls `feedStore.startSummaryGeneration()` directly
2. `startSummaryGeneration` checks `weeklySummaryWeekday` (default: Sunday)
   - If today matches → generates **weekly** summary
   - Otherwise → generates **daily** summary
3. A real summary card is inserted immediately for that date if one does not already exist
4. The card shows `CardStateBadge(.processing)` + `.processingOverlay()` while generating
5. The card remains tappable during processing and opens `SummaryDetailView` in its generating state
6. When generation completes, that same card updates in place with persisted content
7. A day has at most one summary card — weekly takes precedence on the configured day

Regeneration is kind-aware: swipe-regenerate on a weekly card regenerates weekly; on a daily card regenerates daily.
The summary card keeps the same feed-row and detail-route identity whether it is still processing or already persisted.

## Detail View (SummaryDetailView)

Uses an explicit `DetailPhase` enum (`.loading`, `.generating`, `.content`, `.empty`) instead of a boolean state matrix. Loading, generating, and empty states are outside the ScrollView for centered layout. Content is top-aligned.

Feed navigation seeds the detail with the current card text when `SummaryPayload.summaryId != nil`, so an already-generated summary renders immediately from payload before the follow-up GET refresh completes. Processing cards with `summaryId == nil` still navigate, but they enter the `.generating`/load flow without seeded text.
The feed navigation target identity is stable per summary date/kind, so the first generated card uses the same route before and after persistence.

Layout:
```swift
Group {
    switch phase {
    case .loading: FullViewLoading(message: ...)
    case .generating: FullViewLoading(message: ...)
    case .content:
        ScrollView {
            VStack(alignment: .leading, spacing: 16) { ... }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    case .empty: VStack { ... generate button ... }
    }
}
```

- Routing uses `SummaryType.daily(date:)` or `.weekly(date:)` — derived from payload `kind`, never inferred from current weekday
- `SummaryType.kind` maps to `SummaryKind` for FeedStore generation calls
- Initializer: `SummaryDetailView(summaryType:initialText:)` where `initialText` is optional feed-seeded content
- No `.textSelection(.enabled)` — gesture conflicts with NavigationStack back-swipe. Collapsible sections via `DisclosureGroup` (in `SummarySectionsView`) are standard SwiftUI and acceptable.

### Generation routing
- **All generation routes through `FeedStore.generateSummary(kind:date:)`** — the detail view does not call the API directly for POST/generate
- Toolbar regenerate and empty-state generate call `triggerGeneration()`, which delegates to FeedStore
- Auto-generate-on-missing runs only once per appearance, and only when there is no seeded summary text and the initial GET yields no summary
- Loading (GET) still uses the detail view's own `SummaryType.endpoint` and `loadQuery`

### API contract per kind
- Daily: `GET/POST /api/summary/daily-detail?date=...`
- Weekly: `GET/POST /api/summary/weekly-detail` — no `date` query parameter
- `SummaryType` encodes GET query shape via `loadQuery`; POST query shape is handled by `FeedStore.generateSummary`

### Regeneration tracking
- Both daily and weekly use `summaryType.anchorDate` for `regeneratingSummaryDates`
- Detail view observes `feedStoreIsGenerating` — if FeedStore is already generating, shows `.generating` phase without starting a second generation
- When FeedStore generation completes (`onChange(of: feedStoreIsGenerating)`), the detail view performs a bounded retry loop against the GET endpoint before falling back to `.empty`
- Local guards prevent duplicate auto-generation and duplicate post-generation reload tasks, which keeps feed navigation state stable when returning from detail

## Notes

- Supports both auto-generation (triggered via push notification at end of day) and manual generation from the "+" button.
- Swipe action is `.regenerate` instead of `.delete`, allowing the user to re-generate the summary with updated data.
- Pinned at the very top of the feed via `sortPriority=0`.
