import XCTest
import SwiftUI
@testable import KaoriApp

private struct TestPayload: Codable {
    let value: String
}

private final class CardActionSpy {
    var deletedItemIDs: [String] = []
    var addActions: [String] = []
}

private struct DecodingCardModule: CardModule {
    let cardType = "test_decoded"
    let displayNameKey = "test.decoded"
    let iconName = "star"
    let accentColor: Color = .blue
    let supportsManualCreation = false

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }

    func decodeFeedItem(_ item: FeedAPIItem, context: CardFeedDecodingContext) -> FeedItem? {
        guard item.type == cardType, let rawData = item.rawData,
              let payload = try? context.decoder.decode(TestPayload.self, from: rawData) else {
            return nil
        }
        return FeedItem(
            id: "decoded-\(item.id)",
            cardType: cardType,
            dateString: item.date,
            sortPriority: 10,
            sortDate: .distantPast,
            displayTime: nil,
            payload: payload
        )
    }
}

private struct ContributingCardModule: CardModule {
    let cardType = "test_singleton"
    let displayNameKey = "test.singleton"
    let iconName = "star.fill"
    let accentColor: Color = .green
    let supportsManualCreation = false

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }

    func feedItems(for group: FeedAPIDateGroup, context: CardFeedDateGroupContext) -> [FeedItem] {
        [
            FeedItem(
                id: "singleton-\(group.date)",
                cardType: cardType,
                dateString: group.date,
                sortPriority: 1,
                sortDate: .distantFuture,
                displayTime: nil,
                payload: group.date
            )
        ]
    }
}

private struct DeletingCardModule: CardModule {
    let cardType = "test_delete"
    let displayNameKey = "test.delete"
    let iconName = "trash"
    let accentColor: Color = .red
    let supportsManualCreation = false
    let spy: CardActionSpy

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func deleteFeedItem(_ item: FeedItem, context: CardDeleteContext) async {
        spy.deletedItemIDs.append(item.id)
    }
}

private struct DirectActionCardModule: CardModule {
    let cardType = "test_direct"
    let displayNameKey = "test.direct"
    let iconName = "bolt"
    let accentColor: Color = .yellow
    let supportsManualCreation = true
    let spy: CardActionSpy

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func performAddAction(context: CardAddActionContext) async {
        spy.addActions.append("direct")
        await context.startSummaryGeneration()
    }
}

private struct WorkoutActionCardModule: CardModule {
    let cardType = "test_workout"
    let displayNameKey = "test.workout"
    let iconName = "flame"
    let accentColor: Color = .orange
    let supportsManualCreation = true
    let spy: CardActionSpy

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func performAddAction(context: CardAddActionContext) async {
        spy.addActions.append("workout")
        await context.createWorkout()
    }
}

private struct SheetActionCardModule: CardModule {
    let cardType = "sheet_card"
    let displayNameKey = "test.sheet"
    let iconName = "square.and.pencil"
    let accentColor: Color = .purple
    let supportsManualCreation = true

    @MainActor
    func feedCardView(item: FeedItem, displayTime: String?) -> AnyView {
        AnyView(EmptyView())
    }
}

final class CardArchitectureTests: XCTestCase {
    private func makeAPI() -> APIClient {
        APIClient(config: AppConfig())
    }

    private func makeFeedStore(registry: CardRegistry) -> FeedStore {
        FeedStore(api: makeAPI(), cardRegistry: registry)
    }

    private func makeFeedAPIItem(type: String, payloadJSON: String, date: String = "2025-01-15") throws -> FeedAPIItem {
        let json = """
        {
          "type": "\(type)",
          "id": 1,
          "date": "\(date)",
          "created_at": "2025-01-15 08:00:00",
          "data": \(payloadJSON)
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(FeedAPIItem.self, from: Data(json.utf8))
    }

    func testFeedStoreUsesModuleDecodingAndDateGroupContribution() throws {
        let registry = CardRegistry()
        registry.register(DecodingCardModule())
        registry.register(ContributingCardModule())

        let store = makeFeedStore(registry: registry)
        let item = try makeFeedAPIItem(type: "test_decoded", payloadJSON: #"{"value":"hello"}"#)
        let response = FeedAPIResponse(
            dates: [
                FeedAPIDateGroup(
                    date: "2025-01-15",
                    items: [item],
                    nutritionTotals: nil,
                    summary: nil,
                    portfolio: nil,
                    weather: nil
                )
            ],
            cardPreferences: nil
        )

        store.applyFeedResponse(response)

        XCTAssertEqual(Set(store.feedItems.map(\.id)), ["decoded-1", "singleton-2025-01-15"])
        XCTAssertEqual(Set(store.feedItems.map(\.cardType)), ["test_decoded", "test_singleton"])
    }

    func testWeatherForecastCardIsFiledUnderNextDaySection() {
        let module = WeatherCardModule()
        let weather = WeatherResponse(
            current: WeatherData(
                date: "2025-01-15",
                weatherType: "current",
                temperature: 10,
                feelsLike: nil,
                tempHigh: nil,
                tempLow: nil,
                humidity: nil,
                windSpeed: nil,
                weatherCode: nil,
                condition: "Clear",
                icon: "sun.max.fill",
                precipitation: nil,
                uvIndex: nil,
                sunrise: nil,
                sunset: nil
            ),
            forecast: WeatherData(
                date: "2025-01-15",
                weatherType: "forecast",
                temperature: nil,
                feelsLike: nil,
                tempHigh: 14,
                tempLow: 6,
                humidity: nil,
                windSpeed: nil,
                weatherCode: nil,
                condition: "Cloudy",
                icon: "cloud.fill",
                precipitation: nil,
                uvIndex: nil,
                sunrise: nil,
                sunset: nil
            ),
            location: nil,
            isLive: true
        )
        let group = FeedAPIDateGroup(
            date: "2025-01-14",
            items: [],
            nutritionTotals: nil,
            summary: nil,
            portfolio: nil,
            weather: weather
        )

        let items = module.feedItems(
            for: group,
            context: CardFeedDecodingContext(
                decoder: JSONDecoder(),
                todayString: "2025-01-15",
                cachedProfile: nil,
                isMarketDay: true,
                importedWorkoutMeta: { _ in nil }
            )
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first(where: { $0.id == "weather-current-2025-01-15" })?.dateString, "2025-01-15")
        XCTAssertEqual(items.first(where: { $0.cardType == "weather" && $0.id.hasPrefix("weather-forecast-") })?.dateString, "2025-01-16")
    }

    func testPastWeatherGroupDoesNotGenerateAnotherTomorrowForecastCard() {
        let module = WeatherCardModule()
        let weather = WeatherResponse(
            current: WeatherData(
                date: "2025-01-14",
                weatherType: "current",
                temperature: 8,
                feelsLike: nil,
                tempHigh: nil,
                tempLow: nil,
                humidity: nil,
                windSpeed: nil,
                weatherCode: nil,
                condition: "Clear",
                icon: "sun.max.fill",
                precipitation: nil,
                uvIndex: nil,
                sunrise: nil,
                sunset: nil
            ),
            forecast: WeatherData(
                date: "2025-01-15",
                weatherType: "forecast",
                temperature: nil,
                feelsLike: nil,
                tempHigh: 11,
                tempLow: 4,
                humidity: nil,
                windSpeed: nil,
                weatherCode: nil,
                condition: "Cloudy",
                icon: "cloud.fill",
                precipitation: nil,
                uvIndex: nil,
                sunrise: nil,
                sunset: nil
            ),
            location: nil,
            isLive: false
        )
        let group = FeedAPIDateGroup(
            date: "2025-01-14",
            items: [],
            nutritionTotals: nil,
            summary: nil,
            portfolio: nil,
            weather: weather
        )

        let items = module.feedItems(
            for: group,
            context: CardFeedDecodingContext(
                decoder: JSONDecoder(),
                todayString: "2025-01-15",
                cachedProfile: nil,
                isMarketDay: true,
                importedWorkoutMeta: { _ in nil }
            )
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.id, "weather-current-2025-01-14")
    }

    func testFeedStoreDelegatesDeletionToOwningModule() async {
        let spy = CardActionSpy()
        let registry = CardRegistry()
        registry.register(DeletingCardModule(spy: spy))

        let store = makeFeedStore(registry: registry)
        store.feedItems = [
            FeedItem(
                id: "delete-me",
                cardType: "test_delete",
                dateString: "2025-01-15",
                sortPriority: 10,
                sortDate: .distantPast,
                displayTime: nil,
                payload: "payload"
            )
        ]

        let api = makeAPI()
        await store.deleteItem(
            store.feedItems[0],
            mealStore: MealStore(api: api),
            weightStore: WeightStore(api: api),
            workoutStore: WorkoutStore(api: api)
        )

        XCTAssertEqual(spy.deletedItemIDs, ["delete-me"])
        XCTAssertTrue(store.feedItems.isEmpty)
    }

    @MainActor
    func testDefaultAddActionPresentsModuleSheet() async {
        let registry = CardRegistry()
        registry.register(SheetActionCardModule())

        var presentedCardType: String?
        await registry.performAddAction(
            for: "sheet_card",
            context: CardAddActionContext(
                presentCreateModule: { presentedCardType = $0 },
                createWorkout: {},
                startSummaryGeneration: {}
            )
        )

        XCTAssertEqual(presentedCardType, "sheet_card")
    }

    @MainActor
    func testCustomAddActionsCanTriggerDirectAndWorkoutFlows() async {
        let spy = CardActionSpy()
        let registry = CardRegistry()
        registry.register(DirectActionCardModule(spy: spy))
        registry.register(WorkoutActionCardModule(spy: spy))

        var directCalls = 0
        var workoutCalls = 0

        let context = CardAddActionContext(
            presentCreateModule: { _ in XCTFail("Custom add action should not present a sheet") },
            createWorkout: { workoutCalls += 1 },
            startSummaryGeneration: { directCalls += 1 }
        )

        await registry.performAddAction(for: "test_direct", context: context)
        await registry.performAddAction(for: "test_workout", context: context)

        XCTAssertEqual(spy.addActions, ["direct", "workout"])
        XCTAssertEqual(directCalls, 1)
        XCTAssertEqual(workoutCalls, 1)
    }

    func testAuditLocalizationKeysExistInBothLanguages() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let enURL = repoRoot.appendingPathComponent("KaoriApp/Localization/en.json")
        let zhURL = repoRoot.appendingPathComponent("KaoriApp/Localization/zh-Hans.json")

        let en = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: enURL))
        let zh = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: zhURL))

        let keys = [
            "weight.deltaVsAvg",
            "portfolio.topMoversPrefix",
            "weather.uv.low",
            "weather.uv.moderate",
            "weather.uv.high",
            "weather.uv.veryHigh",
            "weather.uv.extreme",
            "reminder.overdue",
            "reminder.fromDate"
        ]

        for key in keys {
            XCTAssertNotNil(en[key], "Missing English localization for \(key)")
            XCTAssertNotNil(zh[key], "Missing Simplified Chinese localization for \(key)")
        }
    }

    func testSharedFilesDoNotReintroduceCentralCardBranches() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let feedStoreSource = try String(
            contentsOf: repoRoot.appendingPathComponent("KaoriApp/Stores/FeedStore.swift")
        )
        let appSource = try String(
            contentsOf: repoRoot.appendingPathComponent("KaoriApp/KaoriApp.swift")
        )

        let forbiddenFeedStoreSnippets = [
            "switch item.type",
            "if let meal = item.payload as? Meal",
            "if let entry = item.payload as? WeightEntry",
            "if let workout = item.payload as? Workout",
            "if let p = item.payload as? HealthKitWorkoutPayload",
            "if let post = item.payload as? Post",
            "if let reminder = item.payload as? Reminder"
        ]
        let forbiddenAppSnippets = [
            "private func handleAddAction",
            "case \"meal\":",
            "case \"weight\":",
            "case \"workout\":",
            "case \"summary\":"
        ]

        for snippet in forbiddenFeedStoreSnippets {
            XCTAssertFalse(feedStoreSource.contains(snippet), "FeedStore reintroduced forbidden snippet: \(snippet)")
        }
        for snippet in forbiddenAppSnippets {
            XCTAssertFalse(appSource.contains(snippet), "KaoriApp.swift reintroduced forbidden snippet: \(snippet)")
        }
    }
}
