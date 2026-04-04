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
    private(set) var modules: [any CardModule] = []

    func register(_ module: any CardModule) {
        modules.append(module)
    }

    /// Look up a module by its card type identifier.
    func module(for cardType: String) -> (any CardModule)? {
        modules.first { $0.cardType == cardType }
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
}
