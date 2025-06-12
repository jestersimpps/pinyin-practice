import SwiftUI

struct CustomPracticeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var progressService = UserProgressService.shared
    @ObservedObject private var vocabularyService = VocabularyService.shared
    @State private var selectedTab = 0
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
                            
                            tabSelector
                            
                            if selectedTab == 0 {
                                levelSelectionSection
                            } else {
                                categorySelectionSection
                            }
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
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: { withAnimation { selectedTab = index } }) {
                    Text(index == 0 ? "HSK Levels" : "Categories")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedTab == index ? .white : Color("SecondaryText"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == index ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground").opacity(0.5))
        )
    }
    
    private var levelSelectionSection: some View {
        VStack(spacing: 12) {
            ForEach(HSKLevel.allCases, id: \.self) { level in
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
    
    private var categorySelectionSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(VocabularyCategory.allCases, id: \.self) { category in
                CategorySelectionCard(
                    category: category,
                    isSelected: settings.wrappedValue.selectedCategories.contains(category),
                    action: { toggleCategory(category) }
                )
            }
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
        vocabularyService.getFilteredVocabulary(
            levels: settings.wrappedValue.selectedHSKLevels,
            categories: settings.wrappedValue.selectedCategories
        ).count
    }
    
    private func getWordCount(for level: HSKLevel) -> Int {
        vocabularyService.allVocabulary.filter { $0.hskLevel == level }.count
    }
    
    private func toggleLevel(_ level: HSKLevel) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if settings.wrappedValue.selectedHSKLevels.contains(level) {
                settings.wrappedValue.selectedHSKLevels.remove(level)
            } else {
                settings.wrappedValue.selectedHSKLevels.insert(level)
            }
        }
    }
    
    private func toggleCategory(_ category: VocabularyCategory) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if settings.wrappedValue.selectedCategories.contains(category) {
                settings.wrappedValue.selectedCategories.remove(category)
            } else {
                settings.wrappedValue.selectedCategories.insert(category)
            }
        }
    }
    
    private func selectAllLevels() {
        withAnimation {
            settings.wrappedValue.selectedHSKLevels = Set(HSKLevel.allCases)
        }
    }
    
    private func deselectAllLevels() {
        withAnimation {
            settings.wrappedValue.selectedHSKLevels.removeAll()
        }
    }
}

private struct LevelSelectionCard: View {
    let level: HSKLevel
    let isSelected: Bool
    let wordCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
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

private struct CategorySelectionCard: View {
    let category: VocabularyCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color("SecondaryBackground").opacity(0.5))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : Color(red: 0.1, green: 0.3, blue: 0.4))
                }
                
                Text(category.displayName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? Color("PrimaryText") : Color("SecondaryText"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.4) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}