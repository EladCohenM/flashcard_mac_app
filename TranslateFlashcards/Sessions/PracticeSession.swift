import Combine
import Foundation

struct SessionResult: Equatable {
    let prompt: String
    let expected: String
    let submitted: String
    let status: ReviewStatus
}

struct SessionMetrics: Equatable {
    let promptsShown: Int
    let correct: Int
    let incorrect: Int
    let skipped: Int

    var accuracy: Double {
        guard promptsShown > 0 else { return 0 }
        return Double(correct) / Double(promptsShown)
    }

    static func calculate(from results: [SessionResult]) -> SessionMetrics {
        SessionMetrics(
            promptsShown: results.count,
            correct: results.filter { $0.status == .correct }.count,
            incorrect: results.filter { $0.status == .incorrect || $0.status == .close }.count,
            skipped: results.filter { $0.status == .skipped }.count
        )
    }
}

@MainActor
final class PracticeSessionViewModel: ObservableObject {
    @Published private(set) var cards: [PracticeCard]
    @Published private(set) var currentIndex = 0
    @Published var answer = ""
    @Published private(set) var feedback: AnswerEvaluation?
    @Published private(set) var results: [SessionResult] = []
    @Published private(set) var isFinished = false

    let collectionID: UUID
    let collectionName: String
    let fromLanguage: String
    let toLanguage: String
    let startedAt: Date
    private let matcher: AnswerMatcher

    init(
        cards: [PracticeCard],
        count: Int,
        collectionID: UUID,
        collectionName: String,
        fromLanguage: String,
        toLanguage: String,
        matcher: AnswerMatcher = AnswerMatcher(),
        shuffled: Bool = true,
        startedAt: Date = .now
    ) {
        let ordered = shuffled ? cards.shuffled() : cards
        self.cards = Array(ordered.prefix(min(count, cards.count)))
        self.collectionID = collectionID
        self.collectionName = collectionName
        self.fromLanguage = fromLanguage
        self.toLanguage = toLanguage
        self.matcher = matcher
        self.startedAt = startedAt
        self.isFinished = self.cards.isEmpty
    }

    var currentCard: PracticeCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var progressText: String {
        guard !cards.isEmpty else { return "0 of 0" }
        return "\(min(currentIndex + 1, cards.count)) of \(cards.count)"
    }

    func submit() {
        guard feedback == nil, let card = currentCard, !answer.trimmed.isEmpty else { return }
        feedback = matcher.evaluate(submitted: answer, expected: card.expected)
    }

    func next() {
        guard let card = currentCard, let feedback else { return }
        let status: ReviewStatus = feedback.isCorrect ? .correct : (feedback.isClose ? .close : .incorrect)
        results.append(
            SessionResult(
                prompt: card.prompt,
                expected: card.expected,
                submitted: answer.trimmed,
                status: status
            )
        )
        advance()
    }

    func skip() {
        guard feedback == nil, let card = currentCard else { return }
        results.append(
            SessionResult(
                prompt: card.prompt,
                expected: card.expected,
                submitted: "",
                status: .skipped
            )
        )
        advance()
    }

    func end() {
        isFinished = true
    }

    func makeRecord(endedAt: Date = .now) -> PracticeSessionRecord {
        let metrics = SessionMetrics.calculate(from: results)
        let reviewItems = results
            .filter { $0.status != .correct }
            .map {
                SessionReviewItem(
                    prompt: $0.prompt,
                    expected: $0.expected,
                    submitted: $0.submitted,
                    status: $0.status
                )
            }
        return PracticeSessionRecord(
            collectionID: collectionID,
            collectionName: collectionName,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            startedAt: startedAt,
            endedAt: endedAt,
            promptsShown: metrics.promptsShown,
            correctAnswers: metrics.correct,
            incorrectAnswers: metrics.incorrect,
            skippedAnswers: metrics.skipped,
            reviewItems: reviewItems
        )
    }

    private func advance() {
        answer = ""
        feedback = nil
        if currentIndex + 1 >= cards.count {
            isFinished = true
        } else {
            currentIndex += 1
        }
    }
}
