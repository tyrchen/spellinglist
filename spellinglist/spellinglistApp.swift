//
//  spellinglistApp.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData
import os.log

@main
struct spellinglistApp: App {
    @State private var modelContainer: ModelContainer?
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var isInMemoryMode = false

    private let logger = Logger(subsystem: "com.spellinglist.app", category: "Database")

    init() {
        _modelContainer = State(initialValue: createModelContainer())
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = modelContainer {
                    ContentView()
                        .modelContainer(container)
                        .alert("Database Warning", isPresented: $showingError) {
                            Button("Continue", role: .cancel) { }
                        } message: {
                            if let message = errorMessage {
                                Text(message)
                            }
                        }
                        .onAppear {
                            if isInMemoryMode {
                                showingError = true
                            }
                        }
                } else {
                    DatabaseErrorView(
                        errorMessage: errorMessage ?? "Failed to initialize database",
                        onRetry: {
                            modelContainer = createModelContainer()
                        }
                    )
                }
            }
        }
    }

    private func createModelContainer() -> ModelContainer? {
        let schema = Schema([
            VocabularyWord.self,
            VocabularySet.self,
        ])

        // Try persistent storage first
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("Successfully created persistent ModelContainer")
            return container
        } catch {
            logger.error("Failed to create persistent ModelContainer: \(error.localizedDescription)")

            // Try to recover from corrupted database
            if let recoveredContainer = recoverFromCorruptedDatabase(schema: schema, error: error) {
                logger.warning("Recovered from corrupted database")
                errorMessage = "Your database was recovered. Some data may have been reset."
                showingError = true
                return recoveredContainer
            }

            // Fallback to in-memory storage
            logger.warning("Falling back to in-memory storage")
            return createInMemoryContainer(schema: schema)
        }
    }

    private func recoverFromCorruptedDatabase(schema: Schema, error: Error) -> ModelContainer? {
        // Attempt to delete and recreate the database
        logger.info("Attempting database recovery...")

        do {
            // Get app documents directory
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Could not find documents directory")
                return nil
            }

            // Remove all .store files (SwiftData database files)
            let storeFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in storeFiles where file.pathExtension == "store" {
                try fileManager.removeItem(at: file)
                logger.info("Removed corrupted database file at \(file.path)")
            }

            // Try to recreate with persistent storage
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("Successfully recreated database after recovery")
            return container
        } catch {
            logger.error("Database recovery failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func createInMemoryContainer(schema: Schema) -> ModelContainer? {
        let inMemoryConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            logger.warning("Created in-memory ModelContainer - data will not persist")
            errorMessage = "Running in temporary mode. Your data will not be saved permanently. Please check device storage and restart the app."
            isInMemoryMode = true
            return container
        } catch {
            logger.critical("Failed to create even in-memory container: \(error.localizedDescription)")
            errorMessage = "Critical error: Unable to initialize app database. Error: \(error.localizedDescription)"
            return nil
        }
    }
}

struct DatabaseErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            Text("Database Error")
                .font(.title)
                .fontWeight(.bold)

            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 15) {
                Button(action: onRetry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Text("If this problem persists, try restarting your device or freeing up storage space.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
