//
//  FileUploadView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct FileUploadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingDocumentPicker = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var vocabularySetName = ""
    @State private var extractedWords: [VocabularyWord] = []
    @State private var showWordReview = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing document...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .padding(.top, 40)

                        Text("Upload Vocabulary List")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose an image or PDF containing your vocabulary words and definitions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 15) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }

                            Button(action: { isShowingDocumentPicker = true }) {
                                Label("Choose PDF File", systemImage: "doc.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Add Vocabulary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingDocumentPicker) {
                DocumentPicker { url in
                    Task {
                        await processPDF(url: url)
                    }
                }
            }
            .sheet(isPresented: $showWordReview) {
                WordReviewView(words: $extractedWords, setName: $vocabularySetName, onSave: saveVocabularySet)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await processImage(image)
                    }
                }
            }
        }
    }

    private func processImage(_ image: UIImage) async {
        await MainActor.run { isProcessing = true }
        defer { Task { await MainActor.run { isProcessing = false } } }

        do {
            // OCR on background thread
            let text = try await OCRService.shared.extractText(from: image)

            // Parsing on background thread
            let words = await Task.detached {
                VocabularyParser.shared.parseVocabulary(from: text)
            }.value

            await MainActor.run {
                extractedWords = words
                if extractedWords.isEmpty {
                    errorMessage = "No vocabulary words found. Please ensure your image contains word-definition pairs."
                    showError = true
                } else {
                    showWordReview = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func processPDF(url: URL) async {
        await MainActor.run { isProcessing = true }
        defer { Task { await MainActor.run { isProcessing = false } } }

        do {
            // Load PDF data on background thread
            let data = try await Task.detached {
                try Data(contentsOf: url)
            }.value

            // OCR on background thread
            let text = try await OCRService.shared.extractText(from: data)

            // Parsing on background thread
            let words = await Task.detached {
                VocabularyParser.shared.parseVocabulary(from: text)
            }.value

            await MainActor.run {
                extractedWords = words
                if extractedWords.isEmpty {
                    errorMessage = "No vocabulary words found. Please ensure your PDF contains word-definition pairs."
                    showError = true
                } else {
                    showWordReview = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func saveVocabularySet() {
        let vocabSet = VocabularySet(
            name: vocabularySetName.isEmpty ? "Vocabulary Set \(Date().formatted(date: .abbreviated, time: .omitted))" : vocabularySetName,
            words: extractedWords
        )

        modelContext.insert(vocabSet)
        dismiss()
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentPicked(url)
        }
    }
}

struct WordReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var words: [VocabularyWord]
    @Binding var setName: String
    let onSave: () -> Void

    @State private var editingWordIndex: Int?
    @State private var showingAddWord = false
    @State private var newWord = ""
    @State private var newDefinition = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with set name
                VStack(spacing: 15) {
                    Text("Review & Edit Words")
                        .font(.headline)

                    TextField("Vocabulary Set Name (optional)", text: $setName)
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
                                TextField("Word", text: Binding(
                                    get: { words[index].word },
                                    set: { words[index].word = $0 }
                                ))
                                .font(.headline)
                                .textFieldStyle(.roundedBorder)

                                TextField("Definition", text: Binding(
                                    get: { words[index].definition },
                                    set: { words[index].definition = $0 }
                                ), axis: .vertical)
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
            .navigationTitle("Review Words")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    onSave()
                    dismiss()
                }
                .disabled(words.isEmpty || hasEmptyFields)
            )
            .sheet(isPresented: $showingAddWord) {
                AddWordSheet(
                    newWord: $newWord,
                    newDefinition: $newDefinition,
                    onAdd: {
                        addNewWord()
                    }
                )
            }
        }
    }

    private var hasEmptyFields: Bool {
        words.contains { $0.word.trimmingCharacters(in: .whitespaces).isEmpty ||
                        $0.definition.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func deleteWord(at index: Int) {
        guard index >= 0 && index < words.count else { return }
        withAnimation {
            words.remove(at: index)
            // If editing the deleted word, clear edit mode
            if editingWordIndex == index {
                editingWordIndex = nil
            } else if let editingIndex = editingWordIndex, editingIndex > index {
                // Adjust editing index if needed
                editingWordIndex = editingIndex - 1
            }
        }
    }

    private func addNewWord() {
        guard !newWord.isEmpty && !newDefinition.isEmpty else { return }

        let vocabWord = VocabularyWord(word: newWord, definition: newDefinition)
        words.append(vocabWord)

        newWord = ""
        newDefinition = ""
        showingAddWord = false
    }
}

struct AddWordSheet: View {
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newWord = ""
                        newDefinition = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty ||
                             newDefinition.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FileUploadView()
        .modelContainer(for: [VocabularyWord.self, VocabularySet.self])
}
