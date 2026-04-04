# Card: HealthKit Workout (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/HealthKitWorkoutCardModule.swift` |
| cardType | `"healthkit_workout"` |
| icon | `figure.run` |
| accentColor | Green |
| supportsManualCreation | No |
| presentationStyle | N/A (auto-imported from Apple Health) |
| hasFeedDetailView | Yes |
| hasDataListView | No |
| hasSettingsView | No |
| feedSwipeActions | `[.delete]` |
| sortPriority | 10 |

## FeedItem

Factory: `FeedItem.healthkitWorkout(...)`
Payload type: `HealthKitWorkoutPayload` (contains `workout` + optional `ImportedWorkoutMeta`)

## Views

| View | File | Purpose |
|------|------|---------|
| WorkoutFeedCard | `Views/Workout/WorkoutFeedCard.swift` | Compact card in the daily feed (shared with manual workouts) |
| ImportedWorkoutDetailView | `Views/Workout/ImportedWorkoutDetailView.swift` | Read-only detail view for imported HealthKit workouts |

## Store

`Stores/WorkoutStore.swift` — Shared with the manual workout card. Handles persistence and sync for both manual and imported workouts.

## Notes

- Deliberately split into a separate card module from manual workouts to avoid conditional logic bugs in views and stores.
- The backend differentiates manual vs. imported workouts via a `source` field on the workout record.
- These entries are auto-imported from Apple Health; the user cannot create them from the "+" button.
