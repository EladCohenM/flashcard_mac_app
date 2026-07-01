// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TranslateFlashcards",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TranslateFlashcards", targets: ["TranslateFlashcards"])
    ],
    targets: [
        .executableTarget(
            name: "TranslateFlashcards",
            path: "TranslateFlashcards"
        ),
        .testTarget(
            name: "TranslateFlashcardsTests",
            dependencies: ["TranslateFlashcards"],
            path: "TranslateFlashcardsTests"
        )
    ]
)
