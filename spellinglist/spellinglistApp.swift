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
    @State private var isInitializing = true

    private let logger = Logger(subsystem: "com.spellinglist.app", category: "Database")

    var body: some Scene {
        WindowGroup {
            Group {
                if isInitializing {
                    // Show loading view while initializing
                    ProgressView("Initializing...")
                        .task {
                            // Perform database initialization asynchronously
                            await initializeDatabase()
                        }
                } else if let container = modelContainer {
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
                            Task {
                                await initializeDatabase()
                            }
                        }
                    )
                }
            }
        }
    }

    @MainActor
    private func initializeDatabase() async {
        isInitializing = true

        // Perform database initialization on background thread
        let result = await Task.detached(priority: .userInitiated) { [logger] in
            return spellinglistApp.createModelContainer(logger: logger)
        }.value

        modelContainer = result.container
        errorMessage = result.errorMessage
        isInMemoryMode = result.isInMemoryMode
        showingError = result.showingError
        isInitializing = false
    }

    struct DatabaseInitResult {
        let container: ModelContainer?
        let errorMessage: String?
        let isInMemoryMode: Bool
        let showingError: Bool
    }

    private static func createModelContainer(logger: Logger) -> DatabaseInitResult {
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
            return DatabaseInitResult(
                container: container,
                errorMessage: nil,
                isInMemoryMode: false,
                showingError: false
            )
        } catch {
            logger.error("Failed to create persistent ModelContainer: \(error.localizedDescription)")

            // Try to recover from corrupted database
            if let recoveredResult = recoverFromCorruptedDatabase(schema: schema, error: error, logger: logger) {
                logger.warning("Recovered from corrupted database")
                return recoveredResult
            }

            // Fallback to in-memory storage
            logger.warning("Falling back to in-memory storage")
            return createInMemoryContainer(schema: schema, logger: logger)
        }
    }

    private static func recoverFromCorruptedDatabase(schema: Schema, error: Error, logger: Logger) -> DatabaseInitResult? {
        // Attempt to delete and recreate the database
        logger.info("Attempting database recovery...")

        do {
            // Get app documents directory
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                logger.error("Could not find documents directory")
                return nil
            }

            // Remove all SwiftData-related files (e.g., .store, .store-shm, .store-wal)
            let storeFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let dbBaseName = "spellinglist.store"
            let dbRelatedExtensions = ["store", "store-shm", "store-wal"]

            for file in storeFiles {
                let fileName = file.lastPathComponent
                // Remove files that match the base name or auxiliary files
                if fileName.hasPrefix(dbBaseName) || dbRelatedExtensions.contains(file.pathExtension) {
                    try fileManager.removeItem(at: file)
                    logger.info("Removed corrupted database file at \(file.path)")
                }
            }

            // Try to recreate with persistent storage
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.info("Successfully recreated database after recovery")
            return DatabaseInitResult(
                container: container,
                errorMessage: "Your database was recovered. Some data may have been reset.",
                isInMemoryMode: false,
                showingError: true
            )
        } catch {
            logger.error("Database recovery failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func createInMemoryContainer(schema: Schema, logger: Logger) -> DatabaseInitResult {
        let inMemoryConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
            logger.warning("Created in-memory ModelContainer - data will not persist")
            return DatabaseInitResult(
                container: container,
                errorMessage: "Running in temporary mode. Your data will not be saved permanently. Please check device storage and restart the app.",
                isInMemoryMode: true,
                showingError: false
            )
        } catch {
            logger.critical("Failed to create even in-memory container: \(error.localizedDescription)")
            return DatabaseInitResult(
                container: nil,
                errorMessage: "Critical error: Unable to initialize app database. Error: \(error.localizedDescription)",
                isInMemoryMode: false,
                showingError: false
            )
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
