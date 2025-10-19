//
//  ContentView.swift
//  spellinglist
//
//  Created by cynthia on 10/18/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [VocabularyWord.self, VocabularySet.self])
}
