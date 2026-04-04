import SwiftUI

/// Imported Apple Health workout — read-only summary (duration, calories, distance, pace).
struct HealthKitWorkoutCardModule: CardModule {
    let cardType = "healthkit_workout"
    let displayNameKey = "card.healthkitWorkout"
    let iconName = "figure.run"
    let accentColor = Color.green
    let supportsManualCreation = false
    let hasFeedDetailView = true

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let p = item.payload as? HealthKitWorkoutPayload else { return AnyView(EmptyView()) }
        return AnyView(WorkoutFeedCard(workout: p.workout, displayTime: displayTime))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let p = item.payload as? HealthKitWorkoutPayload else { return nil }
        if let meta = p.meta {
            return AnyView(ImportedWorkoutDetailView(workoutId: p.workout.id, meta: meta))
        }
        // Fallback if meta is missing — still show imported detail with basic info
        return AnyView(WorkoutDetailView(workoutId: p.workout.id))
    }
}
