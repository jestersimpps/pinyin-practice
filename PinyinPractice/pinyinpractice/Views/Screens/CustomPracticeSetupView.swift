import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var showingPractice = false
    
    private var settings: Binding<PracticeSettings> {
        $progressService.settings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            availableWordsCard
                            levelSelectionSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    bottomBar
                }
            }
            .navigationTitle("Custom Practice")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .fullScreenCover(isPresented: $showingPractice) {
                PracticeView()
            }
        }
    }
    
    private var availableWordsCard: some View {
        VStack(spacing: 8) {
            Text("\(availableWordCount)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            
            Text("words selected")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    
    private var levelSelectionSection: some View {
        VStack(spacing: 12) {
            ForEach(1...6, id: \.self) { level in
                LevelSelectionCard(
                    level: level,
                    isSelected: settings.wrappedValue.selectedHSKLevels.contains(level),
                    wordCount: getWordCount(for: level),
                    action: { toggleLevel(level) }
                )
            }
            
            HStack(spacing: 12) {
                Button(action: selectAllLevels) {
                    Text("Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.4))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("•")
                    .foregroundColor(Color("SecondaryText"))
                
                Button(action: deselectAllLevels) {
                    Text("Deselect All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.4))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
    }
    
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Mode")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("SecondaryText"))
                    
                    Menu {
                        ForEach(PracticeSettings.PracticeMode.allCases, id: \.self) { mode in
                            Button(action: { settings.wrappedValue.practiceMode = mode }) {
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Text(settings.wrappedValue.practiceMode.rawValue)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color("PrimaryText"))
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundColor(Color("SecondaryText"))
                        }
                    }
                }
                
                Spacer()
                
                PrimaryButton(
                    title: "Start",
                    icon: "play.fill",
                    action: { showingPractice = true },
                    isDisabled: availableWordCount == 0
                )
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
    
    private var availableWordCount: Int {
        vocabularyService.getVocabularyForLevels(
            settings.wrappedValue.selectedHSKLevels
        ).count
    }
    
    private func getWordCount(for level: Int) -> Int {
        vocabularyService.getVocabularyForLevel(level).count
    }
    
    private func toggleLevel(_ level: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if settings.wrappedValue.selectedHSKLevels.contains(level) {
                settings.wrappedValue.selectedHSKLevels.remove(level)
            } else {
                settings.wrappedValue.selectedHSKLevels.insert(level)
            }
        }
    }
    
    
    private func selectAllLevels() {
        withAnimation {
            settings.wrappedValue.selectedHSKLevels = Set(1...6)
        }
    }
    
    private func deselectAllLevels() {
        withAnimation {
            settings.wrappedValue.selectedHSKLevels.removeAll()
        }
    }
}

private struct LevelSelectionCard: View {
    let level: Int
    let isSelected: Bool
    let wordCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HSK \(level)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                    
                    Text("\(wordCount) words")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color("SecondaryText"))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : Color("SecondaryText"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color("SecondaryBackground").opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

