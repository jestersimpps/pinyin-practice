//
//  pinyingpracticev2App.swift
//  pinyingpracticev2
//
//  Created by jestersimpps on 7/6/25.
//

import SwiftUI

@main
struct pinyingpracticev2App: App {
    @StateObject private var diContainer = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diContainer)
                .environment(\.diContainer, diContainer)
                .onAppear {
                    diContainer.vocabularyService.loadVocabulary()
                }
        }
    }
}
