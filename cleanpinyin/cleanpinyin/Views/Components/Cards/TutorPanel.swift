import SwiftUI

struct TutorPanel: View {
    @ObservedObject var tutor: TutorViewModel
    let mistake: MistakeContext
    let hskLevel: Int
    let onSpeak: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tutor.explanation == .idle || tutor.examples == .idle {
                HStack(spacing: 8) {
                    if tutor.explanation == .idle {
                        tutorButton("Why?", icon: "sparkles") {
                            Task { await tutor.explain(mistake) }
                        }
                    }
                    if tutor.examples == .idle {
                        tutorButton("Use it", icon: "text.quote") {
                            Task { await tutor.loadExamples(for: mistake.word, hskLevel: hskLevel) }
                        }
                    }
                }
            }

            explanationContent
            examplesContent
        }
        .animation(.easeInOut(duration: 0.2), value: tutor.explanation)
        .animation(.easeInOut(duration: 0.2), value: tutor.examples)
    }

    @ViewBuilder
    private var explanationContent: some View {
        switch tutor.explanation {
        case .idle:
            EmptyView()
        case .loading:
            loadingRow("Thinking about your answer…")
        case .loaded(let explanation):
            card {
                VStack(alignment: .leading, spacing: 8) {
                    Label(explanation.summary, systemImage: "sparkles")
                        .foregroundColor(Color("PrimaryText"))
                    Label(explanation.memoryTip, systemImage: "lightbulb.fill")
                        .foregroundColor(Color("SecondaryText"))
                }
                .font(.system(size: 15))
            }
        case .failed:
            failureRow
        }
    }

    @ViewBuilder
    private var examplesContent: some View {
        switch tutor.examples {
        case .idle:
            EmptyView()
        case .loading:
            loadingRow("Writing example sentences…")
        case .loaded(let sentences):
            card {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sentences) { sentence in
                        Button(action: { onSpeak(sentence.chinese) }) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(sentence.chinese)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(Color("PrimaryText"))
                                    Spacer()
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(Color("SecondaryText"))
                                }
                                Text(sentence.pinyin)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("MidnightGreen"))
                                Text(sentence.english)
                                    .font(.system(size: 13))
                                    .foregroundColor(Color("SecondaryText"))
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Plays the sentence")
                    }
                }
            }
        case .failed:
            failureRow
        }
    }

    private func tutorButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("MidnightGreen"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color("MidnightGreen").opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    private func loadingRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color("SecondaryText"))
        }
    }

    private var failureRow: some View {
        Text("The tutor couldn't help with this word. Try another one.")
            .font(.system(size: 13))
            .foregroundColor(Color("SecondaryText"))
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("MidnightGreen").opacity(0.08))
            )
    }
}
