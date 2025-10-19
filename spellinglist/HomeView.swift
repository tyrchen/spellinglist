//
//  HomeView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabularySet.dateCreated, order: .reverse) private var vocabularySets: [VocabularySet]

    @State private var showingFileUpload = false
    @State private var selectedSet: VocabularySet?
    @State private var showingQuiz = false
    @State private var showingSettings = false
    @State private var editingSet: VocabularySet?

    var body: some View {
        NavigationStack {
            ZStack {
                if vocabularySets.isEmpty {
                    EmptyStateView(showingFileUpload: $showingFileUpload)
                } else {
                    List {
                        ForEach(vocabularySets) { vocabSet in
                            VocabularySetRow(vocabularySet: vocabSet)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSet = vocabSet
                                    showingQuiz = true
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        editingSet = vocabSet
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteSet(vocabSet)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Vocabulary Quiz")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFileUpload = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingFileUpload) {
                FileUploadView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $editingSet) { set in
                EditVocabularySetSheet(vocabularySet: set)
            }
            .fullScreenCover(item: $selectedSet) { vocabSet in
                QuizView(vocabularySet: vocabSet)
            }
        }
    }

    private func deleteSet(_ set: VocabularySet) {
        modelContext.delete(set)
    }
}

struct VocabularySetRow: View {
    let vocabularySet: VocabularySet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vocabularySet.name)
                        .font(.headline)

                    Text("\(vocabularySet.words.count) words")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }

            if let fileName = vocabularySet.sourceFileName {
                Text(fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stats
            if totalAttempts > 0 {
                HStack(spacing: 15) {
                    StatBadge(
                        icon: "checkmark.circle.fill",
                        value: "\(accuracyPercentage)%",
                        color: .green
                    )

                    StatBadge(
                        icon: "chart.bar.fill",
                        value: "\(totalAttempts) attempts",
                        color: .blue
                    )
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private var totalAttempts: Int {
        vocabularySet.words.reduce(0) { $0 + $1.timesCorrect + $1.timesIncorrect }
    }

    private var accuracyPercentage: Int {
        let total = totalAttempts
        guard total > 0 else { return 0 }
        let correct = vocabularySet.words.reduce(0) { $0 + $1.timesCorrect }
        return Int((Double(correct) / Double(total)) * 100)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    @Binding var showingFileUpload: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.5))

            Text("No Vocabulary Sets")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add your first vocabulary list by uploading a PDF or image")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingFileUpload = true }) {
                Label("Add Vocabulary List", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [VocabularyWord.self, VocabularySet.self])
}
