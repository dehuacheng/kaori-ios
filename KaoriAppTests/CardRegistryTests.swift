import XCTest
import SwiftUI
@testable import KaoriApp

// Minimal mock conforming to CardModule for testing
private struct MockCardModule: CardModule {
    let cardType: String
    let displayNameKey: String = "test"
    let iconName: String = "star"
    let accentColor: Color = .blue
    let supportsManualCreation: Bool
    let hasDataListView: Bool
    let hasSettingsView: Bool

    @MainActor func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }
}

final class CardRegistryTests: XCTestCase {

    func testRegisterAndLookup() {
        let registry = CardRegistry()
        let module = MockCardModule(
            cardType: "test", supportsManualCreation: false,
            hasDataListView: false, hasSettingsView: false
        )
        registry.register(module)

        XCTAssertNotNil(registry.module(for: "test"))
        XCTAssertEqual(registry.module(for: "test")?.cardType, "test")
    }

    func testLookupUnregisteredReturnsNil() {
        let registry = CardRegistry()
        XCTAssertNil(registry.module(for: "nonexistent"))
    }

    func testAddableModulesFiltering() {
        let registry = CardRegistry()
        registry.register(MockCardModule(
            cardType: "creatable", supportsManualCreation: true,
            hasDataListView: false, hasSettingsView: false
        ))
        registry.register(MockCardModule(
            cardType: "noncreatable", supportsManualCreation: false,
            hasDataListView: false, hasSettingsView: false
        ))

        XCTAssertEqual(registry.addableModules.count, 1)
        XCTAssertEqual(registry.addableModules.first?.cardType, "creatable")
    }

    func testDataModulesFiltering() {
        let registry = CardRegistry()
        registry.register(MockCardModule(
            cardType: "withdata", supportsManualCreation: false,
            hasDataListView: true, hasSettingsView: false
        ))
        registry.register(MockCardModule(
            cardType: "nodata", supportsManualCreation: false,
            hasDataListView: false, hasSettingsView: false
        ))

        XCTAssertEqual(registry.dataModules.count, 1)
        XCTAssertEqual(registry.dataModules.first?.cardType, "withdata")
    }

    func testSettingsModulesFiltering() {
        let registry = CardRegistry()
        registry.register(MockCardModule(
            cardType: "withsettings", supportsManualCreation: false,
            hasDataListView: false, hasSettingsView: true
        ))
        registry.register(MockCardModule(
            cardType: "nosettings", supportsManualCreation: false,
            hasDataListView: false, hasSettingsView: false
        ))

        XCTAssertEqual(registry.settingsModules.count, 1)
        XCTAssertEqual(registry.settingsModules.first?.cardType, "withsettings")
    }

    func testDuplicateRegistrationIsRejected() {
        let registry = CardRegistry()
        XCTAssertTrue(registry.register(
            MockCardModule(
                cardType: "duplicate",
                supportsManualCreation: false,
                hasDataListView: false,
                hasSettingsView: false
            ),
            assertingOnDuplicate: false
        ))
        XCTAssertFalse(registry.register(
            MockCardModule(
                cardType: "duplicate",
                supportsManualCreation: true,
                hasDataListView: true,
                hasSettingsView: true
            ),
            assertingOnDuplicate: false
        ))
        XCTAssertEqual(registry.modules.count, 1)
        XCTAssertEqual(registry.module(for: "duplicate")?.supportsManualCreation, false)
    }

    func testModuleOrderingIsStableAcrossSurfaces() {
        let registry = CardRegistry()
        registry.register(MockCardModule(
            cardType: "first", supportsManualCreation: true,
            hasDataListView: true, hasSettingsView: false
        ))
        registry.register(MockCardModule(
            cardType: "second", supportsManualCreation: false,
            hasDataListView: true, hasSettingsView: true
        ))
        registry.register(MockCardModule(
            cardType: "third", supportsManualCreation: true,
            hasDataListView: false, hasSettingsView: true
        ))

        XCTAssertEqual(registry.modules.map { $0.cardType }, ["first", "second", "third"])
        XCTAssertEqual(registry.addableModules.map { $0.cardType }, ["first", "third"])
        XCTAssertEqual(registry.dataModules.map { $0.cardType }, ["first", "second"])
        XCTAssertEqual(registry.settingsModules.map { $0.cardType }, ["second", "third"])
    }
}
