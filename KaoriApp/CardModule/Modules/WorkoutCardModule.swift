import SwiftUI

/// Manual gym workout — user creates via "+", logs exercises/sets/reps.
struct WorkoutCardModule: CardModule {
    let cardType = "workout"
    let displayNameKey = "card.workout"
    let iconName = "dumbbell.fill"
    let accentColor = Color.orange
    let supportsManualCreation = true
    let hasFeedDetailView = true
    let hasDataListView = true
    let hasSettingsView = true
    let presentationStyle = CardPresentationStyle.fullScreenCover

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        guard let workout = item.payload as? Workout else { return AnyView(EmptyView()) }
        return AnyView(WorkoutFeedCard(workout: workout, displayTime: displayTime))
    }

    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView? {
        guard let workout = item.payload as? Workout else { return nil }
        return AnyView(WorkoutDetailView(workoutId: workout.id))
    }

    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView? {
        // Workout creation handled by ContentView (full-screen cover + auto-delete logic)
        nil
    }

    @MainActor
    func dataListView() -> AnyView? {
        AnyView(WorkoutListView())
    }

    @MainActor
    func settingsView() -> AnyView? {
        AnyView(ExerciseManageView())
    }
}
