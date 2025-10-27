//
//  QuizSessionTests.swift
//  spellinglistTests
//
//  Created by cynthia on 10/18/25.
//

import XCTest
@testable import spellinglist

@MainActor
final class QuizSessionTests: XCTestCase {

    var quizSession: QuizSession!
    var testWords: [VocabularyWord]!

    override func setUp() async throws {
        try await super.setUp()
        quizSession = QuizSession()

        testWords = [
            VocabularyWord(word: "Abundant", definition: "Present in great quantity"),
            VocabularyWord(word: "Benevolent", definition: "Well-meaning and kindly"),
            VocabularyWord(word: "Candid", definition: "Truthful and straightforward"),
            VocabularyWord(word: "Diligent", definition: "Having care in one's work")
        ]
    }

    override func tearDown() {
        quizSession = nil
        testWords = nil
        super.tearDown()
    }

    // MARK: - Quiz Generation

    func testGenerateQuizCreatesCorrectNumberOfQuestions() async {
        let success = await quizSession.generateQuiz(from: testWords)

        XCTAssertTrue(success)
        XCTAssertEqual(quizSession.questions.count, 4)
        XCTAssertNil(quizSession.generationError)
    }

    func testGenerateQuizWithInsufficientWords() async {
        let singleWord = [VocabularyWord(word: "Test", definition: "Test definition")]

        let success = await quizSession.generateQuiz(from: singleWord, numberOfOptions: 4)

        XCTAssertFalse(success, "Should not generate quiz with insufficient words")
        XCTAssertEqual(quizSession.questions.count, 0)
        XCTAssertNotNil(quizSession.generationError)
    }

    func testGenerateQuizWithEmptyWords() async {
        let success = await quizSession.generateQuiz(from: [], numberOfOptions: 4)

        XCTAssertFalse(success, "Should not generate quiz with empty word list")
        XCTAssertEqual(quizSession.questions.count, 0)
        XCTAssertNotNil(quizSession.generationError)
        XCTAssertTrue(quizSession.generationError?.contains("No vocabulary words") ?? false)
    }

    func testGenerateQuizAdjustsOptionsWhenNotEnoughWords() async {
        let twoWords = [
            VocabularyWord(word: "Word1", definition: "Definition 1"),
            VocabularyWord(word: "Word2", definition: "Definition 2")
        ]

        let success = await quizSession.generateQuiz(from: twoWords, numberOfOptions: 6)

        XCTAssertTrue(success, "Should adjust options and succeed")
        XCTAssertEqual(quizSession.questions.count, 2)
        // Each question should have at most 2 options (based on available words)
        for question in quizSession.questions {
            XCTAssertLessThanOrEqual(question.options.count, 2)
        }
    }

    func testGenerateQuizWithExactMinimumWords() async {
        let twoWords = [
            VocabularyWord(word: "Word1", definition: "Definition 1"),
            VocabularyWord(word: "Word2", definition: "Definition 2")
        ]

        let success = await quizSession.generateQuiz(from: twoWords, numberOfOptions: 2)

        XCTAssertTrue(success)
        XCTAssertEqual(quizSession.questions.count, 2)
        XCTAssertNil(quizSession.generationError)
    }

    func testQuizQuestionsHaveCorrectNumberOfOptions() async {
        _ = await quizSession.generateQuiz(from: testWords, numberOfOptions: 4)

        for question in quizSession.questions {
            XCTAssertEqual(question.options.count, 4)
        }
    }

    func testCorrectAnswerIsInOptions() async {
        _ = await quizSession.generateQuiz(from: testWords)

        for question in quizSession.questions {
            XCTAssertTrue(question.options.contains(question.correctDefinition))
        }
    }

    func testCorrectAnswerIndexPointsToCorrectDefinition() async {
        _ = await quizSession.generateQuiz(from: testWords)

        for question in quizSession.questions {
            XCTAssertEqual(question.options[question.correctAnswerIndex], question.correctDefinition)
        }
    }

    // MARK: - Answer Submission

    func testSubmitCorrectAnswer() async {
        _ = await quizSession.generateQuiz(from: testWords)

        let correctIndex = quizSession.questions[0].correctAnswerIndex
        let word = testWords.first { $0.word == quizSession.questions[0].wordText }!

        quizSession.submitAnswer(correctIndex, word: word)

        XCTAssertEqual(quizSession.score, 1)
        XCTAssertEqual(word.timesCorrect, 1)
        XCTAssertEqual(word.timesIncorrect, 0)
    }

    func testSubmitIncorrectAnswer() async {
        _ = await quizSession.generateQuiz(from: testWords)

        let correctIndex = quizSession.questions[0].correctAnswerIndex
        let wrongIndex = (correctIndex + 1) % quizSession.questions[0].options.count
        let word = testWords.first { $0.word == quizSession.questions[0].wordText }!

        quizSession.submitAnswer(wrongIndex, word: word)

        XCTAssertEqual(quizSession.score, 0)
        XCTAssertEqual(word.timesCorrect, 0)
        XCTAssertEqual(word.timesIncorrect, 1)
        XCTAssertEqual(quizSession.incorrectWords.count, 1)
    }

    // MARK: - Quiz Navigation

    func testNextQuestion() async {
        _ = await quizSession.generateQuiz(from: testWords)

        XCTAssertEqual(quizSession.currentQuestionIndex, 0)

        quizSession.nextQuestion()

        XCTAssertEqual(quizSession.currentQuestionIndex, 1)
    }

    func testCompleteQuiz() async {
        _ = await quizSession.generateQuiz(from: testWords)

        quizSession.currentQuestionIndex = quizSession.questions.count - 1
        quizSession.nextQuestion()

        XCTAssertTrue(quizSession.isQuizComplete)
    }

    // MARK: - Second Chance Round

    func testSecondChanceRoundWithIncorrectWords() async {
        _ = await quizSession.generateQuiz(from: testWords)

        // Submit wrong answers for first two questions
        let word1 = testWords[0]
        let word2 = testWords[1]
        quizSession.submitAnswer(0, word: word1) // Assume wrong
        quizSession.incorrectWords.append(word1)
        quizSession.submitAnswer(0, word: word2) // Assume wrong
        quizSession.incorrectWords.append(word2)

        let success = await quizSession.startSecondChanceRound()

        XCTAssertTrue(success)
        XCTAssertTrue(quizSession.isSecondChanceRound)
        XCTAssertGreaterThan(quizSession.questions.count, 0)
    }

    func testSecondChanceRoundWithNoIncorrectWords() async {
        _ = await quizSession.generateQuiz(from: testWords)

        let success = await quizSession.startSecondChanceRound()

        // Should not generate new quiz if no incorrect words
        XCTAssertFalse(success)
        XCTAssertNotNil(quizSession.generationError)
        XCTAssertFalse(quizSession.isSecondChanceRound)
    }

    // MARK: - Reset

    func testResetQuiz() async {
        _ = await quizSession.generateQuiz(from: testWords)
        quizSession.score = 5
        quizSession.currentQuestionIndex = 2
        quizSession.isQuizComplete = true

        quizSession.reset()

        XCTAssertEqual(quizSession.score, 0)
        XCTAssertEqual(quizSession.currentQuestionIndex, 0)
        XCTAssertEqual(quizSession.questions.count, 0)
        XCTAssertFalse(quizSession.isQuizComplete)
        XCTAssertFalse(quizSession.isSecondChanceRound)
    }

    // MARK: - Edge Cases and Crash Prevention

    func testQuizGenerationWithLargeNumberOfOptions() async {
        let success = await quizSession.generateQuiz(from: testWords, numberOfOptions: 100)

        XCTAssertTrue(success, "Should handle large numberOfOptions gracefully")
        XCTAssertGreaterThan(quizSession.questions.count, 0)
        // Options should be capped at available words
        for question in quizSession.questions {
            XCTAssertLessThanOrEqual(question.options.count, testWords.count)
        }
    }

    func testMultipleQuizGenerationCallsDoNotCrash() async {
        for _ in 0..<5 {
            let success = await quizSession.generateQuiz(from: testWords)
            XCTAssertTrue(success)
        }
    }

    func testQuizGenerationAfterReset() async {
        _ = await quizSession.generateQuiz(from: testWords)
        quizSession.reset()

        let success = await quizSession.generateQuiz(from: testWords)

        XCTAssertTrue(success)
        XCTAssertGreaterThan(quizSession.questions.count, 0)
    }

    func testCorrectIndexNeverOutOfBounds() async {
        _ = await quizSession.generateQuiz(from: testWords)

        for question in quizSession.questions {
            XCTAssertGreaterThanOrEqual(question.correctAnswerIndex, 0)
            XCTAssertLessThan(question.correctAnswerIndex, question.options.count)
        }
    }
}
