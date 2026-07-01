import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSessionRecord.startedAt, order: .reverse)
    private var sessions: [PracticeSessionRecord]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Practice History",
                        systemImage: "clock",
                        description: Text("Completed and ended sessions will appear here.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            NavigationLink {
                                SessionSummaryView(record: session)
                            } label: {
                                HistoryRow(session: session)
                            }
                            .contextMenu {
                                Button("Delete Session", role: .destructive) {
                                    delete(session)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                modelContext.delete(sessions[index])
                            }
                            try? modelContext.save()
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func delete(_ session: PracticeSessionRecord) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}

private struct HistoryRow: View {
    let session: PracticeSessionRecord

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(session.collectionName)
                    .font(.headline)
                Text("\(session.fromLanguage) → \(session.toLanguage)")
                    .foregroundStyle(.secondary)
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(AppFormatting.accuracy(session.accuracy))
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("\(session.promptsShown) cards · \(AppFormatting.duration(session.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
