import SwiftUI

struct ContentView: View {
    @StateObject private var diContainer = DIContainer.shared
    @State private var showingPractice = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("PinyinPractice v2")
                    .font(.largeTitle)
                    .bold()
                
                Text("Refactored Version")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    NavigationLink("Start Practice") {
                        PracticeView()
                            .environmentObject(diContainer)
                            .environment(\.diContainer, diContainer)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    NavigationLink("Test Components") {
                        TestView()
                            .environmentObject(diContainer)
                            .environment(\.diContainer, diContainer)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Vocabulary loading status
                if diContainer.vocabularyService.isLoading {
                    ProgressView("Loading vocabulary...")
                        .padding()
                } else {
                    Text("Vocabulary loaded: \(diContainer.vocabularyService.allVocabulary.count) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onAppear {
            diContainer.vocabularyService.loadVocabulary()
        }
    }
}

struct TestView: View {
    @Environment(\.diContainer) var diContainer
    @State private var testResults: [String] = []
    
    var body: some View {
        List {
            Section("Test Results") {
                if testResults.isEmpty {
                    Text("Run tests to see results")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            
            Section("Tests") {
                Button("Test Vocabulary Service") {
                    testVocabularyService()
                }
                
                Button("Test Progress Tracking") {
                    testProgressTracking()
                }
                
                Button("Test Input Validation") {
                    testInputValidation()
                }
                
                Button("Clear Results") {
                    testResults.removeAll()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Component Tests")
    }
    
    func testVocabularyService() {
        testResults.removeAll()
        
        let vocab = diContainer.vocabularyService
        testResults.append("Total words: \(vocab.allVocabulary.count)")
        testResults.append("Chapters: \(vocab.chapters.count)")
        
        for level in 1...6 {
            let words = vocab.getVocabularyForLevels([level])
            testResults.append("HSK \(level): \(words.count) words")
        }
    }
    
    func testProgressTracking() {
        testResults.removeAll()
        
        let progressService = diContainer.makeProgressService()
        testResults.append("Current streak: \(progressService.currentStreak)")
        testResults.append("Accuracy: \(progressService.accuracy)")
        testResults.append("Words learned: \(progressService.getTotalWordsLearned())")
    }
    
    func testInputValidation() {
        testResults.removeAll()
        
        let validator = InputValidator()
        let testWord = VocabularyItem(
            id: "test",
            simplified: "你好",
            traditional: "你好",
            pinyin: "nǐ hǎo",
            toneNumbers: "ni3 hao3",
            english: "hello",
            frequency: 1,
            hskLevel: 1,
            cp: nil
        )
        
        let tests = [
            ("ni3 hao3", true, "Correct with tones"),
            ("ni hao", false, "Correct without tones"),
            ("ni hao", true, "Partial (no tones)"),
            ("wo hao", false, "Incorrect")
        ]
        
        for (input, requireTones, description) in tests {
            let result = validator.validateAnswer(input, for: testWord, requireTones: requireTones)
            testResults.append("\(description): \(result)")
        }
    }
}

// Simple button styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}