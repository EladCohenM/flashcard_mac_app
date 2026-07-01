import Foundation
import SwiftData

@Model
final class VocabularyCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var importedAt: Date
    var originalFilename: String
    @Relationship(deleteRule: .cascade, inverse: \Flashcard.collection)
    var cards: [Flashcard]

    init(
        id: UUID = UUID(),
        name: String,
        importedAt: Date = .now,
        originalFilename: String,
        cards: [Flashcard] = []
    ) {
        self.id = id
        self.name = name
        self.importedAt = importedAt
        self.originalFilename = originalFilename
        self.cards = cards
    }

    var availableLanguages: [LanguageOption] {
        var values: [String: String] = [:]
        for card in cards {
            values[card.languageAIdentifier] = card.languageA
            values[card.languageBIdentifier] = card.languageB
        }
        return values
            .map { LanguageOption(identifier: $0.key, displayName: $0.value) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}

@Model
final class Flashcard {
    @Attribute(.unique) var id: UUID
    var languageA: String
    var languageAIdentifier: String
    var textA: String
    var languageB: String
    var languageBIdentifier: String
    var textB: String
    var createdAt: Date
    var collection: VocabularyCollection?

    init(
        id: UUID = UUID(),
        languageA: String,
        languageAIdentifier: String,
        textA: String,
        languageB: String,
        languageBIdentifier: String,
        textB: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.languageA = languageA
        self.languageAIdentifier = languageAIdentifier
        self.textA = textA
        self.languageB = languageB
        self.languageBIdentifier = languageBIdentifier
        self.textB = textB
        self.createdAt = createdAt
    }
}

@Model
final class PracticeSessionRecord {
    @Attribute(.unique) var id: UUID
    var collectionID: UUID?
    var collectionName: String
    var fromLanguage: String
    var toLanguage: String
    var startedAt: Date
    var endedAt: Date
    var promptsShown: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    var skippedAnswers: Int
    @Relationship(deleteRule: .cascade, inverse: \SessionReviewItem.session)
    var reviewItems: [SessionReviewItem]

    init(
        id: UUID = UUID(),
        collectionID: UUID?,
        collectionName: String,
        fromLanguage: String,
        toLanguage: String,
        startedAt: Date,
        endedAt: Date,
        promptsShown: Int,
        correctAnswers: Int,
        incorrectAnswers: Int,
        skippedAnswers: Int,
        reviewItems: [SessionReviewItem]
    ) {
        self.id = id
        self.collectionID = collectionID
        self.collectionName = collectionName
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.promptsShown = promptsShown
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.skippedAnswers = skippedAnswers
        self.reviewItems = reviewItems
    }

    var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt)) }
    var accuracy: Double {
        guard promptsShown > 0 else { return 0 }
        return Double(correctAnswers) / Double(promptsShown)
    }
}

@Model
final class SessionReviewItem {
    @Attribute(.unique) var id: UUID
    var prompt: String
    var expected: String
    var submitted: String
    var statusRawValue: String
    var session: PracticeSessionRecord?

    init(
        id: UUID = UUID(),
        prompt: String,
        expected: String,
        submitted: String,
        status: ReviewStatus
    ) {
        self.id = id
        self.prompt = prompt
        self.expected = expected
        self.submitted = submitted
        self.statusRawValue = status.rawValue
    }

    var status: ReviewStatus {
        ReviewStatus(rawValue: statusRawValue) ?? .incorrect
    }
}

enum ReviewStatus: String, Codable {
    case correct
    case close
    case incorrect
    case skipped
}

struct LanguageOption: Identifiable, Hashable {
    var id: String { identifier }
    let identifier: String
    let displayName: String
}
