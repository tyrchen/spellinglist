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
        await quizSession.generateQuiz(from: testWords)

        XCTAssertEqual(quizSession.questions.count, 4)
    }

    func testGenerateQuizWithInsufficientWords() async {
        let singleWord = [VocabularyWord(word: "Test", definition: "Test definition")]

        await quizSession.generateQuiz(from: singleWord, numberOfOptions: 4)

        XCTAssertEqual(quizSession.questions.count, 0, "Should not generate quiz with insufficient words")
    }

    func testQuizQuestionsHaveCorrectNumberOfOptions() async {
        await quizSession.generateQuiz(from: testWords, numberOfOptions: 4)

        for question in quizSession.questions {
            XCTAssertEqual(question.options.count, 4)
        }
    }

    func testCorrectAnswerIsInOptions() async {
        await quizSession.generateQuiz(from: testWords)

        for question in quizSession.questions {
            XCTAssertTrue(question.options.contains(question.correctDefinition))
        }
    }

    func testCorrectAnswerIndexPointsToCorrectDefinition() async {
        await quizSession.generateQuiz(from: testWords)

        for question in quizSession.questions {
            XCTAssertEqual(question.options[question.correctAnswerIndex], question.correctDefinition)
        }
    }

    // MARK: - Answer Submission

    func testSubmitCorrectAnswer() async {
        await quizSession.generateQuiz(from: testWords)

        let correctIndex = quizSession.questions[0].correctAnswerIndex
        let word = testWords.first { $0.word == quizSession.questions[0].wordText }!

        quizSession.submitAnswer(correctIndex, word: word)

        XCTAssertEqual(quizSession.score, 1)
        XCTAssertEqual(word.timesCorrect, 1)
        XCTAssertEqual(word.timesIncorrect, 0)
    }

    func testSubmitIncorrectAnswer() async {
        await quizSession.generateQuiz(from: testWords)

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
        await quizSession.generateQuiz(from: testWords)

        XCTAssertEqual(quizSession.currentQuestionIndex, 0)

        quizSession.nextQuestion()

        XCTAssertEqual(quizSession.currentQuestionIndex, 1)
    }

    func testCompleteQuiz() async {
        await quizSession.generateQuiz(from: testWords)

        quizSession.currentQuestionIndex = quizSession.questions.count - 1
        quizSession.nextQuestion()

        XCTAssertTrue(quizSession.isQuizComplete)
    }

    // MARK: - Second Chance Round

    func testSecondChanceRoundWithIncorrectWords() async {
        await quizSession.generateQuiz(from: testWords)

        // Submit wrong answers for first two questions
        let word1 = testWords[0]
        let word2 = testWords[1]
        quizSession.submitAnswer(0, word: word1) // Assume wrong
        quizSession.incorrectWords.append(word1)
        quizSession.submitAnswer(0, word: word2) // Assume wrong
        quizSession.incorrectWords.append(word2)

        await quizSession.startSecondChanceRound()

        XCTAssertTrue(quizSession.isSecondChanceRound)
        XCTAssertGreaterThan(quizSession.questions.count, 0)
    }

    func testSecondChanceRoundWithNoIncorrectWords() async {
        await quizSession.generateQuiz(from: testWords)

        await quizSession.startSecondChanceRound()

        // Should not generate new quiz if no incorrect words
        XCTAssertFalse(quizSession.isSecondChanceRound)
    }

    // MARK: - Reset

    func testResetQuiz() async {
        await quizSession.generateQuiz(from: testWords)
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
}
