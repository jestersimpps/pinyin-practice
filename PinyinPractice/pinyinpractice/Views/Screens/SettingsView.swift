import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("preferredColorScheme") private var preferredColorScheme: String = "system"
    @StateObject private var progressService = UserProgressService.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("PrimaryBackground")
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
                    description: "Must enter correct tone marks or numbers",
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
                    title: "Show Hints",
                    description: "Enable hint button for difficult words",
                    isOn: $progressService.settings.showHints
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("SecondaryBackground"))
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
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("SecondaryText"))
                        Text("\(progressService.progress.wordsSeenCount)")
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