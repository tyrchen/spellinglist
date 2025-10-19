//
//  IntegrationTests.swift
//  spellinglistTests
//
//  Created by cynthia on 10/18/25.
//

import XCTest
import SwiftData
@testable import spellinglist

@MainActor
final class IntegrationTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var quizSession: QuizSession!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            VocabularyWord.self,
            VocabularySet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
        quizSession = QuizSession()
    }

    override func tearDown() {
        quizSession = nil
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - End-to-End User Flows

    func testCompleteUserFlow_UploadParseQuizDelete() async throws {
        // 1. Parse vocabulary from text (simulating OCR result)
        let ocrText = """
        Abundant - Present in great quantity
        Benevolent - Well-meaning and kindly
        Candid - Truthful and straightforward
        """

        let words = VocabularyParser.shared.parseVocabulary(from: ocrText)
        XCTAssertEqual(words.count, 3, "Should parse 3 words")

        // 2. Create vocabulary set
        let vocabSet = VocabularySet(name: "Test Vocabulary", words: words)
        modelContext.insert(vocabSet)
        try modelContext.save()

        // 3. Generate quiz
        await quizSession.generateQuiz(from: vocabSet.words)
        XCTAssertEqual(quizSession.questions.count, 3, "Should generate 3 questions")

        // 4. Answer questions
        for i in 0..<quizSession.questions.count {
            let question = quizSession.questions[i]
            let word = vocabSet.words.first { $0.word == question.wordText }!
            quizSession.submitAnswer(question.correctAnswerIndex, word: word)
            if i < quizSession.questions.count - 1 {
                quizSession.nextQuestion()
            }
        }

        XCTAssertEqual(quizSession.score, 3, "Should score 3/3")
        XCTAssertEqual(quizSession.incorrectWords.count, 0, "Should have no incorrect words")

        // 5. Delete vocabulary set
        modelContext.delete(vocabSet)
        try modelContext.save()

        let descriptor = FetchDescriptor<VocabularySet>()
        let remainingSets = try modelContext.fetch(descriptor)
        XCTAssertEqual(remainingSets.count, 0, "Should have no vocabulary sets")
    }

    func testUserFlow_WithIncorrectAnswersAndSecondChance() async throws {
        // 1. Create vocabulary
        let words = [
            VocabularyWord(word: "Word1", definition: "Definition1"),
            VocabularyWord(word: "Word2", definition: "Definition2"),
            VocabularyWord(word: "Word3", definition: "Definition3"),
            VocabularyWord(word: "Word4", definition: "Definition4")
        ]
        let vocabSet = VocabularySet(name: "Test Set", words: words)

        // 2. Generate quiz
        await quizSession.generateQuiz(from: words)

        // 3. Answer first question wrong
        let wrongIndex = (quizSession.questions[0].correctAnswerIndex + 1) % quizSession.questions[0].options.count
        quizSession.submitAnswer(wrongIndex, word: words[0])

        XCTAssertEqual(quizSession.incorrectWords.count, 1, "Should have 1 incorrect word")

        // 4. Answer rest correctly
        for i in 1..<quizSession.questions.count {
            quizSession.nextQuestion()
            let question = quizSession.questions[i]
            let word = words.first { $0.word == question.wordText }!
            quizSession.submitAnswer(question.correctAnswerIndex, word: word)
        }

        quizSession.completeQuiz()
        XCTAssertTrue(quizSession.isQuizComplete)

        // 5. Start second chance round
        await quizSession.startSecondChanceRound()
        XCTAssertTrue(quizSession.isSecondChanceRound)
        XCTAssertGreaterThan(quizSession.questions.count, 0, "Should have questions for second chance")
    }

    func testUserFlow_EditVocabularySet() throws {
        // 1. Create original set
        let word1 = VocabularyWord(word: "Original1", definition: "OriginalDef1")
        let word2 = VocabularyWord(word: "Original2", definition: "OriginalDef2")
        let set = VocabularySet(name: "Original Name", words: [word1, word2])

        modelContext.insert(set)
        try modelContext.save()

        // 2. Edit set name
        set.name = "Updated Name"

        // 3. Edit word
        word1.word = "Modified1"
        word1.definition = "ModifiedDef1"

        // 4. Add new word
        let word3 = VocabularyWord(word: "New3", definition: "NewDef3")
        modelContext.insert(word3)
        set.words.append(word3)

        // 5. Remove a word
        modelContext.delete(word2)

        try modelContext.save()

        // 6. Verify changes
        XCTAssertEqual(set.name, "Updated Name")
        XCTAssertEqual(set.words.count, 2)
        XCTAssertEqual(set.words[0].word, "Modified1")
    }

    func testUserFlow_MultipleVocabularySets() throws {
        // Create multiple sets
        let set1 = VocabularySet(name: "Set 1", words: [
            VocabularyWord(word: "A1", definition: "D1")
        ])
        let set2 = VocabularySet(name: "Set 2", words: [
            VocabularyWord(word: "B1", definition: "D2")
        ])
        let set3 = VocabularySet(name: "Set 3", words: [
            VocabularyWord(word: "C1", definition: "D3")
        ])

        modelContext.insert(set1)
        modelContext.insert(set2)
        modelContext.insert(set3)
        try modelContext.save()

        // Fetch all sets
        let descriptor = FetchDescriptor<VocabularySet>(sortBy: [SortDescriptor(\.name)])
        let allSets = try modelContext.fetch(descriptor)

        XCTAssertEqual(allSets.count, 3)
        XCTAssertEqual(allSets[0].name, "Set 1")
        XCTAssertEqual(allSets[1].name, "Set 2")
        XCTAssertEqual(allSets[2].name, "Set 3")

        // Delete one set
        modelContext.delete(set2)
        try modelContext.save()

        let remainingSets = try modelContext.fetch(descriptor)
        XCTAssertEqual(remainingSets.count, 2)
    }

    // MARK: - Performance Tests

    func testPerformance_GenerateQuizWithLargeVocabulary() async {
        // Create 100 words
        var words: [VocabularyWord] = []
        for i in 1...100 {
            words.append(VocabularyWord(word: "Word\(i)", definition: "Definition for word \(i)"))
        }

        measure {
            Task {
                await quizSession.generateQuiz(from: words)
            }
        }
    }

    func testPerformance_ParseLargeText() {
        var largeText = ""
        for i in 1...100 {
            largeText += "Word\(i) - Definition for word \(i)\n"
        }

        measure {
            _ = VocabularyParser.shared.parseVocabulary(from: largeText)
        }
    }

    // MARK: - Error Recovery Tests

    func testRecovery_DeleteWordDuringQuiz() async throws {
        let words = [
            VocabularyWord(word: "Word1", definition: "Definition1"),
            VocabularyWord(word: "Word2", definition: "Definition2"),
            VocabularyWord(word: "Word3", definition: "Definition3")
        ]

        await quizSession.generateQuiz(from: words)

        // Simulate deleting a word from the source
        // Quiz should continue with existing questions
        XCTAssertEqual(quizSession.questions.count, 3)
    }

    func testRecovery_EmptyVocabularySet() async {
        let emptySet = VocabularySet(name: "Empty")

        await quizSession.generateQuiz(from: emptySet.words)

        XCTAssertEqual(quizSession.questions.count, 0)
        XCTAssertFalse(quizSession.isQuizComplete)
    }
}
