import SwiftUI

struct ImportPreviewView: View {
    @Binding var draft: ImportDraft
    let conflictingCollection: VocabularyCollection?
    let saveNew: () -> Void
    let replace: (VocabularyCollection) -> Void
    let cancel: () -> Void

    @State private var isConfirmingReplacement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Import Preview")
                .font(.largeTitle.bold())

            TextField("Collection name", text: $draft.collectionName)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Collection name")

            HStack(spacing: 28) {
                ImportStat(title: "Valid rows", value: "\(draft.validRowCount)")
                ImportStat(title: "Unique cards", value: "\(draft.cards.count)")
                ImportStat(title: "Skipped", value: "\(draft.skippedRowCount)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Detected Languages").font(.headline)
                Text(draft.detectedLanguages.joined(separator: " · "))
                    .foregroundStyle(.secondary)
            }

            if let conflictingCollection {
                Label(
                    "A collection named “\(conflictingCollection.name)” already exists. Import as a separate collection, or explicitly replace it.",
                    systemImage: "exclamationmark.triangle"
                )
                .foregroundStyle(.orange)
            }

            Text("Sample").font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                ForEach(draft.sampleCards) { card in
                    GridRow {
                        Text(card.languageA).foregroundStyle(.secondary)
                        Text(card.textA)
                            .multilineTextAlignment(ScriptDirection.alignment(for: card.textA))
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.tertiary)
                        Text(card.languageB).foregroundStyle(.secondary)
                        Text(card.textB)
                            .multilineTextAlignment(ScriptDirection.alignment(for: card.textB))
                    }
                }
            }
            .padding()
            .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))

            Spacer()
            HStack {
                Button("Cancel", role: .cancel, action: cancel)
                Spacer()
                if conflictingCollection != nil {
                    Button("Replace Existing…", role: .destructive) {
                        isConfirmingReplacement = true
                    }
                }
                Button(conflictingCollection == nil ? "Import Collection" : "Import as New", action: saveNew)
                    .buttonStyle(.borderedProminent)
                    .disabled(draft.collectionName.trimmed.isEmpty)
            }
        }
        .padding(28)
        .frame(width: 720, height: 560)
        .confirmationDialog(
            "Replace Existing Collection?",
            isPresented: $isConfirmingReplacement
        ) {
            if let conflictingCollection {
                Button("Replace “\(conflictingCollection.name)”", role: .destructive) {
                    replace(conflictingCollection)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The existing collection and its cards will be replaced. Past session history will remain available.")
        }
    }
}

private struct ImportStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
}
