import Foundation
import SwiftData

@MainActor
enum CollectionStore {
    static func save(
        draft: ImportDraft,
        replacing existing: VocabularyCollection?,
        in context: ModelContext
    ) throws -> VocabularyCollection {
        if let existing {
            context.delete(existing)
        }

        let collection = VocabularyCollection(
            name: draft.collectionName.trimmed,
            originalFilename: draft.originalFilename
        )
        for cardDraft in draft.cards {
            let card = Flashcard(
                languageA: cardDraft.languageA,
                languageAIdentifier: cardDraft.languageAIdentifier,
                textA: cardDraft.textA,
                languageB: cardDraft.languageB,
                languageBIdentifier: cardDraft.languageBIdentifier,
                textB: cardDraft.textB
            )
            card.collection = collection
            collection.cards.append(card)
        }
        context.insert(collection)
        try context.save()
        return collection
    }
}
