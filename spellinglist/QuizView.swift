//
//  QuizView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData
import AVFoundation

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quizSession: QuizSession
    let vocabularySet: VocabularySet

    @State private var selectedAnswerIndex: Int?
    @State private var showingFeedback = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showCompletionScreen = false
    @State private var showError = false
    @State private var isLoading = false

    init(vocabularySet: VocabularySet) {
        self.vocabularySet = vocabularySet
        _quizSession = StateObject(wrappedValue: QuizSession())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if quizSession.isQuizComplete {
                    QuizCompletionView(
                        quizSession: quizSession,
                        onRestart: restartQuiz,
                        onSecondChance: startSecondChance,
                        onExit: { dismiss() }
                    )
                } else if !quizSession.questions.isEmpty, let question = currentQuestion {
                    VStack(spacing: 0) {
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)

                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * progress, height: 8)
                                    .animation(.easeInOut, value: progress)
                            }
                        }
                        .frame(height: 8)

                        // Score and question counter
                        HStack {
                            Text("Score: \(quizSession.score)/\(quizSession.questions.count)")
                                .font(.headline)
                                .foregroundColor(.blue)

                            Spacer()

                            Text("Question \(quizSession.currentQuestionIndex + 1) of \(quizSession.questions.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()

                        ScrollView {
                            VStack(spacing: 30) {
                                // Word card
                                VStack(spacing: 15) {
                                    Text("What is the definition of:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Text(question.wordText)
                                        .font(.system(size: 32, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                        .accessibilityLabel("Word: \(question.wordText)")
                                }
                                .padding(.top, 20)
                                .accessibilityElement(children: .combine)

                                // Answer options
                                VStack(spacing: 15) {
                                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                        AnswerButton(
                                            text: option,
                                            isSelected: selectedAnswerIndex == index,
                                            isCorrect: showingFeedback && index == question.correctAnswerIndex,
                                            isWrong: showingFeedback && selectedAnswerIndex == index && index != question.correctAnswerIndex,
                                            action: {
                                                selectAnswer(index)
                                            }
                                        )
                                        .disabled(showingFeedback)
                                    }
                                }
                            }
                            .padding()
                        }

                        // Next button
                        if showingFeedback {
                            Button(action: nextQuestion) {
                                Text(quizSession.currentQuestionIndex < quizSession.questions.count - 1 ? "Next Question" : "Finish Quiz")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text(isLoading ? "Generating quiz..." : "Loading quiz...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(vocabularySet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        dismiss()
                    }
                }
            }
            .alert("Quiz Generation Error", isPresented: $showError) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(quizSession.generationError ?? "Failed to generate quiz")
            }
        }
        .task {
            if quizSession.questions.isEmpty && !isLoading {
                isLoading = true
                let success = await quizSession.generateQuiz(from: vocabularySet.words)
                isLoading = false

                if !success {
                    showError = true
                }
            }
        }
    }

    private var currentQuestion: QuizQuestion? {
        guard !quizSession.questions.isEmpty,
              quizSession.currentQuestionIndex >= 0,
              quizSession.currentQuestionIndex < quizSession.questions.count else {
            return nil
        }
        return quizSession.questions[quizSession.currentQuestionIndex]
    }

    private var currentWord: VocabularyWord? {
        guard let question = currentQuestion else { return nil }
        return vocabularySet.words.first { $0.word == question.wordText }
    }

    private var progress: Double {
        guard !quizSession.questions.isEmpty else { return 0 }
        return Double(quizSession.currentQuestionIndex + 1) / Double(quizSession.questions.count)
    }

    private func selectAnswer(_ index: Int) {
        guard !showingFeedback else { return }
        guard let question = currentQuestion else { return }
        guard let word = currentWord else { return }

        selectedAnswerIndex = index
        quizSession.submitAnswer(index, word: word)
        showingFeedback = true

        // Play sound effect
        if index == question.correctAnswerIndex {
            playSound(named: "correct")
            generateHapticFeedback(style: .success)
        } else {
            playSound(named: "incorrect")
            generateHapticFeedback(style: .error)
        }
    }

    private func nextQuestion() {
        withAnimation {
            selectedAnswerIndex = nil
            showingFeedback = false
            quizSession.nextQuestion()
        }
    }

    private func restartQuiz() {
        Task {
            quizSession.reset()
            isLoading = true
            let success = await quizSession.generateQuiz(from: vocabularySet.words)
            isLoading = false

            if !success {
                showError = true
            }
        }
    }

    private func startSecondChance() {
        Task {
            isLoading = true
            let success = await quizSession.startSecondChanceRound()
            isLoading = false

            if !success {
                showError = true
            }
        }
    }

    private func playSound(named soundName: String) {
        // Using louder system sounds
        if soundName == "correct" {
            // Success sound - louder chime
            AudioServicesPlaySystemSound(1016) // SMS tone - louder
            // Also play haptic for more impact
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        } else {
            // Error sound - louder buzz
            AudioServicesPlaySystemSound(1306) // Anticipate - louder error sound
        }
    }

    private func generateHapticFeedback(style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
}

struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .animation(.easeInOut(duration: 0.3), value: isCorrect)
        .animation(.easeInOut(duration: 0.3), value: isWrong)
    }

    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.2)
        } else if isWrong {
            return Color.red.opacity(0.2)
        } else if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }

    private var borderColor: Color {
        if isCorrect {
            return .green
        } else if isWrong {
            return .red
        } else if isSelected {
            return .blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var textColor: Color {
        if isCorrect || isWrong {
            return .primary
        } else {
            return .primary
        }
    }
}

struct QuizCompletionView: View {
    @ObservedObject var quizSession: QuizSession
    let onRestart: () -> Void
    let onSecondChance: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Trophy icon
            Image(systemName: scorePercentage >= 0.8 ? "trophy.fill" : "star.fill")
                .font(.system(size: 80))
                .foregroundColor(scorePercentage >= 0.8 ? .yellow : .blue)
                .padding()

            // Congratulations message
            Text(scorePercentage >= 0.8 ? "Excellent Work!" : "Quiz Complete!")
                .font(.system(size: 32, weight: .bold))

            // Score display
            VStack(spacing: 10) {
                Text("\(quizSession.score) / \(quizSession.questions.count)")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundColor(.blue)

                Text("\(Int(scorePercentage * 100))% Correct")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.blue.opacity(0.1))
            )

            if !quizSession.incorrectWords.isEmpty && !quizSession.isSecondChanceRound {
                VStack(spacing: 10) {
                    Text("\(quizSession.incorrectWords.count) words to review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: onSecondChance) {
                        Label("Practice Missed Words", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                    }
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 15) {
                Button(action: onRestart) {
                    Label("Start New Quiz", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Button(action: onExit) {
                    Text("Back to Home")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var scorePercentage: Double {
        guard !quizSession.questions.isEmpty else { return 0 }
        return Double(quizSession.score) / Double(quizSession.questions.count)
    }
}

#Preview {
    let words = [
        VocabularyWord(word: "Abundant", definition: "Present in great quantity; more than adequate"),
        VocabularyWord(word: "Benevolent", definition: "Well-meaning and kindly"),
        VocabularyWord(word: "Candid", definition: "Truthful and straightforward; frank"),
        VocabularyWord(word: "Diligent", definition: "Having or showing care in one's work")
    ]
    let vocabSet = VocabularySet(name: "Sample Vocabulary", words: words)
    return QuizView(vocabularySet: vocabSet)
        .modelContainer(for: [VocabularyWord.self, VocabularySet.self])
}
