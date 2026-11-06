import SwiftUI

struct PracticeCompletionView: View {
    let sessionStats: SessionStats
    let onContinue: () -> Void
    let onFinish: () -> Void
    
    @State private var animateStats = false

    var body: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color("SuccessGreen"))
                        .scaleEffect(animateStats ? 1 : 0.5)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateStats)
                    
                    Text("Practice Complete!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("PrimaryText"))
                        .scaleEffect(animateStats ? 1 : 0.8)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animateStats)
                    
                    Text(sessionStats.practiceMode)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("SecondaryText"))
                        .opacity(animateStats ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.2), value: animateStats)
                }
                .padding(.top, 40)
                
                // Stats Grid
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        CompletionStatCard(
                            title: "Words Studied",
                            value: "\(sessionStats.wordsStudied)",
                            icon: "book.fill",
                            color: .blue
                        )
                        .scaleEffect(animateStats ? 1 : 0.8)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animateStats)
                        
                        CompletionStatCard(
                            title: "Accuracy",
                            value: String(format: "%.0f%%", sessionStats.accuracy),
                            icon: "target",
                            color: sessionStats.accuracy >= 80 ? Color("SuccessGreen") : .orange
                        )
                        .scaleEffect(animateStats ? 1 : 0.8)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4), value: animateStats)
                    }
                    
                    HStack(spacing: 16) {
                        CompletionStatCard(
                            title: "Time",
                            value: sessionStats.formattedDuration,
                            icon: "clock.fill",
                            color: .purple
                        )
                        .scaleEffect(animateStats ? 1 : 0.8)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5), value: animateStats)
                        
                        CompletionStatCard(
                            title: "Best Combo",
                            value: "\(sessionStats.bestCombo)",
                            icon: "bolt.fill",
                            color: sessionStats.bestCombo > 0 ? .orange : Color("SecondaryText")
                        )
                        .scaleEffect(animateStats ? 1 : 0.8)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6), value: animateStats)
                    }
                }
                .padding(.horizontal, 20)
                
                // Performance Message
                if animateStats {
                    Text(performanceMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color("PrimaryText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animateStats ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(0.7), value: animateStats)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("Continue Practice")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("MidnightGreen"))
                            )
                    }
                    
                    Button(action: onFinish) {
                        Text("Back to Home")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("PrimaryText"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("SecondaryBackground"))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(animateStats ? 1 : 0)
                .animation(.easeInOut(duration: 0.3).delay(0.8), value: animateStats)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateStats = true
            }
        }
    }
    
    private var performanceMessage: String {
        let accuracy = sessionStats.accuracy
        
        switch accuracy {
        case 90...100:
            return "Outstanding! You're mastering these words! 🌟"
        case 80..<90:
            return "Great job! Keep up the excellent work! 💪"
        case 70..<80:
            return "Good progress! You're getting there! 📈"
        case 60..<70:
            return "Nice effort! Practice makes perfect! 🎯"
        default:
            return "Keep practicing! You'll improve with time! 💡"
        }
    }
}

struct CompletionStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryText"))
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("SecondaryBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}