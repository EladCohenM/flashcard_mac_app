import Foundation

struct AnswerMatcher {
    let closeThreshold: Double

    init(closeThreshold: Double = 0.8) {
        self.closeThreshold = closeThreshold
    }

    func evaluate(submitted: String, expected: String) -> AnswerEvaluation {
        let normalizedSubmitted = normalize(submitted)
        let variants = acceptedVariants(expected)

        if let matched = variants.first(where: { normalize($0) == normalizedSubmitted }) {
            return AnswerEvaluation(isCorrect: true, isClose: false, matchedVariant: matched)
        }

        let bestSimilarity = variants
            .map { similarity(normalizedSubmitted, normalize($0)) }
            .max() ?? 0
        let close = normalizedSubmitted.count >= 3 && bestSimilarity >= closeThreshold
        return AnswerEvaluation(isCorrect: false, isClose: close, matchedVariant: nil)
    }

    func acceptedVariants(_ expected: String) -> [String] {
        expected
            .split(whereSeparator: { character in
                character == ";" || character == "/" || character == ","
            })
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
    }

    func normalize(_ value: String) -> String {
        let decomposed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .decomposedStringWithCanonicalMapping

        let filteredScalars = decomposed.unicodeScalars.filter { scalar in
            if CharacterSet.nonBaseCharacters.contains(scalar) {
                return false
            }
            switch scalar.properties.generalCategory {
            case .connectorPunctuation, .dashPunctuation, .openPunctuation,
                 .closePunctuation, .initialPunctuation, .finalPunctuation,
                 .otherPunctuation:
                return false
            default:
                return true
            }
        }

        return String(String.UnicodeScalarView(filteredScalars))
            .precomposedStringWithCanonicalMapping
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private func similarity(_ lhs: String, _ rhs: String) -> Double {
        let maxLength = max(lhs.count, rhs.count)
        guard maxLength > 0 else { return 1 }
        return 1 - Double(levenshteinDistance(lhs, rhs)) / Double(maxLength)
    }

    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        if left.isEmpty { return right.count }
        if right.isEmpty { return left.count }

        var previous = Array(0...right.count)
        for (leftIndex, leftCharacter) in left.enumerated() {
            var current = [leftIndex + 1]
            for (rightIndex, rightCharacter) in right.enumerated() {
                let insertion = current[rightIndex] + 1
                let deletion = previous[rightIndex + 1] + 1
                let substitution = previous[rightIndex] + (leftCharacter == rightCharacter ? 0 : 1)
                current.append(min(insertion, deletion, substitution))
            }
            previous = current
        }
        return previous[right.count]
    }
}
