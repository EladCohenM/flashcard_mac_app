import SwiftData
import XCTest
@testable import TranslateFlashcards

@MainActor
final class SessionTests: XCTestCase {
    func testSessionMetricsTreatSkippedSeparatelyAndAsNotCorrect() {
        let results = [
            SessionResult(prompt: "one", expected: "uno", submitted: "uno", status: .correct),
            SessionResult(prompt: "two", expected: "dos", submitted: "tres", status: .incorrect),
            SessionResult(prompt: "three", expected: "tres", submitted: "", status: .skipped)
        ]

        let metrics = SessionMetrics.calculate(from: results)
        XCTAssertEqual(metrics.promptsShown, 3)
        XCTAssertEqual(metrics.correct, 1)
        XCTAssertEqual(metrics.incorrect, 1)
        XCTAssertEqual(metrics.skipped, 1)
        XCTAssertEqual(metrics.accuracy, 1.0 / 3.0, accuracy: 0.0001)
    }

    func testSessionRandomizationDoesNotRepeatCards() {
        let cards = (0..<30).map {
            PracticeCard(id: UUID(), prompt: "\($0)", expected: "\($0)")
        }
        let viewModel = PracticeSessionViewModel(
            cards: cards,
            count: 20,
            collectionID: UUID(),
            collectionName: "Numbers",
            fromLanguage: "English",
            toLanguage: "Spanish"
        )

        XCTAssertEqual(viewModel.cards.count, 20)
        XCTAssertEqual(Set(viewModel.cards.map(\.id)).count, 20)
    }

    func testCreatesAndPersistsHistorySnapshot() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: PracticeSessionRecord.self,
            SessionReviewItem.self,
            configurations: configuration
        )
        let viewModel = PracticeSessionViewModel(
            cards: [PracticeCard(id: UUID(), prompt: "book", expected: "libro")],
            count: 1,
            collectionID: UUID(),
            collectionName: "Travel",
            fromLanguage: "English",
            toLanguage: "Spanish",
            shuffled: false
        )
        viewModel.answer = "wrong"
        viewModel.submit()
        viewModel.next()

        let record = viewModel.makeRecord()
        container.mainContext.insert(record)
        try container.mainContext.save()

        let saved = try container.mainContext.fetch(FetchDescriptor<PracticeSessionRecord>())
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].collectionName, "Travel")
        XCTAssertEqual(saved[0].incorrectAnswers, 1)
        XCTAssertEqual(saved[0].reviewItems.first?.prompt, "book")
    }
}
