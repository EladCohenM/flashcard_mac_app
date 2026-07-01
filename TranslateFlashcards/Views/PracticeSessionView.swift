import SwiftData
import SwiftUI

struct PracticeSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: PracticeSessionViewModel
    let close: () -> Void

    @FocusState private var answerFocused: Bool
    @State private var isConfirmingEnd = false
    @State private var savedRecord: PracticeSessionRecord?

    var body: some View {
        Group {
            if let savedRecord {
                SessionSummaryView(record: savedRecord, close: close)
            } else {
                sessionContent
            }
        }
        .onAppear {
            answerFocused = true
            if viewModel.isFinished { saveSessionIfNeeded() }
        }
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished { saveSessionIfNeeded() }
        }
        .interactiveDismissDisabled(savedRecord == nil)
    }

    private var sessionContent: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.progressText)
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
                Button("End Session") { isConfirmingEnd = true }
                    .accessibilityLabel("End practice session")
            }
            .padding(24)

            Divider()

            if let card = viewModel.currentCard {
                VStack(spacing: 28) {
                    Spacer()

                    VStack(spacing: 12) {
                        Text(viewModel.fromLanguage)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text(card.prompt)
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .environment(\.layoutDirection, ScriptDirection.layoutDirection(for: card.prompt))
                            .textSelection(.enabled)
                            .accessibilityLabel("Prompt: \(card.prompt)")
                    }
                    .frame(maxWidth: 640)

                    VStack(spacing: 14) {
                        TextField("Type the \(viewModel.toLanguage) translation", text: $viewModel.answer)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .multilineTextAlignment(
                                ScriptDirection.isRightToLeft(viewModel.answer) ? .trailing : .leading
                            )
                            .environment(
                                \.layoutDirection,
                                ScriptDirection.layoutDirection(for: viewModel.answer)
                            )
                            .focused($answerFocused)
                            .disabled(viewModel.feedback != nil)
                            .onSubmit(handleReturn)
                            .accessibilityLabel("Your translation")

                        if let feedback = viewModel.feedback {
                            FeedbackView(
                                feedback: feedback,
                                expected: card.expected,
                                submitted: viewModel.answer
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .frame(maxWidth: 580)

                    Spacer()

                    HStack {
                        if viewModel.feedback == nil {
                            Button("Skip") { viewModel.skip() }
                                .keyboardShortcut("s", modifiers: [.command])
                            Spacer()
                            Button("Submit") { viewModel.submit() }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.answer.trimmed.isEmpty)
                                .keyboardShortcut(.return, modifiers: [])
                        } else {
                            Spacer()
                            Button("Next Card") {
                                viewModel.next()
                                answerFocused = true
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.return, modifiers: [])
                        }
                    }
                    .frame(maxWidth: 580)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 40)
                .animation(.easeInOut(duration: 0.18), value: viewModel.feedback != nil)
            }
        }
        .confirmationDialog("End this session?", isPresented: $isConfirmingEnd) {
            Button("End and Save", role: .destructive) { viewModel.end() }
            Button("Keep Practicing", role: .cancel) {}
        } message: {
            Text("Completed answers will be saved to history.")
        }
    }

    private func handleReturn() {
        if viewModel.feedback == nil {
            viewModel.submit()
        } else {
            viewModel.next()
            answerFocused = true
        }
    }

    private func saveSessionIfNeeded() {
        guard savedRecord == nil else { return }
        let record = viewModel.makeRecord()
        modelContext.insert(record)
        try? modelContext.save()
        savedRecord = record
    }
}

private struct FeedbackView: View {
    let feedback: AnswerEvaluation
    let expected: String
    let submitted: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(color)

            LabeledContent("Expected") {
                Text(expected)
                    .multilineTextAlignment(ScriptDirection.alignment(for: expected))
                    .textSelection(.enabled)
            }
            LabeledContent("Your answer") {
                Text(submitted)
                    .multilineTextAlignment(ScriptDirection.alignment(for: submitted))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        if feedback.isCorrect { return "Correct" }
        if feedback.isClose { return "Close, but not exact" }
        return "Incorrect"
    }

    private var symbol: String {
        feedback.isCorrect ? "checkmark.circle.fill" : (feedback.isClose ? "equal.circle" : "xmark.circle.fill")
    }

    private var color: Color {
        feedback.isCorrect ? .green : (feedback.isClose ? .orange : .red)
    }
}
