//
//  VocabularyDataManager.swift
//  travel
//
//  Created by fushuai on 2026/3/7.
//

import Foundation

// MARK: - JSON 数据结构
struct JLPTData: Codable {
    let meta: Meta
    let intermediate1: [VocabularyItem]?
    let intermediate2: [VocabularyItem]?
    let primary1: [VocabularyItem]?
}

struct Meta: Codable {
    let sourceFile: String?
    let generatedAt: String?
    let counts: Counts?
}

struct Counts: Codable {
    let primary1: Int?
    let intermediate1: Int?
    let intermediate2: Int?
    let total: Int
}

struct VocabularyItem: Codable {
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    let lesson: String
    let sheet: String
    // 新增：3条例句（中英文翻译通过API获取）
    let japaneseExamples: [String]?
    let chineseExamples: [String]?
    let englishExamples: [String]?
}

// MARK: - 应用词汇模型
struct AppVocabularyWord: Identifiable, Codable {
    let id: UUID
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    let lesson: String
    let level: String
    // 3条日语例句
    let japaneseExamples: [String]
    // 3条中文翻译
    let chineseExamples: [String]
    // 3条英文翻译
    let englishExamples: [String]
    
    // 兼容旧版本数据的初始化器
    var japaneseExample: String { japaneseExamples.first ?? "" }
    var englishExample: String { englishExamples.first ?? "" }
    var chineseExample: String { chineseExamples.first ?? "" }
    
    init(from item: VocabularyItem, level: String) {
        // 使用基于内容的稳定 UUID，保证同一个单词在不同启动之间 ID 不变
        let simplifiedLesson = Self.convertToSimplifiedChinese(item.lesson)
        let key = "\(level)|\(simplifiedLesson)|\(item.sheet)|\(item.word)|\(item.reading)"
        self.id = Self.makeStableUUID(from: key)
        self.word = item.word
        self.reading = item.reading.isEmpty ? "読み方なし" : item.reading
        self.meaning = item.meaning
        self.partOfSpeech = item.partOfSpeech
        // 将 lesson 转换为简体格式，确保与界面匹配
        self.lesson = simplifiedLesson
        self.level = level
        
        // 生成3条示例句子
        let generatedJP = Self.generateJapaneseExamples(word: item.word, partOfSpeech: item.partOfSpeech)
        let generatedEN = Self.generateEnglishExamples(word: item.word, meaning: item.meaning)
        let generatedCN = Self.generateChineseExamples(word: item.word, meaning: item.meaning)
        
        // 检查是否有预翻译的数据
        if let translatedExamples = item.japaneseExamples, !translatedExamples.isEmpty {
            self.japaneseExamples = translatedExamples
        } else {
            self.japaneseExamples = generatedJP
        }
        
        if let translatedExamples = item.chineseExamples, !translatedExamples.isEmpty {
            self.chineseExamples = translatedExamples
        } else {
            self.chineseExamples = generatedCN
        }
        
        if let translatedExamples = item.englishExamples, !translatedExamples.isEmpty {
            self.englishExamples = translatedExamples
        } else {
            self.englishExamples = generatedEN
        }
    }
    
    // 将繁体中文转换为简体中文
    private static func convertToSimplifiedChinese(_ text: String) -> String {
        var result = text
        // 课程相关的繁体转简体
        result = result.replacingOccurrences(of: "課", with: "课")
        result = result.replacingOccurrences(of: "語", with: "语")
        result = result.replacingOccurrences(of: "詞", with: "词")
        result = result.replacingOccurrences(of: "説", with: "说")
        return result
    }
    
    private static func generateJapaneseExamples(word: String, partOfSpeech: String) -> [String] {
        let templates: [String: [String]] = [
            "名词": [
                "これは\(word)です。",
                "\(word)使えますか。",
                "\(word)が好きです。"
            ],
            "代词": [
                "それは\(word)です。",
                "\(word)は何ですか。",
                "\(word)が好きです。"
            ],
            "动词": [
                "\(word)てください。",
                "\(word)ます。",
                "\(word)たいです。"
            ],
            "形容词": [
                "\(word)です。",
                "\(word)いです。",
                "\(word)くないです。"
            ],
            "default": [
                "これは\(word)の例文です。",
                "\(word)を使ってみましょう。",
                "\(word)の意味を理解する。"
            ]
        ]
        
        let selected = templates[partOfSpeech] ?? templates["default"]!
        return selected
    }
    
    private static func generateChineseExamples(word: String, meaning: String) -> [String] {
        // 使用词汇的中文意思生成中文例句
        return [
            "这是「\(word)」的例句：\(meaning)。",
            "请使用「\(word)」这个词。",
            "「\(word)」的意思是\(meaning)。"
        ]
    }

    private static func generateEnglishExamples(word: String, meaning: String) -> [String] {
        return [
            "This is an example of \(word).",
            "Let's try using \(word).",
            "Understanding the meaning of \(word)."
        ]
    }
    
    /// 根据字符串生成稳定的 UUID，用于在不同启动之间保持同一单词的 ID 一致
    private static func makeStableUUID(from string: String) -> UUID {
        var hasher = Hasher()
        hasher.combine(string)
        let hashValue = hasher.finalize()
        
        // 使用 64 位 hash 构造一个 128 位的 UUID（高 64 位是 hash，低 64 位是其按位取反）
        let high = UInt64(bitPattern: Int64(hashValue))
        let low = ~high
        
        // 将两个 64 位整数拆成 16 个字节，填充到 uuid_t 中
        let bytes: uuid_t = (
            UInt8((high >> 56) & 0xFF),
            UInt8((high >> 48) & 0xFF),
            UInt8((high >> 40) & 0xFF),
            UInt8((high >> 32) & 0xFF),
            UInt8((high >> 24) & 0xFF),
            UInt8((high >> 16) & 0xFF),
            UInt8((high >> 8) & 0xFF),
            UInt8(high & 0xFF),
            UInt8((low >> 56) & 0xFF),
            UInt8((low >> 48) & 0xFF),
            UInt8((low >> 40) & 0xFF),
            UInt8((low >> 32) & 0xFF),
            UInt8((low >> 24) & 0xFF),
            UInt8((low >> 16) & 0xFF),
            UInt8((low >> 8) & 0xFF),
            UInt8(low & 0xFF)
        )
        
        return UUID(uuid: bytes)
    }
}

// MARK: - 数据管理器
class VocabularyDataManager: ObservableObject {
    static let shared = VocabularyDataManager()
    
    @Published var allWords: [AppVocabularyWord] = []
    
    private enum DataSourceType {
        case primary      // 标准日本语初级
        case intermediate // 大家的日本语（中级①、②）
    }
    
    private init() {
        loadVocabularyData()
    }
    
    private func loadVocabularyData() {
        var loadedWords: [AppVocabularyWord] = []
        
        // MARK: 加载「标准日本语初级上册」词汇（jlpt_primary_summary.json）
        
        if let primaryFromBundle = loadPrimaryWordsFromBundle() {
            loadedWords.append(contentsOf: primaryFromBundle)
        } else if let primaryFromDocuments = loadPrimaryWordsFromDocuments() {
            loadedWords.append(contentsOf: primaryFromDocuments)
        } else {
            print("未找到初级词汇文件 jlpt_primary_summary.json")
        }
        
        // MARK: 加载「大家的日本语」词汇（jlpt_intermediate_summary.json，中级①+中级②）
        
        if let minnaFromBundle = loadIntermediateWordsFromBundle() {
            loadedWords.append(contentsOf: minnaFromBundle)
        } else if let minnaFromDocuments = loadIntermediateWordsFromDocuments() {
            loadedWords.append(contentsOf: minnaFromDocuments)
        } else {
            print("未找到中级词汇文件 jlpt_intermediate_summary.json")
        }
        
        if loadedWords.isEmpty {
            print("未找到任何词汇文件，使用备用数据")
            // 加载示例数据作为备用
            loadSampleData()
        } else {
            allWords = loadedWords
            print("总共加载词汇数据: \(allWords.count) 个单词")
        }
    }
    
    // MARK: - 各来源加载辅助方法
    
    private func loadPrimaryWordsFromBundle() -> [AppVocabularyWord]? {
        // 优先尝试带例句的版本
        if let url = Bundle.main.url(forResource: "jlpt_primary_summary_with_examples", withExtension: "json") {
            print("找到 Bundle 中的带例句词汇文件: \(url)")
            if let words = loadWordsFromURL(url, level: "标准日本语初级上册", sourceType: .primary) {
                print("成功从 Bundle 加载带例句词汇数据: \(words.count) 个单词")
                return words
            }
        }
        // 回退到旧版本
        if let url = Bundle.main.url(forResource: "jlpt_primary_summary", withExtension: "json") {
            print("找到 Bundle 中的初级词汇文件: \(url)")
            if let words = loadWordsFromURL(url, level: "标准日本语初级上册", sourceType: .primary) {
                print("成功从 Bundle 加载初级词汇数据: \(words.count) 个单词")
                return words
            }
        }
        return nil
    }
    
    private func loadPrimaryWordsFromDocuments() -> [AppVocabularyWord]? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        // 优先尝试带例句的版本
        if let url = documentsPath?.appendingPathComponent("jlpt_primary_summary_with_examples.json") {
            print("尝试从 Documents 加载带例句词汇: \(url)")
            if let words = loadWordsFromURL(url, level: "标准日本语初级上册", sourceType: .primary) {
                print("成功从 Documents 加载带例句词汇数据: \(words.count) 个单词")
                return words
            }
        }
        // 回退到旧版本
        if let url = documentsPath?.appendingPathComponent("jlpt_primary_summary.json") {
            print("尝试从 Documents 加载初级词汇: \(url)")
            if let words = loadWordsFromURL(url, level: "标准日本语初级上册", sourceType: .primary) {
                print("成功从 Documents 加载初级词汇数据: \(words.count) 个单词")
                return words
            }
        }
        return nil
    }
    
    private func loadIntermediateWordsFromBundle() -> [AppVocabularyWord]? {
        if let url = Bundle.main.url(forResource: "jlpt_intermediate_summary", withExtension: "json") {
            print("找到 Bundle 中的中级词汇文件: \(url)")
            if let words = loadWordsFromURL(url, level: "大家的日本语", sourceType: .intermediate) {
                print("成功从 Bundle 加载中级词汇数据: \(words.count) 个单词")
                return words
            }
        }
        return nil
    }
    
    private func loadIntermediateWordsFromDocuments() -> [AppVocabularyWord]? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let url = documentsPath?.appendingPathComponent("jlpt_intermediate_summary.json") {
            print("尝试从 Documents 加载中级词汇: \(url)")
            if let words = loadWordsFromURL(url, level: "大家的日本语", sourceType: .intermediate) {
                print("成功从 Documents 加载中级词汇数据: \(words.count) 个单词")
                return words
            }
        }
        return nil
    }
    
    // 辅助方法：从URL加载词汇数据
    // level 参数：
    //  - 对于 primary：表示教材级别名称（标准日本语初级上册）
    //  - 对于 intermediate：表示教材名称（大家的日本语），同时会额外生成 N3 / N2 级别数据
    private func loadWordsFromURL(_ url: URL, level: String, sourceType: DataSourceType) -> [AppVocabularyWord]? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let jlptData = try decoder.decode(JLPTData.self, from: data)
            
            switch sourceType {
            case .primary:
                let primaryWords = jlptData.primary1 ?? []
                print("解码成功, primary1 数量: \(primaryWords.count)")
                
                guard !primaryWords.isEmpty else {
                    print("primary1 数据为空")
                    return nil
                }
                
                return primaryWords.map { item in
                    AppVocabularyWord(from: item, level: level)
                }
                
            case .intermediate:
                let words1 = jlptData.intermediate1 ?? []
                let words2 = jlptData.intermediate2 ?? []
                print("解码成功, intermediate1 数量: \(words1.count), intermediate2 数量: \(words2.count)")
                
                guard !words1.isEmpty || !words2.isEmpty else {
                    print("intermediate 数据为空")
                    return nil
                }
                
                var result: [AppVocabularyWord] = []
                
                // 1) 大家的日本语：包含中级① + 中级② 全部单词
                result.append(contentsOf: words1.map { AppVocabularyWord(from: $0, level: level) })
                result.append(contentsOf: words2.map { AppVocabularyWord(from: $0, level: level) })
                
                // 2) N3：使用 intermediate1（中级①）的全部单词
                result.append(contentsOf: words1.map { AppVocabularyWord(from: $0, level: "N3") })
                
                // 3) N2：使用 intermediate2（中级②）的全部单词
                result.append(contentsOf: words2.map { AppVocabularyWord(from: $0, level: "N2") })
                
                print("生成 大家的日本语/N3/N2 共 \(result.count) 个词条")
                return result
            }
        } catch {
            print("加载词汇数据失败: \(error)")
            return nil
        }
    }
    
    private func loadSampleData() {
        // 示例数据作为备用
        let sampleWords = [
            ("ありがとう", "arigatou", "谢谢", "感叹词", "第1课", "ありがとうございます。", "Thank you very much."),
            ("おはよう", "ohayou", "早上好", "感叹词", "第1课", "おはようございます。", "Good morning."),
            ("こんにちは", "konnichiwa", "你好", "感叹词", "第1课", "こんにちは、元気ですか。", "Hello, how are you?"),
            ("さようなら", "sayounara", "再见", "感叹词", "第1课", "さようなら、また明日。", "Goodbye, see you tomorrow."),
            ("はい", "hai", "是", "感叹词", "第1课", "はい、そうです。", "Yes, that's right."),
            ("いいえ", "iie", "不是", "感叹词", "第1课", "いいえ、違います。", "No, that's wrong."),
            ("お願いします", "onegaishimasu", "拜托了", "感叹词", "第1课", "これを買ってください、お願いします。", "Please buy this for me."),
            ("すみません", "sumimasen", "对不起", "感叹词", "第1课", "すみません、遅れました。", "I'm sorry, I'm late."),
            ("どうぞ", "douzo", "请", "感叹词", "第1课", "どうぞ、おかけください。", "Please, have a seat."),
            ("失礼します", "shitsureishimasu", "失礼了", "感叹词", "第1课", "失礼します、先に帰ります。", "Excuse me, I'll leave first.")
        ]
        
        allWords = sampleWords.map { word, reading, meaning, pos, lesson, jpEx, enEx in
            // 创建临时的VocabularyItem来使用AppVocabularyWord的初始化器
            let tempItem = VocabularyItem(
                word: word,
                reading: reading,
                meaning: meaning,
                partOfSpeech: pos,
                lesson: lesson,
                sheet: "",
                japaneseExamples: nil,
                chineseExamples: nil,
                englishExamples: nil
            )
            return AppVocabularyWord(from: tempItem, level: "标准日本语初级上册")
        }
        
        print("加载示例数据: \(allWords.count) 个单词")
    }
    
    // 按级别筛选词汇
    func getWordsByLevel(_ level: String) -> [AppVocabularyWord] {
        return allWords.filter { $0.level == level }
    }
    
    // 按课程筛选词汇
    func getWordsByLesson(_ lesson: String) -> [AppVocabularyWord] {
        return allWords.filter { $0.lesson == lesson }
    }
    
    // 搜索词汇
    func searchWords(_ query: String) -> [AppVocabularyWord] {
        if query.isEmpty {
            return allWords
        }
        return allWords.filter { word in
            word.word.localizedCaseInsensitiveContains(query) ||
            word.meaning.localizedCaseInsensitiveContains(query) ||
            word.reading.localizedCaseInsensitiveContains(query)
        }
    }
}