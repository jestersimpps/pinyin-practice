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
    
    // Chapter definitions with titles and descriptions
    static let chapters: [Int: (title: String, description: String)] = [
        // HSK 1
        1: ("你好 (Hello)", "Basic greetings, personal pronouns, introductions, numbers 0-10"),
        2: ("姓名 (Names and Introductions)", "What's your name, surnames and given names"),
        3: ("国家 (Countries and Nationalities)", "Where are you from, countries, languages"),
        4: ("家庭 (Family)", "Family members, age, possessive particle 的"),
        5: ("时间 (Time)", "What time, hours, days of the week, today/yesterday/tomorrow"),
        6: ("日期 (Dates)", "Months, dates, years"),
        7: ("天气 (Weather)", "Weather conditions, hot/cold, rain/sunny"),
        8: ("购物 (Shopping)", "How much, money, buy/sell, this/that"),
        9: ("食物 (Food)", "Eating and drinking, basic foods, hungry/thirsty"),
        10: ("交通 (Transportation)", "Vehicles, go/come, where, home/school"),
        11: ("学习 (Study)", "Study Chinese, teacher/student, books, can/will"),
        12: ("工作 (Work)", "What do you do, professions, busy"),
        13: ("爱好 (Hobbies)", "What do you like, activities, movies/books"),
        14: ("位置 (Locations)", "Where is, directions, inside/outside, here/there"),
        15: ("复习 (Review)", "Comprehensive review of all HSK 1 vocabulary"),
        
        // HSK 2
        16: ("衣服 (Clothing)", "Clothing items, colors, wear, beautiful/ugly"),
        17: ("身体 (Body and Health)", "Body parts, illness, pain, hospital/medicine"),
        18: ("运动 (Sports and Exercise)", "Sports, play, exercise, tired/rest"),
        19: ("旅行 (Travel)", "Travel, transportation, tickets, hotel"),
        20: ("节日 (Festivals and Celebrations)", "Festivals, celebrate, gifts, happy"),
        21: ("学校生活 (School Life)", "School facilities, subjects, homework, exams"),
        22: ("比较 (Comparisons)", "Comparative sentences, more/less, same/different"),
        23: ("动作 (Actions and Activities)", "Daily actions, walking, opening/closing, begin/finish"),
        24: ("情感 (Emotions)", "Happy/sad, angry, worried, love"),
        25: ("方向 (Directions)", "Asking for directions, turn left/right, far/near"),
        26: ("助动词 (Modal Verbs)", "Can/able to, should, want to, have to"),
        27: ("完成时态 (Completed Actions)", "Aspect particles 了/过, currently happening, about to"),
        28: ("复习与测试 (Review and Testing)", "HSK 2 comprehensive review"),
        
        // HSK 3
        29: ("描述人物 (Describing People)", "Physical appearance, personality, character traits"),
        30: ("饮食文化 (Food Culture)", "Chinese cuisine, cooking methods, taste, dining"),
        31: ("住房 (Housing)", "Types of housing, rooms, rent, furniture"),
        32: ("购物消费 (Shopping and Consumption)", "Shopping locations, bargaining, payment, quality"),
        33: ("通讯 (Communication)", "Phone, internet, contact, messages"),
        34: ("工作职业 (Career and Professions)", "Job interview, company, boss/colleague, salary"),
        35: ("教育 (Education)", "University, major, graduate, degree"),
        36: ("环境 (Environment)", "Nature, environmental issues, clean/dirty, protect"),
        37: ("科技 (Technology)", "Computer, internet, technology, modern"),
        38: ("文化艺术 (Culture and Arts)", "Art, music, literature, traditional"),
        39: ("社会关系 (Social Relationships)", "Friends, relationships, society, help each other"),
        40: ("表达观点 (Expressing Opinions)", "I think, opinion, agree/disagree, reason"),
        41: ("时间表达 (Time Expressions)", "Time periods, duration, frequency, recently"),
        42: ("复习与应用 (Review and Application)", "HSK 3 comprehensive review"),
        
        // HSK 4
        43: ("社会现象 (Social Phenomena)", "Social issues, development, change, influence"),
        44: ("经济生活 (Economic Life)", "Economy, business, investment, market"),
        45: ("健康保健 (Health and Healthcare)", "Health, medical treatment, prevention, nutrition"),
        46: ("人际交往 (Interpersonal Relations)", "Communication, cooperation, trust, respect"),
        47: ("学习方法 (Study Methods)", "Learning methods, improve, practice, memory"),
        48: ("文化差异 (Cultural Differences)", "Culture, customs, difference, understanding"),
        49: ("新闻媒体 (News and Media)", "News, media, information, report"),
        50: ("法律道德 (Law and Ethics)", "Law, rules, ethics, justice"),
        51: ("科学技术 (Science and Technology)", "Science, research, innovation, progress"),
        52: ("历史地理 (History and Geography)", "History, ancient, geography, location"),
        53: ("文学艺术 (Literature and Arts)", "Literature, poetry, novel, artistic"),
        54: ("体育竞技 (Sports and Competition)", "Competition, team, victory, championship"),
        55: ("环境保护 (Environmental Protection)", "Environment, protect, pollution, resource"),
        56: ("复习强化 (Review and Reinforcement)", "HSK 4 comprehensive review"),
        
        // HSK 5
        57: ("政治制度 (Political Systems)", "Politics, government, democracy, policy"),
        58: ("哲学思想 (Philosophy and Thought)", "Philosophy, thinking, logic, wisdom"),
        59: ("心理学 (Psychology)", "Psychology, emotion, behavior, personality"),
        60: ("社会学 (Sociology)", "Society, social class, community, population"),
        61: ("国际关系 (International Relations)", "International, diplomacy, cooperation, conflict"),
        62: ("宗教信仰 (Religion and Beliefs)", "Religion, belief, faith, spirit"),
        63: ("科学研究 (Scientific Research)", "Research, experiment, theory, discovery"),
        64: ("医学健康 (Medicine and Health)", "Medicine, treatment, disease, surgery"),
        65: ("教育制度 (Education System)", "Education system, curriculum, teaching method, academic"),
        66: ("文化传承 (Cultural Heritage)", "Heritage, tradition, inherit, preserve"),
        67: ("经济发展 (Economic Development)", "Development, growth, industry, agriculture"),
        68: ("复习综合 (Comprehensive Review)", "HSK 5 comprehensive review"),
        
        // HSK 6
        69: ("学术研究 (Academic Research)", "Academic, research methodology, thesis, analysis"),
        70: ("商业管理 (Business Management)", "Management, strategy, leadership, organization"),
        71: ("法律制度 (Legal System)", "Legal system, court, judge, evidence"),
        72: ("文学创作 (Literary Creation)", "Literature, creation, style, criticism"),
        73: ("艺术评论 (Art Criticism)", "Art criticism, aesthetic, interpretation, masterpiece"),
        74: ("科技创新 (Technological Innovation)", "Innovation, technology transfer, patent, breakthrough"),
        75: ("环境科学 (Environmental Science)", "Environmental science, ecosystem, sustainability, conservation"),
        76: ("心理咨询 (Psychological Counseling)", "Counseling, therapy, mental health, rehabilitation"),
        77: ("社会政策 (Social Policy)", "Social policy, welfare, reform, implementation"),
        78: ("国际贸易 (International Trade)", "International trade, export, import, globalization"),
        79: ("文化交流 (Cultural Exchange)", "Cultural exchange, cross-cultural, integration, diversity"),
        80: ("综合应用 (Comprehensive Application)", "HSK 6 final review, professional communication")
    ]
    
    static func getChapterInfo(chapter: Int) -> (title: String, description: String, hskLevel: Int) {
        let info = chapters[chapter] ?? ("Chapter \(chapter)", "Chapter \(chapter) vocabulary")
        let level = hskLevel(forChapter: chapter)
        return (info.title, info.description, level)
    }
    
    // Check if a chapter number is valid
    static func isValidChapter(_ chapter: Int) -> Bool {
        return chapter >= 1 && chapter <= totalChapters
    }
}