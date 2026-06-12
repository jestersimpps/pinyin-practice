import SwiftUI

struct ChapterCard: View {
    let chapter: Chapter
    let isSelected: Bool
    var progress: ChapterProgress? = nil
    var isUnlocked: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: chapter.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(iconBackgroundColor)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.displayTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(textColor)

                        Text(chapter.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text("\(chapter.wordCount) words")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                    }

                    Spacer()

                    trailingIcon
                }

                if let progress, progress.wordsCompleted.count > 0 {
                    progressSection(progress)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if !isUnlocked {
            Image(systemName: "lock.fill")
                .font(.title3)
                .foregroundColor(Color("SecondaryText"))
        } else if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
        } else {
            Image(systemName: "circle")
                .font(.title2)
                .foregroundColor(Color("SecondaryText"))
        }
    }

    private func progressSection(_ progress: ChapterProgress) -> some View {
        VStack(spacing: 4) {
            ProgressView(value: progress.completionPercentage, total: 100)
                .tint(progressColor(progress))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            HStack {
                Text("\(Int(progress.completionPercentage))% complete")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(secondaryTextColor)

                Spacer()

                if progress.isCompleted {
                    Label("Completed", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color("SuccessGreen"))
                }
            }
        }
    }

    private var textColor: Color {
        if !isUnlocked {
            return Color("SecondaryText")
        } else if isSelected {
            return .white
        } else {
            return Color("PrimaryText")
        }
    }

    private var secondaryTextColor: Color {
        if !isUnlocked {
            return Color("SecondaryText").opacity(0.6)
        } else if isSelected {
            return .white.opacity(0.8)
        } else {
            return Color("SecondaryText")
        }
    }

    private var backgroundColor: Color {
        if !isUnlocked {
            return Color("SecondaryBackground").opacity(0.3)
        } else if isSelected {
            return Color("MidnightGreen")
        } else {
            return Color("SecondaryBackground").opacity(0.5)
        }
    }

    private var borderColor: Color {
        if !isUnlocked {
            return Color.gray.opacity(0.2)
        } else if isSelected {
            return Color.clear
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private func progressColor(_ progress: ChapterProgress) -> Color {
        if progress.isCompleted {
            return Color("SuccessGreen")
        } else if progress.completionPercentage >= AppConstants.Chapters.unlockRequirement * 100 {
            return Color("VibrantOrange")
        } else {
            return Color("MidnightGreen")
        }
    }

    private var iconColor: Color {
        if !isUnlocked {
            return Color("SecondaryText").opacity(0.4)
        } else if isSelected {
            return .white
        } else {
            return Color("MidnightGreen")
        }
    }

    private var iconBackgroundColor: Color {
        if !isUnlocked {
            return Color("SecondaryText").opacity(0.1)
        } else if isSelected {
            return Color.white.opacity(0.2)
        } else {
            return Color("MidnightGreen").opacity(0.1)
        }
    }
}
