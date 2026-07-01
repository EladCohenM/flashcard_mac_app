import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case collections = "Collections"
    case practice = "Practice"
    case history = "History"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .collections: "books.vertical"
        case .practice: "rectangle.stack"
        case .history: "clock.arrow.circlepath"
        }
    }
}

struct RootView: View {
    @State private var selection: AppSection? = .collections

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.symbol)
                    .tag(section)
            }
            .navigationTitle("Translate Flashcards")
            .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            switch selection ?? .collections {
            case .collections:
                CollectionsView()
            case .practice:
                PracticeSetupView()
            case .history:
                HistoryView()
            }
        }
    }
}
