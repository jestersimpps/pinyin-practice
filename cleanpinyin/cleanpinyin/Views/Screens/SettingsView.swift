import SwiftUI
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @AppStorage(SpeechLanguage.chinese.preferenceKey) private var chineseVoiceId = ""
    @AppStorage(SpeechLanguage.english.preferenceKey) private var englishVoiceId = ""
    @ObservedObject private var progressService = UserProgressService.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("PrimaryBackground")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        wordListSection
                        themeSection
                        quickPracticeLevelsSection
                        practiceModeSection
                        displayOptionsSection
                        voiceSection
                        dataProgressSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("VibrantOrange"))
                }
            }
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                progressService.resetProgress()
            }
        } message: {
            Text("This clears your learned words, streaks, chapter progress and history. Your settings are kept. This cannot be undone.")
        }
    }
    
    private var wordListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Word List", icon: "list.bullet.rectangle.fill")

            VStack(spacing: 12) {
                ForEach(HSKSyllabus.allCases) { syllabus in
                    let isSelected = progressService.settings.syllabus == syllabus
                    SelectableCard(
                        isSelected: isSelected,
                        action: { progressService.selectSyllabus(syllabus) }
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(syllabus.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                                Text("\(syllabus.summary) · \(VocabularyService.shared.wordCount(in: syllabus)) words")
                                    .font(.system(size: 13))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color("SecondaryText"))
                            }
                            Spacer()
                        }
                    }
                    .accessibilityIdentifier("settings.wordList.\(syllabus.rawValue)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            Text("Your learned words and reviews carry over when you switch.")
                .font(.system(size: 13))
                .foregroundColor(Color("SecondaryText"))
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Appearance", icon: "paintbrush.fill")
            
            VStack(spacing: 12) {
                ForEach([
                    ("Light", "sun.max.fill", "light"),
                    ("Dark", "moon.fill", "dark"),
                    ("System", "circle.lefthalf.filled", "system")
                ], id: \.2) { theme in
                    SelectableCard(
                        isSelected: preferredColorScheme == theme.2,
                        action: { preferredColorScheme = theme.2 }
                    ) {
                        HStack {
                            Image(systemName: theme.1)
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundColor(preferredColorScheme == theme.2 ? .white : Color("SecondaryText"))
                            
                            Text(theme.0)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(preferredColorScheme == theme.2 ? .white : Color("PrimaryText"))
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var quickPracticeLevelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Practice Levels", icon: "graduationcap.fill")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(Array(PracticeSettings.hskLevels), id: \.self) { level in
                    let isSelected = progressService.settings.selectedHSKLevels.contains(level)
                    Button(action: { toggleLevel(level) }) {
                        Text("HSK \(level)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color("MidnightGreen") : Color("SecondaryBackground"))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func toggleLevel(_ level: Int) {
        var levels = progressService.settings.selectedHSKLevels
        if levels.contains(level) {
            guard levels.count > 1 else { return }
            levels.remove(level)
        } else {
            levels.insert(level)
        }
        progressService.settings.selectedHSKLevels = levels
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "About", icon: "info.circle.fill")

            HStack {
                Text("Version")
                    .foregroundColor(Color("PrimaryText"))
                Spacer()
                Text(appVersion)
                    .foregroundColor(Color("SecondaryText"))
            }
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SecondaryBackground"))
            )

            Text("All your progress stays on this device. No account, no tracking.")
                .font(.system(size: 13))
                .foregroundColor(Color("SecondaryText"))

            Text("Word lists follow the official HSK syllabus. Word data from complete-hsk-vocabulary by Yanis Zafirópulos (MIT). English meanings from CC-CEDICT, licensed CC BY-SA 4.0.")
                .font(.system(size: 13))
                .foregroundColor(Color("SecondaryText"))
                .accessibilityIdentifier("settings.credits")
        }
    }

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var practiceModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Word Order", icon: "brain.head.profile")
            
            VStack(spacing: 12) {
                ForEach(PracticeMode.allCases, id: \.self) { mode in
                    SelectableCard(
                        isSelected: progressService.settings.practiceMode == mode,
                        action: { progressService.settings.practiceMode = mode }
                    ) {
                        HStack {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundColor(progressService.settings.practiceMode == mode ? .white : Color("SecondaryText"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(progressService.settings.practiceMode == mode ? .white : Color("PrimaryText"))
                                
                                Text(mode.description)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(progressService.settings.practiceMode == mode ? .white.opacity(0.8) : Color("SecondaryText"))
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var displayOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Display Options", icon: "eye.fill")
            
            VStack(spacing: 0) {
                ToggleRow(
                    title: "Require Tones",
                    description: "Answers need the right tones (numbers or marks)",
                    isOn: $progressService.settings.requireTones
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Show English Translation",
                    description: "Display English meaning during practice",
                    isOn: $progressService.settings.showEnglishTranslation
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Pronunciation Hints",
                    description: "Memory aids for pinyin pronunciation",
                    isOn: $progressService.settings.showPronunciationHints
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Character Hints", 
                    description: "Memory aids for character meaning",
                    isOn: $progressService.settings.showCharacterHints
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Use Traditional Characters",
                    description: "Practice with traditional instead of simplified",
                    isOn: $progressService.settings.useTraditional
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Show Full Meanings",
                    description: "Include linguistic notes in translations",
                    isOn: $progressService.settings.showFullMeaning
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Speak on Correct Answer",
                    description: "Use text-to-speech for Chinese pronunciation",
                    isOn: $progressService.settings.speakOnCorrectAnswer
                )

                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)

                ToggleRow(
                    title: "Speak English Meaning",
                    description: "Read each new word's meaning aloud in practice",
                    isOn: $progressService.settings.speakMeaningOnNewWord
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SecondaryBackground"))
            )
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Voice", icon: "waveform")

            VStack(spacing: 0) {
                voiceRow(.chinese, selection: $chineseVoiceId)
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                voiceRow(.english, selection: $englishVoiceId)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SecondaryBackground"))
            )

            Text("Automatic picks the best voice on your iPhone. For a more natural sound, download an Enhanced or Premium voice in Settings › Accessibility › Spoken Content › Voices, then choose it here.")
                .font(.system(size: 13))
                .foregroundColor(Color("SecondaryText"))
        }
    }

    private func voiceRow(_ language: SpeechLanguage, selection: Binding<String>) -> some View {
        let speech = TextToSpeechService.shared
        let automatic = speech.bestVoice(for: language).map { "Automatic · \($0.name)" } ?? "Automatic"
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(language.name)
                    .font(.system(size: 16))
                    .foregroundColor(Color("PrimaryText"))
                Picker("\(language.name) voice", selection: selection) {
                    Text(automatic).tag("")
                    ForEach(speech.installedVoices(for: language), id: \.identifier) { voice in
                        Text(Self.voiceLabel(voice)).tag(voice.identifier)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Color("MidnightGreen"))
                .accessibilityIdentifier("settings.voice.\(language.rawValue)")
                .onChange(of: selection.wrappedValue) { _, _ in
                    speech.speak(language.sample, in: language)
                }
            }
            Spacer()
            Button {
                speech.speak(language.sample, in: language)
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("VibrantOrange"))
            }
            .accessibilityLabel("Play \(language.name) voice sample")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private static func voiceLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        let region = voice.language.split(separator: "-").last.flatMap { Locale.current.localizedString(forRegionCode: String($0)) }
        return [voice.name, qualityName(voice.quality), region].compactMap { $0 }.joined(separator: " · ")
    }

    private static func qualityName(_ quality: AVSpeechSynthesisVoiceQuality) -> String {
        switch quality {
        case .premium: return "Premium"
        case .enhanced: return "Enhanced"
        default: return "Standard"
        }
    }
    
    private var dataProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Data & Progress", icon: "chart.bar.fill")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Words Learned")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("SecondaryText"))
                        Text("\(progressService.wordsLearnedCount)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("PrimaryText"))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Accuracy")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("SecondaryText"))
                        Text(progressService.progress.formattedAccuracy)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("PrimaryText"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("SecondaryBackground"))
                )
                
                Button(action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                        
                        Text("Reset All Progress")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("PrimaryText"))
                
                Text(description)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("SecondaryText"))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("VibrantOrange"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}