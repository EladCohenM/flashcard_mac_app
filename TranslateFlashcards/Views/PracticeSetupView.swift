import SwiftData
import SwiftUI

struct PracticeSetupView: View {
    @Query(sort: \VocabularyCollection.importedAt, order: .reverse)
    private var collections: [VocabularyCollection]
    @AppStorage("activeCollectionID") private var activeCollectionID = ""

    @State private var fromLanguageID = ""
    @State private var toLanguageID = ""
    @State private var lengthChoice: SessionLengthChoice = .twenty
    @State private var sessionViewModel: PracticeSessionViewModel?

    private let cardFactory = PracticeCardFactory()

    var body: some View {
        Group {
            if collections.isEmpty {
                ContentUnavailableView(
                    "Import a Collection First",
                    systemImage: "rectangle.stack.badge.plus",
                    description: Text("Open Collections and import a CSV before starting a practice session.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Practice")
                                .font(.largeTitle.bold())
                            Text("Choose a language direction and a session length.")
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            Picker("Collection", selection: $activeCollectionID) {
                                ForEach(collections) { collection in
                                    Text(collection.name).tag(collection.id.uuidString)
                                }
                            }
                            .accessibilityLabel("Selected collection")

                            HStack(spacing: 18) {
                                Picker("From", selection: $fromLanguageID) {
                                    ForEach(availableLanguages) { language in
                                        Text(language.displayName).tag(language.identifier)
                                    }
                                }
                                .accessibilityLabel("From language")

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)

                                Picker("To", selection: $toLanguageID) {
                                    ForEach(targetLanguages) { language in
                                        Text(language.displayName).tag(language.identifier)
                                    }
                                }
                                .accessibilityLabel("To language")
                            }

                            Picker("Session length", selection: $lengthChoice) {
                                ForEach(SessionLengthChoice.allCases) { choice in
                                    Text(choice.rawValue).tag(choice)
                                }
                            }
                            .pickerStyle(.segmented)
                            .accessibilityLabel("Session length")
                        }
                        .padding(24)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 8) {
                            Label(
                                "\(directionCards.count) cards available",
                                systemImage: directionCards.isEmpty ? "exclamationmark.circle" : "checkmark.circle"
                            )
                            .font(.headline)
                            Text(startExplanation)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            startSession()
                        } label: {
                            Label("Start Session", systemImage: "play.fill")
                                .frame(minWidth: 140)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!canStart)
                        .keyboardShortcut(.return, modifiers: [.command])
                    }
                    .padding(40)
                    .frame(maxWidth: 720, alignment: .leading)
                }
            }
        }
        .navigationTitle("Practice")
        .onAppear(perform: repairSelections)
        .onChange(of: activeCollectionID) {
            repairLanguageSelections()
        }
        .onChange(of: fromLanguageID) {
            if toLanguageID == fromLanguageID || !targetLanguages.contains(where: { $0.identifier == toLanguageID }) {
                toLanguageID = targetLanguages.first?.identifier ?? ""
            }
        }
        .onChange(of: collections.map(\.id)) {
            repairSelections()
        }
        .sheet(
            isPresented: Binding(
                get: { sessionViewModel != nil },
                set: { if !$0 { sessionViewModel = nil } }
            )
        ) {
            if let sessionViewModel {
                PracticeSessionView(
                    viewModel: sessionViewModel,
                    close: { self.sessionViewModel = nil }
                )
                .frame(minWidth: 760, minHeight: 600)
            }
        }
    }

    private var selectedCollection: VocabularyCollection? {
        collections.first { $0.id.uuidString == activeCollectionID }
    }

    private var availableLanguages: [LanguageOption] {
        selectedCollection?.availableLanguages ?? []
    }

    private var targetLanguages: [LanguageOption] {
        cardFactory.targetOptions(from: fromLanguageID, languages: availableLanguages)
    }

    private var directionCards: [PracticeCard] {
        guard let collection = selectedCollection else { return [] }
        return cardFactory.cards(
            from: fromLanguageID,
            to: toLanguageID,
            in: collection.cards
        )
    }

    private var canStart: Bool {
        selectedCollection != nil &&
            !directionCards.isEmpty &&
            !fromLanguageID.isEmpty &&
            fromLanguageID != toLanguageID
    }

    private var startExplanation: String {
        if selectedCollection == nil { return "Select an imported collection." }
        if fromLanguageID == toLanguageID { return "Choose two different languages." }
        if directionCards.isEmpty { return "No valid cards exist for this language direction." }
        let count = lengthChoice.count(available: directionCards.count)
        return "This session will include \(count) \(count == 1 ? "card" : "cards"), randomized without repeats."
    }

    private func repairSelections() {
        if !collections.contains(where: { $0.id.uuidString == activeCollectionID }) {
            activeCollectionID = collections.first?.id.uuidString ?? ""
        }
        repairLanguageSelections()
    }

    private func repairLanguageSelections() {
        if !availableLanguages.contains(where: { $0.identifier == fromLanguageID }) {
            fromLanguageID = availableLanguages.first?.identifier ?? ""
        }
        if !targetLanguages.contains(where: { $0.identifier == toLanguageID }) {
            toLanguageID = targetLanguages.first?.identifier ?? ""
        }
    }

    private func startSession() {
        guard let collection = selectedCollection,
              let from = availableLanguages.first(where: { $0.identifier == fromLanguageID }),
              let to = availableLanguages.first(where: { $0.identifier == toLanguageID }),
              canStart else { return }

        sessionViewModel = PracticeSessionViewModel(
            cards: directionCards,
            count: lengthChoice.count(available: directionCards.count),
            collectionID: collection.id,
            collectionName: collection.name,
            fromLanguage: from.displayName,
            toLanguage: to.displayName
        )
    }
}
