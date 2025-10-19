//
//  ModelTests.swift
//  spellinglistTests
//
//  Created by cynthia on 10/18/25.
//

import XCTest
import SwiftData
@testable import spellinglist

@MainActor
final class ModelTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            VocabularyWord.self,
            VocabularySet.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - VocabularyWord Tests

    func testCreateVocabularyWord() {
        let word = VocabularyWord(word: "Test", definition: "Test definition")

        XCTAssertNotNil(word.id)
        XCTAssertEqual(word.word, "Test")
        XCTAssertEqual(word.definition, "Test definition")
        XCTAssertEqual(word.timesCorrect, 0)
        XCTAssertEqual(word.timesIncorrect, 0)
    }

    func testVocabularyWordStats() {
        let word = VocabularyWord(word: "Test", definition: "Test definition")

        word.timesCorrect = 5
        word.timesIncorrect = 2

        XCTAssertEqual(word.timesCorrect, 5)
        XCTAssertEqual(word.timesIncorrect, 2)
    }

    // MARK: - VocabularySet Tests

    func testCreateVocabularySet() {
        let word1 = VocabularyWord(word: "Word1", definition: "Definition1")
        let word2 = VocabularyWord(word: "Word2", definition: "Definition2")

        let set = VocabularySet(name: "Test Set", words: [word1, word2])

        XCTAssertNotNil(set.id)
        XCTAssertEqual(set.name, "Test Set")
        XCTAssertEqual(set.words.count, 2)
    }

    func testVocabularySetWithSourceFile() {
        let set = VocabularySet(name: "Test Set", sourceFileName: "test.pdf")

        XCTAssertEqual(set.sourceFileName, "test.pdf")
    }

    func testAddWordToVocabularySet() {
        let set = VocabularySet(name: "Test Set")
        let word = VocabularyWord(word: "Test", definition: "Test definition")

        set.words.append(word)

        XCTAssertEqual(set.words.count, 1)
        XCTAssertEqual(set.words[0].word, "Test")
    }

    // MARK: - SwiftData Persistence Tests

    func testSaveAndFetchVocabularySet() throws {
        let word = VocabularyWord(word: "Persistent", definition: "Continuing firmly")
        let set = VocabularySet(name: "Persistent Set", words: [word])

        modelContext.insert(set)
        try modelContext.save()

        let descriptor = FetchDescriptor<VocabularySet>()
        let fetchedSets = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetchedSets.count, 1)
        XCTAssertEqual(fetchedSets[0].name, "Persistent Set")
        XCTAssertEqual(fetchedSets[0].words.count, 1)
    }

    func testDeleteVocabularySet() throws {
        let word = VocabularyWord(word: "Delete", definition: "To remove")
        let set = VocabularySet(name: "Delete Set", words: [word])

        modelContext.insert(set)
        try modelContext.save()

        var descriptor = FetchDescriptor<VocabularySet>()
        var fetchedSets = try modelContext.fetch(descriptor)
        XCTAssertEqual(fetchedSets.count, 1)

        // Delete the set
        modelContext.delete(set)
        try modelContext.save()

        descriptor = FetchDescriptor<VocabularySet>()
        fetchedSets = try modelContext.fetch(descriptor)
        XCTAssertEqual(fetchedSets.count, 0)
    }

    func testCascadeDeleteWordsWhenSetDeleted() throws {
        let word1 = VocabularyWord(word: "Word1", definition: "Definition1")
        let word2 = VocabularyWord(word: "Word2", definition: "Definition2")
        let set = VocabularySet(name: "Cascade Set", words: [word1, word2])

        modelContext.insert(set)
        try modelContext.save()

        // Verify words exist
        var wordDescriptor = FetchDescriptor<VocabularyWord>()
        var fetchedWords = try modelContext.fetch(wordDescriptor)
        XCTAssertEqual(fetchedWords.count, 2)

        // Delete set
        modelContext.delete(set)
        try modelContext.save()

        // Verify words were cascade deleted
        wordDescriptor = FetchDescriptor<VocabularyWord>()
        fetchedWords = try modelContext.fetch(wordDescriptor)
        XCTAssertEqual(fetchedWords.count, 0, "Words should be cascade deleted when set is deleted")
    }

    func testUpdateVocabularySetName() throws {
        let set = VocabularySet(name: "Original Name")
        modelContext.insert(set)
        try modelContext.save()

        set.name = "Updated Name"
        try modelContext.save()

        let descriptor = FetchDescriptor<VocabularySet>()
        let fetchedSets = try modelContext.fetch(descriptor)

        XCTAssertEqual(fetchedSets[0].name, "Updated Name")
    }

    // MARK: - Edge Cases

    func testEmptyVocabularySet() {
        let set = VocabularySet(name: "Empty Set")

        XCTAssertEqual(set.words.count, 0)
    }

    func testVocabularySetWithManyWords() {
        var words: [VocabularyWord] = []
        for i in 1...100 {
            words.append(VocabularyWord(word: "Word\(i)", definition: "Definition\(i)"))
        }

        let set = VocabularySet(name: "Large Set", words: words)

        XCTAssertEqual(set.words.count, 100)
    }
}
