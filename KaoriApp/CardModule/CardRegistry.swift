import SwiftUI

/// Central registry of all card modules in the app.
///
/// Injected via `@Environment`. Drives:
/// - FeedView card rendering
/// - "+" menu options
/// - More > Data section
/// - Settings > Card Modules
@Observable
class CardRegistry {
    private var modulesByType: [String: any CardModule] = [:]
    private var orderedCardTypes: [String] = []

    var modules: [any CardModule] {
        orderedCardTypes.compactMap { modulesByType[$0] }
    }

    @discardableResult
    func register(_ module: any CardModule, assertingOnDuplicate: Bool = true) -> Bool {
        if modulesByType[module.cardType] != nil {
            if assertingOnDuplicate {
                assertionFailure("Duplicate card module registration: \(module.cardType)")
            }
            return false
        }

        modulesByType[module.cardType] = module
        orderedCardTypes.append(module.cardType)
        return true
    }

    /// Look up a module by its card type identifier.
    func module(for cardType: String) -> (any CardModule)? {
        modulesByType[cardType]
    }

    /// Modules that support manual creation (for the "+" menu).
    var addableModules: [any CardModule] {
        modules.filter { $0.supportsManualCreation }
    }

    /// Modules that provide a data list view (for More > Data).
    var dataModules: [any CardModule] {
        modules.filter { $0.hasDataListView }
    }

    /// Modules that provide settings (for Settings > Card Modules).
    var settingsModules: [any CardModule] {
        modules.filter { $0.hasSettingsView }
    }

    func decodeFeedItem(from item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        for module in modules {
            if let feedItem = module.decodeFeedItem(item, context: context) {
                return feedItem
            }
        }
        return nil
    }

    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem] {
        modules.flatMap { $0.feedItems(for: group, context: context) }
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async -> Bool {
        guard let module = module(for: item.cardType) else { return false }
        await module.deleteFeedItem(item, context: context)
        return true
    }

    @MainActor
    func performAddAction(for cardType: String, context: CardAddActionContext) async {
        guard let module = module(for: cardType) else { return }
        await module.performAddAction(context: context)
    }
}
