import Foundation

class VocabularyService: ObservableObject {
    static let shared = VocabularyService()
    
    @Published var allVocabulary: [VocabularyItem] = []
    @Published var isLoading = false
    
    private init() {
        loadVocabulary()
    }
    
    func loadVocabulary() {
        isLoading = true
        
        // For now, we'll load a sample dataset. 
        // Later this will be replaced with the full HSK vocabulary
        allVocabulary = Self.getSampleVocabulary()
        
        isLoading = false
    }
    
    func getFilteredVocabulary(levels: Set<HSKLevel>, categories: Set<VocabularyCategory>) -> [VocabularyItem] {
        return allVocabulary.filter { item in
            levels.contains(item.hskLevel) && categories.contains(item.category)
        }
    }
    
    func getReviewVocabulary(incorrectWordIds: Set<String>) -> [VocabularyItem] {
        return allVocabulary.filter { incorrectWordIds.contains($0.id) }
    }
    
    // Sample vocabulary for testing
    static func getSampleVocabulary() -> [VocabularyItem] {
        return [
            VocabularyItem(
                id: "1",
                chinese: "爱",
                pinyin: "ài",
                english: "to love",
                category: "emotions",
                hint: "Imagine saying 'Aww, I love you!' - the sound 'ài' is like 'aww' of affection.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "2",
                chinese: "八",
                pinyin: "bā",
                english: "eight",
                category: "numbers",
                hint: "Picture a 'BAR' (bā) with 8 stools.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "3",
                chinese: "爸爸",
                pinyin: "bà ba",
                english: "father",
                category: "family",
                hint: "Think of a baby saying 'baba' to daddy.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "4",
                chinese: "你",
                pinyin: "nǐ",
                english: "you",
                category: "pronouns",
                hint: "Think 'KNEE' (nǐ) - pointing at someone's knee to say 'you'.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "5",
                chinese: "好",
                pinyin: "hǎo",
                english: "good",
                category: "adjectives",
                hint: "Think 'HOW' (hǎo) good!",
                level: .hsk1
            ),
            VocabularyItem(
                id: "6",
                chinese: "谢谢",
                pinyin: "xiè xie",
                english: "thank you",
                category: "phrases",
                hint: "Sounds like 'sheh-sheh' - imagine shaking hands twice.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "7",
                chinese: "中国",
                pinyin: "zhōng guó",
                english: "China",
                category: "countries",
                hint: "Think 'JONG-gwo' - the middle kingdom.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "8",
                chinese: "学习",
                pinyin: "xué xí",
                english: "to study",
                category: "verbs",
                hint: "Think 'SHWAY-she' - the way she studies.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "9",
                chinese: "老师",
                pinyin: "lǎo shī",
                english: "teacher",
                category: "professions",
                hint: "Think 'LAO-sure' - the teacher is sure about knowledge.",
                level: .hsk1
            ),
            VocabularyItem(
                id: "10",
                chinese: "朋友",
                pinyin: "péng yǒu",
                english: "friend",
                category: "family",
                hint: "Think 'PUNG-yo' - punching your friend playfully.",
                level: .hsk1
            )
        ]
    }
}