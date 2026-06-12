import SwiftUI

struct LevelTabBar: View {
    struct Tab: Identifiable {
        let id: Int
        let title: String

        static func hskLevels() -> [Tab] {
            (1...6).map { Tab(id: $0, title: "HSK \($0)") }
        }

        static func withCustom() -> [Tab] {
            [Tab(id: Chapter.customLevel, title: "Custom")] + hskLevels()
        }
    }

    let tabs: [Tab]
    @Binding var selectedLevel: Int
    var selectedColor: Color = Color("MidnightGreen")

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(tabs) { tab in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedLevel = tab.id
                    }) {
                        Text(tab.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedLevel == tab.id ? .white : Color("PrimaryText"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedLevel == tab.id ? selectedColor : Color("SecondaryBackground"))
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color("SecondaryBackground").opacity(0.5))
    }
}
