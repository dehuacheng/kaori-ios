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

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let workout = try? context.decoder.decode(Workout.self, from: rawData),
              !workout.isImported else {
            return nil
        }
        return .workout(workout)
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        guard let workout = item.payload as? Workout else { return }
        try? await context.workoutStore.deleteWorkout(workout.id)
    }

    @MainActor
    func performAddAction(context: CardAddActionContext) async {
        await context.createWorkout()
    }
}
