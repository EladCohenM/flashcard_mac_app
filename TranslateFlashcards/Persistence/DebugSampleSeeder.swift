import Foundation
import SwiftData

@MainActor
enum DebugSampleSeeder {
    static func seedIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<VocabularyCollection>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let rows = [
            ParsedVocabularyRow(
                sourceLanguage: "English",
                targetLanguage: "עברית",
                sourceText: "welcome",
                targetText: "בְּרוּכִים הַבָּאִים"
            ),
            ParsedVocabularyRow(
                sourceLanguage: "עברית",
                targetLanguage: "English",
                sourceText: "ספר",
                targetText: "book"
            ),
            ParsedVocabularyRow(
                sourceLanguage: "English",
                targetLanguage: "עברית",
                sourceText: "practice",
                targetText: "תרגול"
            )
        ]
        let drafts = CardNormalizer().normalize(rows)
        let draft = ImportDraft(
            collectionName: "Sample English & Hebrew",
            originalFilename: "sample.csv",
            cards: drafts,
            validRowCount: drafts.count,
            skippedRowCount: 0,
            detectedLanguages: ["English", "עברית"]
        )
        _ = try? CollectionStore.save(draft: draft, replacing: nil, in: context)
    }
}
