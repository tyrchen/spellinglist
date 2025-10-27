//
//  Models.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import Foundation
import SwiftData
import Combine
import os.log

@Model
class VocabularyWord {
    @Attribute(.unique) var id: UUID
    var word: String
    var definition: String
    var dateAdded: Date
    var timesCorrect: Int
    var timesIncorrect: Int

    @Relationship(deleteRule: .nullify, inverse: \VocabularySet.words)
    var vocabularySet: VocabularySet?

    init(word: String, definition: String) {
        self.id = UUID()
        self.word = word
        self.definition = definition
        self.dateAdded = Date()
        self.timesCorrect = 0
        self.timesIncorrect = 0
    }
}

@Model
class VocabularySet {
    @Attribute(.unique) var id: UUID
    var name: String
    var dateCreated: Date
    var sourceFileName: String?

    @Relationship(deleteRule: .cascade)
    var words: [VocabularyWord]

    init(name: String, sourceFileName: String? = nil, words: [VocabularyWord] = []) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.sourceFileName = sourceFileName
        self.words = words
    }
}

struct QuizQuestion: Identifiable {
    let id = UUID()
    let wordText: String
    let correctDefinition: String
    let options: [String]
    let correctAnswerIndex: Int
    var userAnswerIndex: Int?
    var isCorrect: Bool {
        guard let userAnswer = userAnswerIndex else { return false }
        return userAnswer == correctAnswerIndex
    }
}

class QuizSession: ObservableObject {
    @Published var currentQuestionIndex = 0
    @Published var questions: [QuizQuestion] = []
    @Published var score = 0
    @Published var incorrectWords: [VocabularyWord] = []
    @Published var isQuizComplete = false
    @Published var isSecondChanceRound = false
    @Published var generationError: String?

    private let logger = Logger(subsystem: "com.spellinglist.app", category: "QuizSession")

    @MainActor
    func generateQuiz(from words: [VocabularyWord], numberOfOptions: Int = 4) async -> Bool {
        // Clear any previous error
        generationError = nil

        // Validate minimum word count
        guard !words.isEmpty else {
            generationError = "Cannot generate quiz: No vocabulary words available."
            return false
        }

        // Need at least 2 words for a quiz (1 question with 1 correct answer and 1 distractor)
        guard words.count >= 2 else {
            generationError = "Cannot generate quiz: Need at least 2 vocabulary words. Currently have \(words.count)."
            return false
        }

        // Adjust numberOfOptions if we don't have enough words
        let effectiveNumberOfOptions = min(numberOfOptions, words.count)

        // If we adjusted, log it (but don't fail)
        if effectiveNumberOfOptions < numberOfOptions {
            logger.info("Adjusted quiz options from \(numberOfOptions) to \(effectiveNumberOfOptions) based on available words")
        }

        // Generate questions on background thread
        let quizQuestions = await Task.detached { [logger] in
            var questions: [QuizQuestion] = []

            for word in words {
                // Get all other definitions for distractors
                let otherDefinitions = words.filter { $0.id != word.id }.map { $0.definition }

                // Randomly select distractors
                let shuffledOthers = otherDefinitions.shuffled()
                let numberOfDistractors = min(effectiveNumberOfOptions - 1, shuffledOthers.count)
                let distractors = Array(shuffledOthers.prefix(numberOfDistractors))

                // Create options array with correct answer and distractors
                var options = distractors
                options.append(word.definition)
                options.shuffle()

                // Find the index of the correct answer
                guard let correctIndex = options.firstIndex(of: word.definition) else {
                    // This should never happen, but handle it gracefully
                    logger.warning("Could not find correct answer in options for word: \(word.word)")
                    continue
                }

                let question = QuizQuestion(
                    wordText: word.word,
                    correctDefinition: word.definition,
                    options: options,
                    correctAnswerIndex: correctIndex
                )

                questions.append(question)
            }

            return questions.shuffled()
        }.value

        // Validate we actually generated questions
        guard !quizQuestions.isEmpty else {
            generationError = "Failed to generate quiz questions. Please try again."
            return false
        }

        // Update state on main thread
        self.questions = quizQuestions
        self.currentQuestionIndex = 0
        self.score = 0
        self.incorrectWords = []
        self.isQuizComplete = false

        return true
    }

    func submitAnswer(_ answerIndex: Int, word: VocabularyWord) {
        guard currentQuestionIndex < questions.count else { return }

        questions[currentQuestionIndex].userAnswerIndex = answerIndex

        if questions[currentQuestionIndex].isCorrect {
            score += 1
            word.timesCorrect += 1
        } else {
            incorrectWords.append(word)
            word.timesIncorrect += 1
        }
    }

    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            completeQuiz()
        }
    }

    func completeQuiz() {
        isQuizComplete = true
    }

    @MainActor
    func startSecondChanceRound() async -> Bool {
        guard !incorrectWords.isEmpty else {
            generationError = "No incorrect words to review."
            return false
        }
        isSecondChanceRound = true
        return await generateQuiz(from: incorrectWords)
    }

    func reset() {
        currentQuestionIndex = 0
        questions = []
        score = 0
        incorrectWords = []
        isQuizComplete = false
        isSecondChanceRound = false
    }
}
