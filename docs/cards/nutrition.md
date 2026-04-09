# Card: Nutrition (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/NutritionCardModule.swift` |
| cardType | `"nutrition"` |
| icon | `chart.bar.fill` |
| accentColor | Red |
| supportsManualCreation | No |
| presentationStyle | N/A |
| hasFeedDetailView | No |
| hasDataListView | No |
| hasSettingsView | No |
| feedSwipeActions | `[]` (none) |
| sortPriority | 2 (pinned) |

## FeedItem

Factory: `FeedItem.nutrition(...)`
Payload type: `NutritionPayload` (contains `NutritionTotals` + optional `Profile` fallback)

## Views

| View | File | Purpose |
|------|------|---------|
| DailyNutritionCard | `Views/Feed/DailyNutritionCard.swift` | Feed card showing daily macro totals and progress bars |

## Store

No dedicated store. Nutrition data is derived from meal data (aggregated from `MealStore`).

## Notes

- The card prefers the live `ProfileStore.profile` from the environment for target calories/macros and falls back to the payload profile snapshot if needed.
- Always shown for today's feed even when all values are zero, so the user has a visible target to fill.
- Pinned near the top of the feed via `sortPriority=2`.
- Not manually creatable; automatically computed from logged meals.
