import Foundation

struct CardNormalizer {
    func normalize(_ rows: [ParsedVocabularyRow]) -> [CanonicalCardDraft] {
        var seen = Set<String>()
        var cards: [CanonicalCardDraft] = []

        for row in rows {
            let sourceLanguage = LanguageNormalizer.displayName(row.sourceLanguage)
            let targetLanguage = LanguageNormalizer.displayName(row.targetLanguage)
            let sourceIdentifier = LanguageNormalizer.identifier(sourceLanguage)
            let targetIdentifier = LanguageNormalizer.identifier(targetLanguage)
            guard sourceIdentifier != targetIdentifier else { continue }

            let sourceComesFirst = compare(
                sourceIdentifier,
                sourceLanguage,
                targetIdentifier,
                targetLanguage
            )

            let card = sourceComesFirst
                ? CanonicalCardDraft(
                    languageA: sourceLanguage,
                    languageAIdentifier: sourceIdentifier,
                    textA: row.sourceText.precomposedStringWithCanonicalMapping,
                    languageB: targetLanguage,
                    languageBIdentifier: targetIdentifier,
                    textB: row.targetText.precomposedStringWithCanonicalMapping
                )
                : CanonicalCardDraft(
                    languageA: targetLanguage,
                    languageAIdentifier: targetIdentifier,
                    textA: row.targetText.precomposedStringWithCanonicalMapping,
                    languageB: sourceLanguage,
                    languageBIdentifier: sourceIdentifier,
                    textB: row.sourceText.precomposedStringWithCanonicalMapping
                )

            let key = [
                card.languageAIdentifier,
                exactKey(card.textA),
                card.languageBIdentifier,
                exactKey(card.textB)
            ].joined(separator: "\u{001F}")

            if seen.insert(key).inserted {
                cards.append(card)
            }
        }
        return cards
    }

    private func compare(
        _ lhsIdentifier: String,
        _ lhsDisplay: String,
        _ rhsIdentifier: String,
        _ rhsDisplay: String
    ) -> Bool {
        if lhsIdentifier != rhsIdentifier {
            return lhsIdentifier < rhsIdentifier
        }
        return lhsDisplay < rhsDisplay
    }

    private func exactKey(_ value: String) -> String {
        value.trimmed.precomposedStringWithCanonicalMapping
    }
}
