# Card: Meal (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/MealCardModule.swift` |
| cardType | `"meal"` |
| icon | `fork.knife` |
| accentColor | Orange |
| supportsManualCreation | Yes |
| presentationStyle | `.sheet` |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | No |
| feedSwipeActions | `[.delete]` |
| sortPriority | 10 |

## FeedItem

Factory: `FeedItem.meal(...)`
Payload type: `Meal`

## Views

| View | File | Purpose |
|------|------|---------|
| MealFeedCard | `Views/Meal/MealFeedCard.swift` | Compact card shown in the daily feed |
| MealDetailView | `Views/Meal/MealDetailView.swift` | Full detail view when tapping a meal card |
| MealCreateView | `Views/Meal/MealCreateView.swift` | Sheet for logging a new meal (manual creation) |
| MealListView | `Views/Meal/MealListView.swift` | Scrollable list of all logged meals |
| MealEditView | `Views/Meal/MealEditView.swift` | Edit an existing meal entry |

## Store

`Stores/MealStore.swift` — Manages CRUD operations for meals, syncs with backend API, publishes meal data for feed and nutrition aggregation.
