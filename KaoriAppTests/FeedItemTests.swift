import XCTest
@testable import KaoriApp

final class FeedItemTests: XCTestCase {

    // MARK: - parseUTCTimestamp

    func testParseValidTimestamp() {
        let date = parseUTCTimestamp("2025-01-15 14:30:00")
        XCTAssertNotNil(date)
    }

    func testParseNilTimestamp() {
        XCTAssertNil(parseUTCTimestamp(nil))
    }

    func testParseInvalidTimestamp() {
        XCTAssertNil(parseUTCTimestamp("not-a-date"))
    }

    // MARK: - formatLocalTime

    func testFormatLocalTimeValid() {
        let result = formatLocalTime("2025-01-15 14:30:00")
        XCTAssertNotNil(result)
        // Should be in HH:mm format
        XCTAssertTrue(result!.count == 5)
        XCTAssertTrue(result!.contains(":"))
    }

    func testFormatLocalTimeNil() {
        XCTAssertNil(formatLocalTime(nil))
    }

    // MARK: - Factory sort priorities

    func testMealSortPriority() {
        let meal = Meal(
            id: 1, date: "2025-01-15", mealType: "lunch", photoPath: nil,
            photoPaths: nil, notes: nil, createdAt: "2025-01-15 12:00:00",
            updatedAt: nil, description: "Test", calories: nil,
            proteinG: nil, carbsG: nil, fatG: nil, isEstimated: nil,
            analysisStatus: nil, confidence: nil
        )
        let item = FeedItem.meal(meal)
        XCTAssertEqual(item.sortPriority, 10)
        XCTAssertEqual(item.cardType, "meal")
    }

    func testSummarySortPriority() {
        let item = FeedItem.summary(text: "Test", date: "2025-01-15")
        XCTAssertEqual(item.sortPriority, 0, "Summary should be pinned with priority 0")
        XCTAssertEqual(item.cardType, "summary")
    }

    func testSummaryIdIsStableAcrossProcessingAndPersistedStates() {
        let processing = FeedItem.summary(text: "", date: "2025-01-15", kind: .weekly)
        let persisted = FeedItem.summary(id: 31, text: "Ready", date: "2025-01-15", kind: .weekly)

        XCTAssertEqual(processing.id, "summary-2025-01-15")
        XCTAssertEqual(persisted.id, "summary-2025-01-15")
    }

    @MainActor
    func testSummaryNavigationIdentityStaysStableAcrossProcessingAndPersistedStates() {
        let module = SummaryCardModule()
        let processing = FeedItem.summary(text: "", date: "2025-01-15", kind: .weekly)
        let persisted = FeedItem.summary(id: 31, text: "Ready", date: "2025-01-15", kind: .weekly)

        XCTAssertTrue(module.canNavigateToFeedDetail(item: processing))
        XCTAssertEqual(
            module.feedDetailNavigationID(item: processing),
            module.feedDetailNavigationID(item: persisted)
        )
    }

    func testPortfolioSortPriority() {
        let summary = PortfolioSummaryResponse(
            date: "2025-01-15", isLive: false, combined: nil,
            accounts: [], topMovers: [], lastUpdated: nil
        )
        let item = FeedItem.portfolio(summary)
        XCTAssertEqual(item.sortPriority, 1)
        XCTAssertEqual(item.cardType, "portfolio")
    }

    func testNutritionSortPriority() {
        let totals = NutritionTotals(totalCal: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
        let item = FeedItem.nutrition(totals, nil, date: "2025-01-15")
        XCTAssertEqual(item.sortPriority, 2)
        XCTAssertEqual(item.cardType, "nutrition")
    }

    func testReminderSortPriority() {
        let reminder = Reminder(
            id: 1, title: "Test", description: nil, dueDate: "2025-01-15",
            originalDate: "2025-01-15", itemType: "todo", isDone: 0,
            doneAt: nil, priority: 1, createdAt: "2025-01-15 10:00:00",
            updatedAt: nil
        )
        let item = FeedItem.reminder(reminder)
        XCTAssertEqual(item.sortPriority, 3)
        XCTAssertEqual(item.cardType, "reminder")
    }

    // MARK: - ID uniqueness

    func testFactoryIdsAreUnique() {
        let meal = Meal(
            id: 1, date: "2025-01-15", mealType: nil, photoPath: nil,
            photoPaths: nil, notes: nil, createdAt: nil, updatedAt: nil,
            description: nil, calories: nil, proteinG: nil, carbsG: nil,
            fatG: nil, isEstimated: nil, analysisStatus: nil, confidence: nil
        )
        let weight = WeightEntry(
            id: 1, date: "2025-01-15", weightKg: 80, notes: nil, createdAt: nil
        )
        let mealItem = FeedItem.meal(meal)
        let weightItem = FeedItem.weight(weight)
        XCTAssertNotEqual(mealItem.id, weightItem.id)
    }
}
