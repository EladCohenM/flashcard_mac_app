import Foundation

enum ImportError: LocalizedError, Equatable {
    case noValidRows

    var errorDescription: String? {
        switch self {
        case .noValidRows:
            "No valid vocabulary rows were found. Each row needs source language, target language, source text, and translated text."
        }
    }
}

struct ImportService {
    private let parser: CSVParser
    private let normalizer: CardNormalizer

    init(parser: CSVParser = CSVParser(), normalizer: CardNormalizer = CardNormalizer()) {
        self.parser = parser
        self.normalizer = normalizer
    }

    func prepare(data: Data, filename: String) throws -> ImportDraft {
        let rawRows = try parser.parse(data: data)
        let nonblankRows = rawRows.filter { row in
            row.contains { !$0.trimmed.isEmpty }
        }

        var skipped = 0
        var rows: [ParsedVocabularyRow] = []
        var startIndex = 0

        if let first = nonblankRows.first, isLikelyHeader(first) {
            startIndex = 1
        }

        for rawRow in nonblankRows.dropFirst(startIndex) {
            guard rawRow.count >= 4 else {
                skipped += 1
                continue
            }
            let values = rawRow.prefix(4).map(\.trimmed)
            guard values.allSatisfy({ !$0.isEmpty }) else {
                skipped += 1
                continue
            }
            guard LanguageNormalizer.identifier(values[0]) != LanguageNormalizer.identifier(values[1]) else {
                skipped += 1
                continue
            }
            rows.append(
                ParsedVocabularyRow(
                    sourceLanguage: values[0],
                    targetLanguage: values[1],
                    sourceText: values[2],
                    targetText: values[3]
                )
            )
        }

        let cards = normalizer.normalize(rows)
        guard !cards.isEmpty else { throw ImportError.noValidRows }

        let languages = Set(cards.flatMap { [$0.languageA, $0.languageB] })
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        let defaultName = URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent

        return ImportDraft(
            collectionName: defaultName.isEmpty ? "Imported Vocabulary" : defaultName,
            originalFilename: filename,
            cards: cards,
            validRowCount: rows.count,
            skippedRowCount: skipped,
            detectedLanguages: languages
        )
    }

    func isLikelyHeader(_ row: [String]) -> Bool {
        guard row.count >= 4 else { return false }

        let normalized = row.prefix(4).map {
            $0.trimmed
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
        }

        let languageTerms: Set<String> = [
            "source language", "target language", "from language", "to language",
            "source lang", "target lang", "language from", "language to"
        ]
        let textTerms: Set<String> = [
            "source text", "target text", "translated text", "translation",
            "original text", "text", "source", "target"
        ]

        var score = 0
        if languageTerms.contains(normalized[0]) || normalized[0] == "language" { score += 1 }
        if languageTerms.contains(normalized[1]) || normalized[1] == "language" { score += 1 }
        if textTerms.contains(normalized[2]) { score += 1 }
        if textTerms.contains(normalized[3]) { score += 1 }
        return score >= 3
    }
}
