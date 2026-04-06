# Card Design Docs (iOS)

Every feature in Kaori is a **card type** implemented as a `CardModule`. Each card has a design doc here covering its iOS module, views, feed behavior, and interaction patterns.

**When adding or modifying a card, update its doc here.** See `CLAUDE.md` for the full checklist.

## Cards

| Card Type | Doc | Module | Feed Card | Detail View |
|-----------|-----|--------|-----------|-------------|
| `meal` | [meal.md](meal.md) | `MealCardModule` | `MealFeedCard` | `MealDetailView` |
| `weight` | [weight.md](weight.md) | `WeightCardModule` | `WeightFeedCard` | — |
| `workout` | [workout.md](workout.md) | `WorkoutCardModule` | `WorkoutFeedCard` | `WorkoutDetailView` |
| `healthkit_workout` | [healthkit-workout.md](healthkit-workout.md) | `HealthKitWorkoutCardModule` | `WorkoutFeedCard` | `ImportedWorkoutDetailView` |
| `portfolio` | [portfolio.md](portfolio.md) | `PortfolioCardModule` | `PortfolioFeedCard` | `PortfolioDetailView` |
| `nutrition` | [nutrition.md](nutrition.md) | `NutritionCardModule` | `DailyNutritionCard` | — |
| `summary` | [summary.md](summary.md) | `SummaryCardModule` | `SummaryFeedCard` | `SummaryDetailView` |
| `post` | [post.md](post.md) | `PostCardModule` | `PostFeedCard` | `PostDetailView` |
| `reminder` | [reminder.md](reminder.md) | `ReminderCardModule` | `ReminderFeedCard` | `ReminderDetailView` |
| `weather` | [weather.md](weather.md) | `WeatherCardModule` | `WeatherFeedCard` | — |

## Shared Visual Components

Cards that have loading/processing/live states use these shared components from `Views/Shared/CardStateBadge.swift`:

| Component | Purpose | Used by |
|-----------|---------|---------|
| `CardStateBadge` | Capsule pill badge for header state (processing, failed, ai, manual, live, loading) | Meal, Summary, Portfolio |
| `.processingOverlay(Bool)` | Dims content to 50% + small spinner overlay during processing | Meal (nutrition), Summary (text), MealRow |
| `FullViewLoading(message:)` | Centered spinner + text for detail view loading | MealDetail, SummaryDetail, PortfolioDetail, HoldingsImport |
| `FullViewError(message:, onRetry:)` | Error icon + message + retry button | HoldingsImport |

## Feed Card Interaction Contract

Feed cards are **passive labels**. All interaction is handled by the feed row:
- **Tap** → navigates to the detail view (via FeedView's outer Button)
- **Swipe** → reveals contextual actions (via `feedSwipeActions`)

Feed cards MUST NOT contain interactive controls: no `Button`, `Toggle`, `Menu`, `DisclosureGroup`, `TextField`, or custom `onTapGesture`. Nested controls inside a feed card interfere with FeedView's outer Button tap handler and can corrupt NavigationStack state after navigation, making all feed cards unclickable.

If a card needs interactive behavior (expand/collapse, inline editing), that behavior belongs in the **detail view**, not the feed card.

## Detail View Layout Rules

All detail views pushed via `navigationDestination` MUST follow these rules:

### 1. Loading/empty states OUTSIDE ScrollView
```swift
// CORRECT — loading state centers on screen
Group {
    if let data {
        ScrollView { /* content */ }
    } else {
        FullViewLoading(message: ...)
    }
}
.navigationTitle(...)

// WRONG — loading state sits at top of scroll area
ScrollView {
    if isLoading {
        FullViewLoading(message: ...)  // appears "high up", not centered
    } else { /* content */ }
}
```

### 2. No concurrent generation with FeedStore
If the detail view can trigger async generation (e.g., summary), it MUST check `feedStore.regeneratingSummaryDates` (or equivalent) before starting its own generation. Two concurrent generations mutate `feedItems` during navigation, corrupting NavigationStack state and making feed cards unclickable after returning.

### 3. No NavigationStack inside detail views
Detail views are pushed onto FeedView's NavigationStack. Adding a nested NavigationStack causes double nav bars and gesture conflicts.

### 4. Value-based NavigationLink with captured detail view
FeedView uses `NavigationLink(value: FeedNavigationTarget)` with `.navigationDestination(for:)`. The detail view is resolved at render time and captured in the `FeedNavigationTarget` value. NavigationStack owns the push/pop lifecycle — no manual state management. This prevents:
- feedItems mutations from recreating the destination view mid-navigation
- Manual state desync between identity and view bindings
- Stale navigation state after pop (NavigationStack clears the path automatically)

### 5. Summary detail must avoid gesture-heavy modifiers
Summary detail should not use `.textSelection(.enabled)` or other gesture-layering modifiers that conflict with NavigationStack's back-swipe gesture. Collapsible sections via `DisclosureGroup` are acceptable (standard SwiftUI). Interactive features like text selection belong in a dedicated read view, not the feed-entered detail path.

### 6. Summary detail must respect distinct daily vs weekly API contracts
- Daily: `GET/POST /api/summary/daily-detail?date=...`
- Weekly: `GET/POST /api/summary/weekly-detail` (no `date` query)
`SummaryType` encodes the query shape per kind. Do not pass `date` to the weekly endpoint.

### Current detail view patterns

| Detail View | Root Layout | Has Loading State | Fetches Data |
|---|---|---|---|
| MealDetailView | `Group { if data { ScrollView } else { FullViewLoading } }` | Yes | By ID |
| WorkoutDetailView | `Group { if data { content } else { ProgressView } }` | Yes | By ID |
| PortfolioDetailView | `List { if data { sections } else { FullViewLoading } }` | Yes | By date |
| SummaryDetailView | `Group { switch phase { .loading/.generating: FullViewLoading, .content: ScrollView, .empty: generate } }` | Yes | By date + observes FeedStore |
| PostDetailView | `ScrollView { ... }` | No | Data in payload |
| ReminderDetailView | `List { ... }` | No | Data in payload |

## Template for New Cards

```markdown
# Card: <Name> (iOS)

## Module
| Property | Value |
|----------|-------|
| File | `CardModule/Modules/XxxCardModule.swift` |
| cardType | `"xxx"` |
| icon | `<sf.symbol.name>` |
| accentColor | <Color> |
| supportsManualCreation | Yes/No |
| hasFeedDetailView | Yes/No |
| hasDataListView | Yes/No |
| hasSettingsView | Yes/No |
| presentationStyle | .sheet / .fullScreenCover |
| feedSwipeActions | [.delete] / [.regenerate] / [] |
| sortPriority | 10 (chronological) / 0-2 (pinned) |

## FeedItem Factory
`FeedItem.xxx(...)` — payload type: `Xxx` or `XxxPayload`

## Views
- Feed card: `Views/Xxx/XxxFeedCard.swift`
- Detail: `Views/Xxx/XxxDetailView.swift`
- Create: `Views/Xxx/XxxCreateView.swift`
- Data list: `Views/Xxx/XxxListView.swift`

## Store
`Stores/XxxStore.swift` — API calls, state management
```
