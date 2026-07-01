# Translate Flashcards

Translate Flashcards is a native, offline macOS app for importing Google Translate saved-word CSV files and practicing translations in either direction. It uses SwiftUI for the interface and SwiftData for local persistence.

## Requirements and running

- macOS 14 or later
- Xcode 15 or later
- No network connection, account, or API key

Open `TranslateFlashcards.xcodeproj` in Xcode, select the **TranslateFlashcards** scheme, and run the macOS target. Run tests with **Product → Test** (`⌘U`). The repository also includes `Package.swift` so core builds and tests can be run with `swift build` and `swift test` when a matching macOS Swift toolchain is active.

In Debug builds, the app creates a small English/Hebrew sample collection only when the local store contains no collections.

## CSV format

Files must be UTF-8 CSV. A header is optional. The first four columns are:

1. Source language name
2. Target language name
3. Source text
4. Translated text

Quoted fields, escaped quotes, embedded commas, CRLF line endings, Hebrew, and other Unicode scripts are supported. Extra columns are ignored. Blank rows are ignored; incomplete rows are reported as skipped in the import preview.

```csv
English,עברית,predilection,הַעֲדָפָה
עברית,English,סייג,Disclaimer
```

## Canonical normalization

Each imported row is converted from a directional row into a canonical language pair. Trimmed, Unicode-normalized language identifiers are sorted into a stable order, and their corresponding texts are stored in that same order. This lets one stored pair generate practice cards in either direction.

Exact duplicate text pairs are removed even when one CSV row reverses the source and target languages. Different translations remain separate cards.

Answer checks are local and deterministic. They ignore case, repeated whitespace, punctuation, Unicode composition differences, and combining marks such as Hebrew niqqud. Expected answers can contain alternatives separated by semicolons, slashes, or commas. Similar answers can be marked “close,” but remain incorrect.

## Local data

Collections, cards, and immutable session-history snapshots are stored by SwiftData in the app’s macOS application-support container. Deleting a collection deletes its cards but preserves historical session summaries, including the collection name at the time of practice.

## Current limitations

- Language identity is based on normalized labels from the CSV. Synonyms in different languages (for example, `English` and `אנגלית`) are not automatically mapped to one language.
- CSV files must be UTF-8.
- Matching is text based; it does not perform stemming, grammar analysis, or online translation.
- The app has local persistence only—there is no sync, backup service, or account.
