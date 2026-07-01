import Foundation

enum CSVParserError: LocalizedError, Equatable {
    case invalidUTF8
    case unterminatedQuotedField

    var errorDescription: String? {
        switch self {
        case .invalidUTF8:
            "The selected file is not valid UTF-8 text."
        case .unterminatedQuotedField:
            "The CSV contains an unterminated quoted field."
        }
    }
}

struct CSVParser {
    func parse(data: Data) throws -> [[String]] {
        guard var text = String(data: data, encoding: .utf8) else {
            throw CSVParserError.invalidUTF8
        }
        if text.first == "\u{FEFF}" {
            text.removeFirst()
        }
        return try parse(text: text)
    }

    func parse(text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var index = text.startIndex

        func finishField() {
            row.append(field)
            field = ""
        }

        func finishRow() {
            finishField()
            rows.append(row)
            row = []
        }

        while index < text.endIndex {
            let character = text[index]
            let next = text.index(after: index)

            if insideQuotes {
                if character == "\"" {
                    if next < text.endIndex, text[next] == "\"" {
                        field.append("\"")
                        index = text.index(after: next)
                        continue
                    }
                    insideQuotes = false
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"":
                    if field.isEmpty {
                        insideQuotes = true
                    } else {
                        field.append(character)
                    }
                case ",":
                    finishField()
                case "\n":
                    finishRow()
                case "\r":
                    if next >= text.endIndex || text[next] != "\n" {
                        finishRow()
                    }
                default:
                    field.append(character)
                }
            }
            index = next
        }

        guard !insideQuotes else {
            throw CSVParserError.unterminatedQuotedField
        }
        if !field.isEmpty || !row.isEmpty {
            finishRow()
        }
        return rows
    }
}
