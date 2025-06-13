import Foundation

struct ChapterCurriculum {
    static let totalChapters = 80
    
    // Map chapter numbers to HSK levels
    static func hskLevel(forChapter chapter: Int) -> Int {
        switch chapter {
        case 1...15: return 1
        case 16...28: return 2
        case 29...42: return 3
        case 43...56: return 4
        case 57...68: return 5
        case 69...80: return 6
        default: return 1
        }
    }
    
    // Chapter definitions with titles, descriptions, and icons
    static let chapters: [Int: (title: String, description: String, icon: String)] = [
        // HSK 1
        1: ("你好 Hello", "Basic greetings, personal pronouns, introductions, numbers 0-10", "hand.wave"),
        2: ("姓名 Names and Introductions", "What's your name, surnames and given names", "person.text.rectangle"),
        3: ("国家 Countries and Nationalities", "Where are you from, countries, languages", "globe"),
        4: ("家庭 Family", "Family members, age, possessive particle 的", "figure.2.and.child.holdinghands"),
        5: ("时间 Time", "What time, hours, days of the week, today/yesterday/tomorrow", "clock"),
        6: ("日期 Dates", "Months, dates, years", "calendar"),
        7: ("天气 Weather", "Weather conditions, hot/cold, rain/sunny", "cloud.sun"),
        8: ("购物 Shopping", "How much, money, buy/sell, this/that", "cart"),
        9: ("食物 Food", "Eating and drinking, basic foods, hungry/thirsty", "fork.knife"),
        10: ("交通 Transportation", "Vehicles, go/come, where, home/school", "car"),
        11: ("学习 Study", "Study Chinese, teacher/student, books, can/will", "book"),
        12: ("工作 Work", "What do you do, professions, busy", "briefcase"),
        13: ("爱好 Hobbies", "What do you like, activities, movies/books", "heart"),
        14: ("位置 Locations", "Where is, directions, inside/outside, here/there", "map"),
        15: ("复习 Review", "Comprehensive review of all HSK 1 vocabulary", "arrow.clockwise"),
        
        // HSK 2
        16: ("衣服 Clothing", "Clothing items, colors, wear, beautiful/ugly", "tshirt"),
        17: ("身体 Body and Health", "Body parts, illness, pain, hospital/medicine", "heart.text.square"),
        18: ("运动 Sports and Exercise", "Sports, play, exercise, tired/rest", "figure.run"),
        19: ("旅行 Travel", "Travel, transportation, tickets, hotel", "airplane"),
        20: ("节日 Festivals and Celebrations", "Festivals, celebrate, gifts, happy", "gift"),
        21: ("学校生活 School Life", "School facilities, subjects, homework, exams", "graduationcap"),
        22: ("比较 Comparisons", "Comparative sentences, more/less, same/different", "arrow.up.arrow.down"),
        23: ("动作 Actions and Activities", "Daily actions, walking, opening/closing, begin/finish", "figure.walk"),
        24: ("情感 Emotions", "Happy/sad, angry, worried, love", "face.smiling"),
        25: ("方向 Directions", "Asking for directions, turn left/right, far/near", "arrow.turn.right.up"),
        26: ("助动词 Modal Verbs", "Can/able to, should, want to, have to", "bubble.left.and.bubble.right"),
        27: ("完成时态 Completed Actions", "Aspect particles 了/过, currently happening, about to", "checkmark.circle"),
        28: ("复习与测试 Review and Testing", "HSK 2 comprehensive review", "arrow.triangle.2.circlepath"),
        
        // HSK 3
        29: ("描述人物 Describing People", "Physical appearance, personality, character traits", "person.crop.circle"),
        30: ("饮食文化 Food Culture", "Chinese cuisine, cooking methods, taste, dining", "fork.knife.circle"),
        31: ("住房 Housing", "Types of housing, rooms, rent, furniture", "house"),
        32: ("购物消费 Shopping and Consumption", "Shopping locations, bargaining, payment, quality", "creditcard"),
        33: ("通讯 Communication", "Phone, internet, contact, messages", "phone"),
        34: ("工作职业 Career and Professions", "Job interview, company, boss/colleague, salary", "person.crop.square"),
        35: ("教育 Education", "University, major, graduate, degree", "book.closed"),
        36: ("环境 Environment", "Nature, environmental issues, clean/dirty, protect", "leaf"),
        37: ("科技 Technology", "Computer, internet, technology, modern", "laptopcomputer"),
        38: ("文化艺术 Culture and Arts", "Art, music, literature, traditional", "paintbrush"),
        39: ("社会关系 Social Relationships", "Friends, relationships, society, help each other", "person.2"),
        40: ("表达观点 Expressing Opinions", "I think, opinion, agree/disagree, reason", "bubble.left"),
        41: ("时间表达 Time Expressions", "Time periods, duration, frequency, recently", "timer"),
        42: ("复习与应用 Review and Application", "HSK 3 comprehensive review", "arrow.clockwise.circle"),
        
        // HSK 4
        43: ("社会现象 Social Phenomena", "Social issues, development, change, influence", "person.3"),
        44: ("经济生活 Economic Life", "Economy, business, investment, market", "chart.line.uptrend.xyaxis"),
        45: ("健康保健 Health and Healthcare", "Health, medical treatment, prevention, nutrition", "heart.circle"),
        46: ("人际交往 Interpersonal Relations", "Communication, cooperation, trust, respect", "person.2.circle"),
        47: ("学习方法 Study Methods", "Learning methods, improve, practice, memory", "brain"),
        48: ("文化差异 Cultural Differences", "Culture, customs, difference, understanding", "globe.americas.fill"),
        49: ("新闻媒体 News and Media", "News, media, information, report", "newspaper"),
        50: ("法律道德 Law and Ethics", "Law, rules, ethics, justice", "scalemass"),
        51: ("科学技术 Science and Technology", "Science, research, innovation, progress", "atom"),
        52: ("历史地理 History and Geography", "History, ancient, geography, location", "map.circle"),
        53: ("文学艺术 Literature and Arts", "Literature, poetry, novel, artistic", "book.pages"),
        54: ("体育竞技 Sports and Competition", "Competition, team, victory, championship", "trophy"),
        55: ("环境保护 Environmental Protection", "Environment, protect, pollution, resource", "leaf.circle"),
        56: ("复习强化 Review and Reinforcement", "HSK 4 comprehensive review", "arrow.triangle.2.circlepath.circle"),
        
        // HSK 5
        57: ("政治制度 Political Systems", "Politics, government, democracy, policy", "building.columns"),
        58: ("哲学思想 Philosophy and Thought", "Philosophy, thinking, logic, wisdom", "brain.filled.head.profile"),
        59: ("心理学 Psychology", "Psychology, emotion, behavior, personality", "person.crop.circle.badge.questionmark"),
        60: ("社会学 Sociology", "Society, social class, community, population", "person.3.sequence"),
        61: ("国际关系 International Relations", "International, diplomacy, cooperation, conflict", "globe.asia.australia"),
        62: ("宗教信仰 Religion and Beliefs", "Religion, belief, faith, spirit", "star.circle"),
        63: ("科学研究 Scientific Research", "Research, experiment, theory, discovery", "flask"),
        64: ("医学健康 Medicine and Health", "Medicine, treatment, disease, surgery", "cross.case"),
        65: ("教育制度 Education System", "Education system, curriculum, teaching method, academic", "building.2"),
        66: ("文化传承 Cultural Heritage", "Heritage, tradition, inherit, preserve", "building.columns.circle"),
        67: ("经济发展 Economic Development", "Development, growth, industry, agriculture", "chart.bar"),
        68: ("复习综合 Comprehensive Review", "HSK 5 comprehensive review", "arrow.counterclockwise.circle"),
        
        // HSK 6
        69: ("学术研究 Academic Research", "Academic, research methodology, thesis, analysis", "doc.text"),
        70: ("商业管理 Business Management", "Management, strategy, leadership, organization", "person.crop.rectangle.stack"),
        71: ("法律制度 Legal System", "Legal system, court, judge, evidence", "scroll"),
        72: ("文学创作 Literary Creation", "Literature, creation, style, criticism", "pencil.and.outline"),
        73: ("艺术评论 Art Criticism", "Art criticism, aesthetic, interpretation, masterpiece", "paintpalette"),
        74: ("科技创新 Technological Innovation", "Innovation, technology transfer, patent, breakthrough", "lightbulb"),
        75: ("环境科学 Environmental Science", "Environmental science, ecosystem, sustainability, conservation", "globe.badge.chevron.backward"),
        76: ("心理咨询 Psychological Counseling", "Counseling, therapy, mental health, rehabilitation", "person.crop.circle.badge.plus"),
        77: ("社会政策 Social Policy", "Social policy, welfare, reform, implementation", "doc.badge.gearshape"),
        78: ("国际贸易 International Trade", "International trade, export, import, globalization", "shippingbox"),
        79: ("文化交流 Cultural Exchange", "Cultural exchange, cross-cultural, integration, diversity", "globe.europe.africa"),
        80: ("综合应用 Comprehensive Application", "HSK 6 final review, professional communication", "checkmark.seal")
    ]
    
    static func getChapterInfo(chapter: Int) -> (title: String, description: String, hskLevel: Int, icon: String) {
        let info = chapters[chapter] ?? ("Chapter \(chapter)", "Chapter \(chapter) vocabulary", "book")
        let level = hskLevel(forChapter: chapter)
        return (info.title, info.description, level, info.icon)
    }
    
    
    // Get number of chapters for a given HSK level
    static func chaptersForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 15  // chapters 1-15
        case 2: return 13  // chapters 16-28
        case 3: return 14  // chapters 29-42
        case 4: return 14  // chapters 43-56
        case 5: return 12  // chapters 57-68
        case 6: return 12  // chapters 69-80
        default: return 0
        }
    }
}