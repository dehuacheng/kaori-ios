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
}

// Default implementations
extension CardModule {
    var presentationStyle: CardPresentationStyle { .sheet }
    var feedSwipeActions: [CardSwipeAction] { [.delete] }
    var hasFeedDetailView: Bool { false }
    var hasDataListView: Bool { false }
    var hasSettingsView: Bool { false }

    @MainActor func feedDetailView(item: FeedItem) -> AnyView? { nil }
    @MainActor func createView(onDismiss: @escaping () -> Void) -> AnyView? { nil }
    @MainActor func dataListView() -> AnyView? { nil }
    @MainActor func settingsView() -> AnyView? { nil }
    @MainActor func feedTrailingSwipeContent(item: FeedItem) -> AnyView? { nil }
    @MainActor func feedLeadingSwipeContent(item: FeedItem) -> AnyView? { nil }
}
