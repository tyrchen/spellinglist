//
//  EditVocabularySetSheet.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData

struct EditVocabularySetSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vocabularySet: VocabularySet

    @State private var setName: String = ""
    @State private var words: [VocabularyWord] = []

    var body: some View {
        WordReviewView(
            words: $words,
            setName: $setName,
            onSave: saveChanges
        )
        .onAppear {
            setName = vocabularySet.name
            words = vocabularySet.words
        }
    }

    private func saveChanges() {
        vocabularySet.name = setName
        // Words are already SwiftData objects, changes are automatically tracked
        try? modelContext.save()
    }
}
