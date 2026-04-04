# Card: Workout (iOS)

## Module

| Property | Value |
|----------|-------|
| File | `CardModule/Modules/WorkoutCardModule.swift` |
| cardType | `"workout"` |
| icon | `dumbbell.fill` |
| accentColor | Orange |
| supportsManualCreation | Yes |
| presentationStyle | `.fullScreenCover` |
| hasFeedDetailView | Yes |
| hasDataListView | Yes |
| hasSettingsView | Yes |
| feedSwipeActions | `[.delete]` |
| sortPriority | 10 |

## FeedItem

Factory: `FeedItem.workout(...)`
Payload type: `Workout` (directly, not wrapped)

## Views

| View | File | Purpose |
|------|------|---------|
| WorkoutFeedCard | `Views/Workout/WorkoutFeedCard.swift` | Compact card shown in the daily feed |
| WorkoutDetailView | `Views/Workout/WorkoutDetailView.swift` | Full detail view with exercises and sets |
| WorkoutListView | `Views/Workout/WorkoutListView.swift` | Scrollable list of all logged workouts |
| ExerciseManageView | `Views/Workout/ExerciseManageView.swift` | Settings view for managing exercise definitions |

## Store

`Stores/WorkoutStore.swift` — Manages workout CRUD, exercise library, and set tracking. Syncs with backend API.

## Notes

- Creation opens a `.fullScreenCover` instead of a sheet to provide a full workout logging experience.
- A blank workout (no exercises added) is auto-deleted on dismiss to prevent empty entries from polluting the feed.
