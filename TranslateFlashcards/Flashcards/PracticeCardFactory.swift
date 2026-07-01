import Foundation

struct PracticeCardFactory {
    func cards(
        from sourceIdentifier: String,
        to targetIdentifier: String,
        in flashcards: [Flashcard]
    ) -> [PracticeCard] {
        flashcards.compactMap { card in
            if card.languageAIdentifier == sourceIdentifier,
               card.languageBIdentifier == targetIdentifier {
                return PracticeCard(id: card.id, prompt: card.textA, expected: card.textB)
            }
            if card.languageBIdentifier == sourceIdentifier,
               card.languageAIdentifier == targetIdentifier {
                return PracticeCard(id: card.id, prompt: card.textB, expected: card.textA)
            }
            return nil
        }
    }

    func targetOptions(from sourceIdentifier: String?, languages: [LanguageOption]) -> [LanguageOption] {
        languages.filter { $0.identifier != sourceIdentifier }
    }
}
