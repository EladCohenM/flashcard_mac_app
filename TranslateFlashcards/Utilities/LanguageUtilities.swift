import Foundation
import SwiftUI

enum LanguageNormalizer {
    static func displayName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
    }

    static func identifier(_ value: String) -> String {
        displayName(value)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}

enum ScriptDirection {
    static func isRightToLeft(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
                return true
            case 0x0041...0x005A, 0x0061...0x007A, 0x00C0...0x02AF:
                return false
            default:
                continue
            }
        }
        return false
    }

    static func layoutDirection(for text: String) -> LayoutDirection {
        isRightToLeft(text) ? .rightToLeft : .leftToRight
    }

    static func alignment(for text: String) -> TextAlignment {
        isRightToLeft(text) ? .trailing : .leading
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
