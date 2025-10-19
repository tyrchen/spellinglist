//
//  Models.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import Foundation
import SwiftData
import Combine

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

    @MainActor
    func generateQuiz(from words: [VocabularyWord], numberOfOptions: Int = 4) async {
        guard words.count >= numberOfOptions else { return }

        // Generate questions on background thread
        let quizQuestions = await Task.detached {
            var questions: [QuizQuestion] = []

            for word in words {
                // Get all other definitions for distractors
                let otherDefinitions = words.filter { $0.id != word.id }.map { $0.definition }

                // Randomly select distractors
                let shuffledOthers = otherDefinitions.shuffled()
                let numberOfDistractors = min(numberOfOptions - 1, shuffledOthers.count)
                let distractors = Array(shuffledOthers.prefix(numberOfDistractors))

                // Create options array with correct answer and distractors
                var options = distractors
                options.append(word.definition)
                options.shuffle()

                // Find the index of the correct answer
                let correctIndex = options.firstIndex(of: word.definition) ?? 0

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

        // Update state on main thread
        self.questions = quizQuestions
        self.currentQuestionIndex = 0
        self.score = 0
        self.incorrectWords = []
        self.isQuizComplete = false
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
    func startSecondChanceRound() async {
        guard !incorrectWords.isEmpty else { return }
        isSecondChanceRound = true
        await generateQuiz(from: incorrectWords)
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
