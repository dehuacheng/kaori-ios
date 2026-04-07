import SwiftUI

/// Presentation style for card creation views.
enum CardPresentationStyle {
    case sheet
    case fullScreenCover
}

/// Declarative swipe action types. FeedView maps these to actual buttons.
enum CardSwipeAction: Hashable {
    case delete
    case regenerate
}

/// Context used when decoding ordinary item-based feed rows from `/api/feed`.
struct CardFeedDecodingContext {
    let decoder: JSONDecoder
    let todayString: String
    let cachedProfile: Profile?
    let isMarketDay: Bool
    let importedWorkoutMeta: (Int) -> ImportedWorkoutMeta?
}

/// Context used when generating singleton or derived feed rows from a date group.
typealias CardFeedDateGroupContext = CardFeedDecodingContext

/// Context for module-owned delete behavior.
struct CardDeleteContext {
    let api: APIClient
    let mealStore: MealStore
    let weightStore: WeightStore
    let workoutStore: WorkoutStore
}

/// Context for module-owned "+" menu behavior.
struct CardAddActionContext {
    let presentCreateModule: @MainActor (String) -> Void
    let createWorkout: @MainActor () async -> Void
    let startSummaryGeneration: @MainActor () async -> Void
}

/// Protocol that every card type in the app must conform to.
///
/// Each `CardModule` encapsulates everything about a card type:
/// identity, behavior flags, and view builders. Adding a new card type
/// means creating a new module — no other files need card-specific switches.
protocol CardModule {
    // MARK: - Identity

    /// Unique identifier matching the backend `CardType` enum.
    var cardType: String { get }

    /// Localization key for the display name (e.g., "tab.meals").
    var displayNameKey: String { get }

    /// SF Symbol name for this card type.
    var iconName: String { get }

    /// Accent color for this card type in the feed.
    var accentColor: Color { get }

    // MARK: - Behavior

    /// Whether this card can be manually created via the "+" menu.
    var supportsManualCreation: Bool { get }

    /// How the creation view is presented (.sheet or .fullScreenCover).
    var presentationStyle: CardPresentationStyle { get }

    /// Swipe actions available on this card in the feed.
    var feedSwipeActions: [CardSwipeAction] { get }

    // MARK: - Capability flags (non-isolated, safe to call from any context)

    /// Whether tapping this card in the feed navigates to a detail view.
    var hasFeedDetailView: Bool { get }

    /// Whether this module provides a data list view for More > Data.
    var hasDataListView: Bool { get }

    /// Whether this module provides a settings view.
    var hasSettingsView: Bool { get }

    // MARK: - View Builders

    /// Build the feed card view for a given `FeedItem`.
    @MainActor @ViewBuilder
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView

    /// Build the detail view when tapping a feed card.
    @MainActor
    func feedDetailView(item: FeedItem) -> AnyView?

    /// Whether this specific feed item should currently navigate to detail.
    @MainActor
    func canNavigateToFeedDetail(item: FeedItem) -> Bool

    /// Stable identity for the detail navigation target for this feed item.
    @MainActor
    func feedDetailNavigationID(item: FeedItem) -> String

    /// Build the creation view (presented from "+"). Return nil if not creatable.
    @MainActor
    func createView(onDismiss: @escaping () -> Void) -> AnyView?

    /// Build the data list view for More > Data. Return nil if no data listing.
    @MainActor
    func dataListView() -> AnyView?

    /// Build the settings view for per-card settings. Return nil if no settings.
    @MainActor
    func settingsView() -> AnyView?

    /// Custom trailing (swipe-left) actions. Return nil to use default enum-based actions.
    @MainActor
    func feedTrailingSwipeContent(item: FeedItem) -> AnyView?

    /// Custom leading (swipe-right) actions. Return nil for no leading swipe.
    @MainActor
    func feedLeadingSwipeContent(item: FeedItem) -> AnyView?

    /// Decode a standard feed item from `/api/feed`.
    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem?

    /// Contribute zero or more singleton/derived feed items for a date group.
    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem]

    /// Handle deletion for this module's feed items.
    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async

    /// Handle the "+" action for this module.
    @MainActor
    func performAddAction(context: CardAddActionContext) async
}

// Default implementations
extension CardModule {
    var presentationStyle: CardPresentationStyle { .sheet }
    var feedSwipeActions: [CardSwipeAction] { [.delete] }
    var hasFeedDetailView: Bool { false }
    var hasDataListView: Bool { false }
    var hasSettingsView: Bool { false }

    @MainActor func feedDetailView(item: FeedItem) -> AnyView? { nil }
    @MainActor func canNavigateToFeedDetail(item: FeedItem) -> Bool { hasFeedDetailView }
    @MainActor func feedDetailNavigationID(item: FeedItem) -> String { item.id }
    @MainActor func createView(onDismiss: @escaping () -> Void) -> AnyView? { nil }
    @MainActor func dataListView() -> AnyView? { nil }
    @MainActor func settingsView() -> AnyView? { nil }
    @MainActor func feedTrailingSwipeContent(item: FeedItem) -> AnyView? { nil }
    @MainActor func feedLeadingSwipeContent(item: FeedItem) -> AnyView? { nil }
    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? { nil }
    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem] { [] }
    @MainActor func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {}

    @MainActor
    func performAddAction(context: CardAddActionContext) async {
        guard supportsManualCreation else { return }
        context.presentCreateModule(cardType)
    }
}
