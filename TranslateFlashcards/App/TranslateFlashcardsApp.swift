import SwiftData
import SwiftUI

@main
struct TranslateFlashcardsApp: App {
    private let container: ModelContainer

    init() {
        let schema = Schema([
            VocabularyCollection.self,
            Flashcard.self,
            PracticeSessionRecord.self,
            SessionReviewItem.self
        ])

        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Unable to initialize local storage: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 920, minHeight: 620)
                .task {
                    #if DEBUG
                    DebugSampleSeeder.seedIfNeeded(in: container.mainContext)
                    #endif
                }
        }
        .modelContainer(container)
        .commands {
            SidebarCommands()
        }
    }
}
