import XCTest
@testable import TranslateFlashcards

final class FlashcardTests: XCTestCase {
    func testGeneratesCardsInBothDirections() {
        let card = Flashcard(
            languageA: "English",
            languageAIdentifier: "english",
            textA: "book",
            languageB: "עברית",
            languageBIdentifier: "עברית",
            textB: "ספר"
        )
        let factory = PracticeCardFactory()

        let forward = factory.cards(from: "english", to: "עברית", in: [card])
        let reverse = factory.cards(from: "עברית", to: "english", in: [card])

        XCTAssertEqual(forward.first?.prompt, "book")
        XCTAssertEqual(forward.first?.expected, "ספר")
        XCTAssertEqual(reverse.first?.prompt, "ספר")
        XCTAssertEqual(reverse.first?.expected, "book")
    }

    func testExcludesSelectedSourceFromTargetOptions() {
        let options = [
            LanguageOption(identifier: "english", displayName: "English"),
            LanguageOption(identifier: "french", displayName: "French"),
            LanguageOption(identifier: "spanish", displayName: "Spanish")
        ]

        let targets = PracticeCardFactory().targetOptions(from: "english", languages: options)
        XCTAssertEqual(targets.map(\.identifier), ["french", "spanish"])
    }
}

final class AnswerMatcherTests: XCTestCase {
    private let matcher = AnswerMatcher()

    func testCaseDifferences() {
        XCTAssertTrue(matcher.evaluate(submitted: "BOOK", expected: "book").isCorrect)
    }

    func testWhitespaceDifferences() {
        XCTAssertTrue(matcher.evaluate(submitted: "  au   revoir ", expected: "au revoir").isCorrect)
    }

    func testHebrewNiqqudDifferences() {
        XCTAssertTrue(matcher.evaluate(submitted: "העדפה", expected: "הַעֲדָפָה").isCorrect)
    }

    func testPunctuationDifferences() {
        XCTAssertTrue(matcher.evaluate(submitted: "hello", expected: "Hello!").isCorrect)
    }

    func testMultipleAcceptedTranslations() {
        XCTAssertTrue(matcher.evaluate(submitted: "caveat", expected: "warning; caveat / reservation").isCorrect)
    }

    func testIncorrectAnswer() {
        let result = matcher.evaluate(submitted: "table", expected: "book")
        XCTAssertFalse(result.isCorrect)
        XCTAssertFalse(result.isClose)
    }

    func testCloseAnswerRemainsIncorrect() {
        let result = matcher.evaluate(submitted: "boook", expected: "book")
        XCTAssertFalse(result.isCorrect)
        XCTAssertTrue(result.isClose)
    }
}
