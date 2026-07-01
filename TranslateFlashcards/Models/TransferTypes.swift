import Foundation

struct ParsedVocabularyRow: Equatable {
    let sourceLanguage: String
    let targetLanguage: String
    let sourceText: String
    let targetText: String
}

struct CanonicalCardDraft: Identifiable, Equatable {
    let id: UUID
    let languageA: String
    let languageAIdentifier: String
    let textA: String
    let languageB: String
    let languageBIdentifier: String
    let textB: String

    init(
        id: UUID = UUID(),
        languageA: String,
        languageAIdentifier: String,
        textA: String,
        languageB: String,
        languageBIdentifier: String,
        textB: String
    ) {
        self.id = id
        self.languageA = languageA
        self.languageAIdentifier = languageAIdentifier
        self.textA = textA
        self.languageB = languageB
        self.languageBIdentifier = languageBIdentifier
        self.textB = textB
    }
}

struct ImportDraft {
    var collectionName: String
    let originalFilename: String
    let cards: [CanonicalCardDraft]
    let validRowCount: Int
    let skippedRowCount: Int
    let detectedLanguages: [String]

    var sampleCards: [CanonicalCardDraft] { Array(cards.prefix(6)) }
}

struct PracticeCard: Identifiable, Equatable {
    let id: UUID
    let prompt: String
    let expected: String
}

enum SessionLengthChoice: String, CaseIterable, Identifiable {
    case ten = "10 cards"
    case twenty = "20 cards"
    case all = "All cards"

    var id: String { rawValue }

    func count(available: Int) -> Int {
        switch self {
        case .ten: min(10, available)
        case .twenty: min(20, available)
        case .all: available
        }
    }
}

struct AnswerEvaluation: Equatable {
    let isCorrect: Bool
    let isClose: Bool
    let matchedVariant: String?
}
