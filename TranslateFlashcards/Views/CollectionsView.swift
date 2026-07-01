import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabularyCollection.importedAt, order: .reverse)
    private var collections: [VocabularyCollection]
    @AppStorage("activeCollectionID") private var activeCollectionID = ""

    @State private var selectedCollectionID: UUID?
    @State private var isImporting = false
    @State private var importDraft: ImportDraft?
    @State private var importError: String?
    @State private var renameCollection: VocabularyCollection?
    @State private var renameText = ""
    @State private var deleteCollection: VocabularyCollection?

    var body: some View {
        Group {
            if collections.isEmpty {
                ContentUnavailableView {
                    Label("No Collections", systemImage: "tray")
                } description: {
                    Text("Import a Google Translate CSV to start practicing.")
                } actions: {
                    Button("Import CSV") { isImporting = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                HSplitView {
                    List(selection: $selectedCollectionID) {
                        ForEach(collections) { collection in
                            CollectionRow(
                                collection: collection,
                                isActive: activeCollectionID == collection.id.uuidString
                            )
                            .tag(collection.id)
                            .contextMenu {
                                Button("Set as Active") { setActive(collection) }
                                Button("Rename…") { beginRename(collection) }
                                Divider()
                                Button("Delete…", role: .destructive) {
                                    deleteCollection = collection
                                }
                            }
                        }
                    }
                    .frame(minWidth: 280, idealWidth: 340)

                    if let selectedCollection {
                        CollectionDetailView(
                            collection: selectedCollection,
                            isActive: activeCollectionID == selectedCollection.id.uuidString,
                            setActive: { setActive(selectedCollection) },
                            rename: { beginRename(selectedCollection) },
                            delete: { deleteCollection = selectedCollection }
                        )
                    } else {
                        ContentUnavailableView(
                            "Select a Collection",
                            systemImage: "books.vertical",
                            description: Text("Choose a collection to view its imported vocabulary.")
                        )
                    }
                }
            }
        }
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem {
                Button {
                    isImporting = true
                } label: {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }
                .help("Import a UTF-8 CSV vocabulary file")
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false,
            onCompletion: handleFileImport
        )
        .sheet(
            isPresented: Binding(
                get: { importDraft != nil },
                set: { if !$0 { importDraft = nil } }
            )
        ) {
            if let draftBinding {
                ImportPreviewView(
                    draft: draftBinding,
                    conflictingCollection: conflictingCollection,
                    saveNew: { saveImport(replacing: nil) },
                    replace: { existing in saveImport(replacing: existing) },
                    cancel: { importDraft = nil }
                )
            }
        }
        .alert(
            "Import Failed",
            isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )
        ) {
            Button("OK") { importError = nil }
        } message: {
            Text(importError ?? "The file could not be imported.")
        }
        .alert(
            "Rename Collection",
            isPresented: Binding(
                get: { renameCollection != nil },
                set: { if !$0 { renameCollection = nil } }
            )
        ) {
            TextField("Collection name", text: $renameText)
            Button("Cancel", role: .cancel) { renameCollection = nil }
            Button("Rename") { commitRename() }
                .disabled(renameText.trimmed.isEmpty)
        } message: {
            Text("Choose a clear name for this vocabulary collection.")
        }
        .confirmationDialog(
            "Delete “\(deleteCollection?.name ?? "Collection")”?",
            isPresented: Binding(
                get: { deleteCollection != nil },
                set: { if !$0 { deleteCollection = nil } }
            )
        ) {
            Button("Delete Collection", role: .destructive) { commitDelete() }
            Button("Cancel", role: .cancel) { deleteCollection = nil }
        } message: {
            Text("Its cards will be deleted. Existing session history will be preserved.")
        }
        .onAppear {
            if selectedCollectionID == nil {
                selectedCollectionID = collections.first?.id
            }
            repairActiveSelection()
        }
        .onChange(of: collections.map(\.id)) {
            repairActiveSelection()
            if selectedCollection == nil {
                selectedCollectionID = collections.first?.id
            }
        }
    }

    private var selectedCollection: VocabularyCollection? {
        collections.first { $0.id == selectedCollectionID }
    }

    private var draftBinding: Binding<ImportDraft>? {
        guard importDraft != nil else { return nil }
        return Binding(
            get: { importDraft! },
            set: { importDraft = $0 }
        )
    }

    private var conflictingCollection: VocabularyCollection? {
        guard let name = importDraft?.collectionName.trimmed else { return nil }
        return collections.first {
            $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            importDraft = try ImportService().prepare(data: data, filename: url.lastPathComponent)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func saveImport(replacing existing: VocabularyCollection?) {
        guard var draft = importDraft else { return }
        draft.collectionName = draft.collectionName.trimmed
        guard !draft.collectionName.isEmpty else { return }

        do {
            let saved = try CollectionStore.save(draft: draft, replacing: existing, in: modelContext)
            activeCollectionID = saved.id.uuidString
            selectedCollectionID = saved.id
            importDraft = nil
        } catch {
            importError = "The collection could not be saved. \(error.localizedDescription)"
        }
    }

    private func setActive(_ collection: VocabularyCollection) {
        activeCollectionID = collection.id.uuidString
        selectedCollectionID = collection.id
    }

    private func beginRename(_ collection: VocabularyCollection) {
        renameCollection = collection
        renameText = collection.name
    }

    private func commitRename() {
        guard let collection = renameCollection, !renameText.trimmed.isEmpty else { return }
        collection.name = renameText.trimmed
        try? modelContext.save()
        renameCollection = nil
    }

    private func commitDelete() {
        guard let collection = deleteCollection else { return }
        if activeCollectionID == collection.id.uuidString {
            activeCollectionID = ""
        }
        if selectedCollectionID == collection.id {
            selectedCollectionID = nil
        }
        modelContext.delete(collection)
        try? modelContext.save()
        deleteCollection = nil
        repairActiveSelection()
    }

    private func repairActiveSelection() {
        guard !collections.isEmpty else {
            activeCollectionID = ""
            return
        }
        if !collections.contains(where: { $0.id.uuidString == activeCollectionID }) {
            activeCollectionID = collections[0].id.uuidString
        }
    }
}

private struct CollectionRow: View {
    let collection: VocabularyCollection
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Active collection")
                }
            }
            Text("\(collection.cards.count) cards · \(collection.availableLanguages.map(\.displayName).joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

private struct CollectionDetailView: View {
    let collection: VocabularyCollection
    let isActive: Bool
    let setActive: () -> Void
    let rename: () -> Void
    let delete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(collection.name)
                            .font(.largeTitle.bold())
                        Text("\(collection.cards.count) unique flashcards")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.tint)
                    } else {
                        Button("Set as Active", action: setActive)
                            .buttonStyle(.borderedProminent)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 32, verticalSpacing: 10) {
                    GridRow {
                        Text("Languages").foregroundStyle(.secondary)
                        Text(collection.availableLanguages.map(\.displayName).joined(separator: ", "))
                    }
                    GridRow {
                        Text("Imported").foregroundStyle(.secondary)
                        Text(collection.importedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    GridRow {
                        Text("Source").foregroundStyle(.secondary)
                        Text(collection.originalFilename)
                    }
                }

                Divider()
                Text("Vocabulary Sample")
                    .font(.title2.bold())

                ForEach(collection.cards.prefix(12)) { card in
                    HStack(spacing: 18) {
                        VStack(alignment: ScriptDirection.isRightToLeft(card.textA) ? .trailing : .leading) {
                            Text(card.languageA).font(.caption).foregroundStyle(.secondary)
                            Text(card.textA).font(.title3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(.tertiary)
                        VStack(alignment: ScriptDirection.isRightToLeft(card.textB) ? .trailing : .leading) {
                            Text(card.languageB).font(.caption).foregroundStyle(.secondary)
                            Text(card.textB).font(.title3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }

                HStack {
                    Button("Rename…", action: rename)
                    Button("Delete…", role: .destructive, action: delete)
                }
            }
            .padding(32)
            .frame(maxWidth: 820, alignment: .leading)
        }
    }
}
