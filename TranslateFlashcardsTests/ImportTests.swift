import Foundation
import XCTest
@testable import TranslateFlashcards

final class ImportTests: XCTestCase {
    private let service = ImportService()

    func testParsesUTF8HeaderlessCSV() throws {
        let data = Data("English,Spanish,hello,hola\nEnglish,Spanish,goodbye,adiós\n".utf8)
        let draft = try service.prepare(data: data, filename: "words.csv")

        XCTAssertEqual(draft.validRowCount, 2)
        XCTAssertEqual(draft.cards.count, 2)
        XCTAssertEqual(draft.skippedRowCount, 0)
        XCTAssertEqual(draft.collectionName, "words")
    }

    func testParsesHebrewAndQuotedComma() throws {
        let csv = "אנגלית,עברית,predilection,הַעֲדָפָה\nעברית,אנגלית,סייג,\"Disclaimer, caveat\"\n"
        let draft = try service.prepare(data: Data(csv.utf8), filename: "hebrew.csv")

        XCTAssertEqual(draft.validRowCount, 2)
        XCTAssertTrue(draft.cards.contains { $0.textA.contains("Disclaimer, caveat") || $0.textB.contains("Disclaimer, caveat") })
        XCTAssertEqual(Set(draft.detectedLanguages), Set(["אנגלית", "עברית"]))
    }

    func testDetectsHeaderWithoutDiscardingFirstVocabularyRow() throws {
        let headerCSV = """
        source language,target language,source text,translated text
        English,French,book,livre
        """
        let headerDraft = try service.prepare(data: Data(headerCSV.utf8), filename: "header.csv")
        XCTAssertEqual(headerDraft.validRowCount, 1)

        let vocabularyCSV = """
        English,French,source,target
        French,English,livre,book
        """
        let vocabularyDraft = try service.prepare(data: Data(vocabularyCSV.utf8), filename: "valid.csv")
        XCTAssertEqual(vocabularyDraft.validRowCount, 2)
    }

    func testSkipsMalformedAndEmptyRows() throws {
        let csv = """
        English,French,hello,bonjour
        broken,row

        English,French,,vide
        English,French,goodbye,au revoir,ignored extra value
        """
        let draft = try service.prepare(data: Data(csv.utf8), filename: "mixed.csv")

        XCTAssertEqual(draft.validRowCount, 2)
        XCTAssertEqual(draft.skippedRowCount, 2)
        XCTAssertEqual(draft.cards.count, 2)
    }

    func testCanonicalizesMixedDirections() {
        let rows = [
            ParsedVocabularyRow(
                sourceLanguage: "English",
                targetLanguage: "עברית",
                sourceText: "book",
                targetText: "ספר"
            ),
            ParsedVocabularyRow(
                sourceLanguage: "עברית",
                targetLanguage: "English",
                sourceText: "כלב",
                targetText: "dog"
            )
        ]

        let cards = CardNormalizer().normalize(rows)
        XCTAssertEqual(cards.count, 2)
        XCTAssertTrue(cards.allSatisfy { $0.languageAIdentifier == "english" && $0.languageBIdentifier == "עברית" })
    }

    func testDeduplicatesReversedPair() {
        let rows = [
            ParsedVocabularyRow(
                sourceLanguage: "English",
                targetLanguage: "Hebrew",
                sourceText: "book",
                targetText: "ספר"
            ),
            ParsedVocabularyRow(
                sourceLanguage: "Hebrew",
                targetLanguage: "English",
                sourceText: "ספר",
                targetText: "book"
            )
        ]

        XCTAssertEqual(CardNormalizer().normalize(rows).count, 1)
    }
}
