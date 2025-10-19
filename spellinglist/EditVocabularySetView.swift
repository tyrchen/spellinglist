//
//  EditVocabularySetView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData

struct EditVocabularySetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let vocabularySet: VocabularySet

    @State private var setName: String = ""
    @State private var words: [VocabularyWord] = []
    @State private var editingWordIndex: Int?
    @State private var showingAddWord = false
    @State private var newWord = ""
    @State private var newDefinition = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with set name
                VStack(spacing: 15) {
                    Text("Edit Vocabulary Set")
                        .font(.headline)

                    TextField("Vocabulary Set Name", text: $setName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Clean list view
                List {
                    ForEach(words.indices, id: \.self) { index in
                        if editingWordIndex == index {
                            // Edit mode - show text fields
                            VStack(alignment: .leading, spacing: 12) {
                                TextField("Word", text: $words[index].word)
                                    .font(.headline)
                                    .textFieldStyle(.roundedBorder)

                                TextField("Definition", text: $words[index].definition, axis: .vertical)
                                    .font(.subheadline)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...6)

                                HStack {
                                    Spacer()
                                    Button("Done") {
                                        withAnimation {
                                            editingWordIndex = nil
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.vertical, 8)
                            .transition(.opacity)
                        } else {
                            // View mode - clean display
                            VStack(alignment: .leading, spacing: 8) {
                                Text(words[index].word)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(words[index].definition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    withAnimation {
                                        editingWordIndex = index
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteWord(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)

                // Bottom section
                VStack(spacing: 12) {
                    Text("\(words.count) word\(words.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { showingAddWord = true }) {
                        Label("Add New Word", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Edit Words")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .disabled(setName.isEmpty || words.isEmpty || hasEmptyFields)
            )
            .sheet(isPresented: $showingAddWord) {
                AddNewWordSheet(
                    newWord: $newWord,
                    newDefinition: $newDefinition,
                    onAdd: addNewWord
                )
            }
        }
        .onAppear {
            setName = vocabularySet.name
            words = vocabularySet.words
        }
    }

    private var hasEmptyFields: Bool {
        words.contains { $0.word.trimmingCharacters(in: .whitespaces).isEmpty ||
                        $0.definition.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func deleteWord(at index: Int) {
        withAnimation {
            modelContext.delete(words[index])
            words.remove(at: index)
        }
    }

    private func addNewWord() {
        guard !newWord.isEmpty && !newDefinition.isEmpty else { return }

        let vocabWord = VocabularyWord(word: newWord, definition: newDefinition)
        modelContext.insert(vocabWord)
        words.append(vocabWord)
        vocabularySet.words.append(vocabWord)

        newWord = ""
        newDefinition = ""
        showingAddWord = false
    }

    private func saveChanges() {
        vocabularySet.name = setName
        try? modelContext.save()
    }
}

struct AddNewWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newWord: String
    @Binding var newDefinition: String
    let onAdd: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("New Word") {
                    TextField("Word", text: $newWord)
                        .font(.headline)

                    TextField("Definition", text: $newDefinition, axis: .vertical)
                        .font(.subheadline)
                        .lineLimit(3...10)
                }

                Section {
                    Text("Tip: Make sure both word and definition are filled in correctly.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    newWord = ""
                    newDefinition = ""
                    dismiss()
                },
                trailing: Button("Add") {
                    onAdd()
                    dismiss()
                }
                .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty ||
                         newDefinition.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: VocabularyWord.self, VocabularySet.self, configurations: config)

    let word1 = VocabularyWord(word: "Abundant", definition: "Present in great quantity")
    let word2 = VocabularyWord(word: "Benevolent", definition: "Well-meaning and kindly")
    let set = VocabularySet(name: "Test Set", words: [word1, word2])

    container.mainContext.insert(set)

    return EditVocabularySetView(vocabularySet: set)
        .modelContainer(container)
}
