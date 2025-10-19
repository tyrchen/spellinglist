//
//  VocabularyParserTests.swift
//  spellinglistTests
//
//  Created by cynthia on 10/18/25.
//

import XCTest
@testable import spellinglist

final class VocabularyParserTests: XCTestCase {

    var parser: VocabularyParser!

    override func setUp() {
        super.setUp()
        parser = VocabularyParser.shared
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Pattern 1: word - definition

    func testParseDashSeparatedWords() {
        let text = """
        Abundant - Present in great quantity
        Benevolent - Well-meaning and kindly
        Candid - Truthful and straightforward
        """

        let words = parser.parseVocabulary(from: text)

        XCTAssertEqual(words.count, 3)
        XCTAssertEqual(words[0].word, "Abundant")
        XCTAssertEqual(words[0].definition, "Present in great quantity")
        XCTAssertEqual(words[1].word, "Benevolent")
        XCTAssertEqual(words[1].definition, "Well-meaning and kindly")
    }

    func testParseColonSeparatedWords() {
        let text = """
        Diligent: Having care in one's work
        Eloquent: Fluent and persuasive in speaking
        """

        let words = parser.parseVocabulary(from: text)

        XCTAssertEqual(words.count, 2)
        XCTAssertEqual(words[0].word, "Diligent")
        XCTAssertEqual(words[0].definition, "Having care in one's work")
    }

    // MARK: - Pattern 2: Numbered lists

    func testParseNumberedList() {
        let text = """
        1. Abundant - Present in great quantity
        2. Benevolent - Well-meaning and kindly
        3. Candid - Truthful and straightforward
        """

        let words = parser.parseVocabulary(from: text)

        XCTAssertEqual(words.count, 3)
        XCTAssertEqual(words[0].word, "Abundant")
        XCTAssertEqual(words[1].word, "Benevolent")
    }

    // MARK: - Pattern 3: Multi-line format

    func testParseMultilineFormat() {
        let text = """
        Abundant
        Present in great quantity
        Benevolent
        Well-meaning and kindly
        """

        let words = parser.parseVocabulary(from: text)

        XCTAssertGreaterThan(words.count, 0)
    }

    // MARK: - Edge Cases

    func testEmptyInput() {
        let words = parser.parseVocabulary(from: "")
        XCTAssertEqual(words.count, 0)
    }

    func testWhitespaceOnly() {
        let words = parser.parseVocabulary(from: "   \n  \n  ")
        XCTAssertEqual(words.count, 0)
    }

    func testCustomSeparator() {
        let text = """
        Abundant | Present in great quantity
        Benevolent | Well-meaning and kindly
        """

        let words = parser.parseVocabulary(from: text, customSeparator: "|")

        XCTAssertEqual(words.count, 2)
        XCTAssertEqual(words[0].word, "Abundant")
        XCTAssertEqual(words[0].definition, "Present in great quantity")
    }

    func testTrimsWhitespace() {
        let text = "  Abundant  -  Present in great quantity  "

        let words = parser.parseVocabulary(from: text)

        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words[0].word, "Abundant")
        XCTAssertEqual(words[0].definition, "Present in great quantity")
    }
}
