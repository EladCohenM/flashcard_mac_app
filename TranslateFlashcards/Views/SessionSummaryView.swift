import SwiftUI

struct SessionSummaryView: View {
    let record: PracticeSessionRecord
    var close: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Session Summary")
                            .font(.largeTitle.bold())
                        Text(record.collectionName)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("\(record.fromLanguage) → \(record.toLanguage)")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let close {
                        Button("Done", action: close)
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                    }
                }

                HStack(spacing: 16) {
                    SummaryMetric(
                        title: "Accuracy",
                        value: AppFormatting.accuracy(record.accuracy),
                        symbol: "target"
                    )
                    SummaryMetric(
                        title: "Correct",
                        value: "\(record.correctAnswers)",
                        symbol: "checkmark.circle"
                    )
                    SummaryMetric(
                        title: "Incorrect",
                        value: "\(record.incorrectAnswers)",
                        symbol: "xmark.circle"
                    )
                    SummaryMetric(
                        title: "Skipped",
                        value: "\(record.skippedAnswers)",
                        symbol: "forward"
                    )
                }

                Grid(alignment: .leading, horizontalSpacing: 28, verticalSpacing: 8) {
                    GridRow {
                        Text("Date").foregroundStyle(.secondary)
                        Text(record.startedAt.formatted(date: .long, time: .shortened))
                    }
                    GridRow {
                        Text("Duration").foregroundStyle(.secondary)
                        Text(AppFormatting.duration(record.duration))
                    }
                    GridRow {
                        Text("Prompts answered").foregroundStyle(.secondary)
                        Text("\(record.promptsShown)")
                    }
                }

                Divider()

                Text("Review")
                    .font(.title2.bold())

                if record.reviewItems.isEmpty {
                    Label("No missed cards", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 12) {
                        ForEach(record.reviewItems) { item in
                            ReviewItemRow(item: item)
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("Session Summary")
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(.tint)
            Text(value)
                .font(.title.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct ReviewItemRow: View {
    let item: SessionReviewItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(statusTitle, systemImage: statusSymbol)
                    .font(.headline)
                    .foregroundStyle(statusColor)
                Spacer()
            }
            LabeledContent("Prompt") {
                Text(item.prompt)
                    .multilineTextAlignment(ScriptDirection.alignment(for: item.prompt))
            }
            LabeledContent("Expected") {
                Text(item.expected)
                    .multilineTextAlignment(ScriptDirection.alignment(for: item.expected))
            }
            LabeledContent("Your answer") {
                Text(item.submitted.isEmpty ? "—" : item.submitted)
                    .foregroundStyle(item.submitted.isEmpty ? .secondary : .primary)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        switch item.status {
        case .correct: "Correct"
        case .close: "Close"
        case .incorrect: "Incorrect"
        case .skipped: "Skipped"
        }
    }

    private var statusSymbol: String {
        switch item.status {
        case .correct: "checkmark.circle"
        case .close: "equal.circle"
        case .incorrect: "xmark.circle"
        case .skipped: "forward.circle"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .correct: .green
        case .close: .orange
        case .incorrect: .red
        case .skipped: .secondary
        }
    }
}
