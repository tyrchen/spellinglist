//
//  SettingsView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("numberOfOptions") private var numberOfOptions = 4
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Settings") {
                    Stepper("Number of Options: \(numberOfOptions)", value: $numberOfOptions, in: 2...6)

                    Toggle("Sound Effects", isOn: $soundEnabled)
                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                }

                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/yourusername/vocabularyquiz")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("How to Use")
                            .font(.headline)

                        Text("1. Upload a PDF or image containing vocabulary words and definitions")
                        Text("2. Review the extracted words and save them")
                        Text("3. Start a quiz to test your knowledge")
                        Text("4. Practice missed words in second-chance rounds")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                } header: {
                    Text("Help")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
