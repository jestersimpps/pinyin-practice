import SwiftUI

struct ChapterCompletionView: View {
    let chapter: Chapter
    let chapterProgress: ChapterProgress
    let onContinue: () -> Void
    let onReview: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private var nextChapterInfo: (title: String, description: String, hskLevel: Int)? {
        if chapter.chapterNumber < ChapterCurriculum.totalChapters {
            return ChapterCurriculum.getChapterInfo(chapter: chapter.chapterNumber + 1)
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.4),
                    Color(red: 0.05, green: 0.15, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti particles
            ConfettiView()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.5), radius: 20)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.1)
                .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2), value: true)
                
                // Congratulations text
                VStack(spacing: 12) {
                    Text("恭喜！")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Chapter Complete!")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Chapter info
                VStack(spacing: 8) {
                    Text(chapter.displayTitle)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(chapterProgress.wordsCompleted.count) words mastered")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Stats
                HStack(spacing: 40) {
                    StatBadge(
                        icon: "clock.fill",
                        value: formatDuration(chapterProgress.totalPracticeTime),
                        label: "Time"
                    )
                    
                    StatBadge(
                        icon: "target",
                        value: "\(Int(chapterProgress.accuracy ?? 100))%",
                        label: "Accuracy"
                    )
                    
                    StatBadge(
                        icon: "star.fill",
                        value: "\(chapterProgress.totalAttempts)",
                        label: "Attempts"
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if let nextChapter = nextChapterInfo {
                        // Next chapter preview
                        VStack(spacing: 8) {
                            Text("Next Chapter")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(nextChapter.title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 8)
                        
                        Button(action: onContinue) {
                            HStack {
                                Text("Continue to Next Chapter")
                                    .font(.system(size: 18, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                            )
                        }
                    }
                    
                    Button(action: onReview) {
                        Text("Review This Chapter")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Back to Chapters")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let hours = minutes / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// Simple confetti animation
private struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                ConfettiPiece(delay: Double(index) * 0.1)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

private struct ConfettiPiece: View {
    let delay: Double
    @State private var yPosition: CGFloat = -100
    @State private var opacity: Double = 1
    
    private let color = [
        Color(red: 0.95, green: 0.35, blue: 0.35),
        Color(red: 0.35, green: 0.85, blue: 0.35),
        Color(red: 0.35, green: 0.55, blue: 0.95),
        Color(red: 0.95, green: 0.85, blue: 0.35),
        Color(red: 0.85, green: 0.35, blue: 0.95)
    ].randomElement()!
    
    private let xPosition = CGFloat.random(in: -150...150)
    private let size = CGFloat.random(in: 8...16)
    private let rotationAngle = Double.random(in: 0...360)
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotationAngle))
            .position(x: UIScreen.main.bounds.width / 2 + xPosition, y: yPosition)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5).delay(delay)) {
                    yPosition = UIScreen.main.bounds.height + 100
                    opacity = 0
                }
            }
    }
}