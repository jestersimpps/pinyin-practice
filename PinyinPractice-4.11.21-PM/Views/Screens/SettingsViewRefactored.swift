import SwiftUI

struct SettingsViewRefactored: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @StateObject private var progressService = UserProgressService.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        themeSection
                        practiceModeSection
                        displayOptionsSection
                        dataProgressSection
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
                    .font(Typography.primaryButtonFont)
                    .foregroundColor(.vibrantOrange)
                }
            }
        }
        .alert("Reset Progress", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                progressService.resetProgress()
            }
        } message: {
            Text("Are you sure you want to reset all your progress? This action cannot be undone.")
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
                                .foregroundColor(preferredColorScheme == theme.2 ? .vibrantOrange : .secondaryText)
                            
                            Text(theme.0)
                                .font(Typography.bodyFont)
                                .foregroundColor(preferredColorScheme == theme.2 ? .primaryText : .primaryText)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var practiceModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Practice Mode", icon: "brain.head.profile")
            
            VStack(spacing: 12) {
                ForEach(PracticeSettings.PracticeMode.allCases, id: \.self) { mode in
                    SelectableCard(
                        isSelected: progressService.settings.practiceMode == mode,
                        action: { progressService.settings.practiceMode = mode }
                    ) {
                        HStack {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .frame(width: 30)
                                .foregroundColor(progressService.settings.practiceMode == mode ? .vibrantOrange : .secondaryText)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(Typography.bodyFont)
                                    .foregroundColor(.primaryText)
                                
                                Text(mode.description)
                                    .font(Typography.smallCaptionFont)
                                    .foregroundColor(.secondaryText)
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
                    description: "Must enter correct tone marks or numbers",
                    isOn: $progressService.settings.requireTones
                )
                
                Divider()
                    .background(Color.lightSilver.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Show English Translation",
                    description: "Display English meaning during practice",
                    isOn: $progressService.settings.showEnglishTranslation
                )
                
                Divider()
                    .background(Color.lightSilver.opacity(0.3))
                    .padding(.horizontal, 16)
                
                ToggleRow(
                    title: "Show Hints",
                    description: "Enable hint button for difficult words",
                    isOn: $progressService.settings.showHints
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondaryBackground)
            )
        }
    }
    
    private var dataProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Data & Progress", icon: "chart.bar.fill")
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Words Learned")
                            .font(Typography.captionFont)
                            .foregroundColor(.secondaryText)
                        Text("\(progressService.progress.wordsSeenCount)")
                            .font(Typography.headlineFont)
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Accuracy")
                            .font(Typography.captionFont)
                            .foregroundColor(.secondaryText)
                        Text(progressService.progress.formattedAccuracy)
                            .font(Typography.headlineFont)
                            .foregroundColor(.primaryText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondaryBackground)
                )
                
                Button(action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .font(.title3)
                            .foregroundColor(.errorRed)
                        
                        Text("Reset All Progress")
                            .font(Typography.bodyFont)
                            .foregroundColor(.errorRed)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.errorRed.opacity(0.1))
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
                    .font(Typography.bodyFont)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(Typography.smallCaptionFont)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.vibrantOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct SettingsViewRefactored_Previews: PreviewProvider {
    static var previews: some View {
        SettingsViewRefactored()
    }
}