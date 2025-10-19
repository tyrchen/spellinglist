//
//  VocabularyParser.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import Foundation

class VocabularyParser {
    static let shared = VocabularyParser()

    private init() {}

    func parseVocabulary(from text: String) -> [VocabularyWord] {
        var words: [VocabularyWord] = []
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Pattern 1: "word - definition" or "word: definition"
        let pattern1 = try? NSRegularExpression(pattern: #"^(.+?)\s*[-:]\s*(.+)$"#, options: [])

        // Pattern 2: "word" on one line, "definition" on next line
        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Try pattern 1 first (word - definition on same line)
            if let regex = pattern1,
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {

                if let wordRange = Range(match.range(at: 1), in: line),
                   let defRange = Range(match.range(at: 2), in: line) {
                    let word = String(line[wordRange]).trimmingCharacters(in: .whitespaces)
                    let definition = String(line[defRange]).trimmingCharacters(in: .whitespaces)

                    if !word.isEmpty && !definition.isEmpty {
                        words.append(VocabularyWord(word: word, definition: definition))
                    }
                }
                i += 1
            }
            // Pattern 2: word on one line, definition on next
            else if i + 1 < lines.count {
                let potentialWord = line
                let potentialDefinition = lines[i + 1]

                // Basic heuristic: if the first line is short (< 50 chars) and second is longer,
                // treat them as word-definition pair
                if potentialWord.count < 50 && potentialDefinition.count > potentialWord.count {
                    words.append(VocabularyWord(word: potentialWord, definition: potentialDefinition))
                    i += 2
                } else {
                    i += 1
                }
            } else {
                i += 1
            }
        }

        // Pattern 3: Numbered list format "1. word - definition"
        if words.isEmpty {
            words = parseNumberedList(from: lines)
        }

        return words
    }

    private func parseNumberedList(from lines: [String]) -> [VocabularyWord] {
        var words: [VocabularyWord] = []
        let numberedPattern = try? NSRegularExpression(pattern: #"^\d+\.\s*(.+?)\s*[-:]\s*(.+)$"#, options: [])

        for line in lines {
            if let regex = numberedPattern,
               let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)) {

                if let wordRange = Range(match.range(at: 1), in: line),
                   let defRange = Range(match.range(at: 2), in: line) {
                    let word = String(line[wordRange]).trimmingCharacters(in: .whitespaces)
                    let definition = String(line[defRange]).trimmingCharacters(in: .whitespaces)

                    if !word.isEmpty && !definition.isEmpty {
                        words.append(VocabularyWord(word: word, definition: definition))
                    }
                }
            }
        }

        return words
    }

    func parseVocabulary(from text: String, customSeparator: String? = nil) -> [VocabularyWord] {
        if let separator = customSeparator {
            return parseWithCustomSeparator(text: text, separator: separator)
        }
        return parseVocabulary(from: text)
    }

    private func parseWithCustomSeparator(text: String, separator: String) -> [VocabularyWord] {
        var words: [VocabularyWord] = []
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        for line in lines {
            let components = line.components(separatedBy: separator)
            if components.count >= 2 {
                let word = components[0].trimmingCharacters(in: .whitespaces)
                let definition = components[1...].joined(separator: separator).trimmingCharacters(in: .whitespaces)

                if !word.isEmpty && !definition.isEmpty {
                    words.append(VocabularyWord(word: word, definition: definition))
                }
            }
        }

        return words
    }
}
