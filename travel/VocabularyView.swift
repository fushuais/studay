//
//  VocabularyView.swift
//  travel
//
//  Created by fushuai on 2026/2/23.
//

import SwiftUI

// MARK: - 数据模型

struct VocabularyWord: Identifiable, Codable {
    let id: UUID
    let word: String
    let pronunciation: String
    let meaning: String
    let japaneseExample: String
    let englishExample: String
    let lesson: String  // 课程编号，如 "第1课"
    let level: String   // 级别，如 "大家的日本语", "N3", "N2", "N1"
    
    init(word: String, pronunciation: String, meaning: String, japaneseExample: String, englishExample: String, lesson: String, level: String) {
        self.id = UUID()
        self.word = word
        self.pronunciation = pronunciation
        self.meaning = meaning
        self.japaneseExample = japaneseExample
        self.englishExample = englishExample
        self.lesson = lesson
        self.level = level
    }
}

// 学习级别
enum VocabularyLevel: String, CaseIterable {
    case minnaNoNihongo = "大家的日本语"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    
    var icon: String {
        switch self {
        case .minnaNoNihongo: return "book.fill"
        case .n3: return "star.fill"
        case .n2: return "star.circle.fill"
        case .n1: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .minnaNoNihongo: return .orange
        case .n3: return .blue
        case .n2: return .purple
        case .n1: return .red
        }
    }
    
    var description: String {
        switch self {
        case .minnaNoNihongo: return "基础词汇 1-50课"
        case .n3: return "中级词汇"
        case .n2: return "中高级词汇"
        case .n1: return "高级词汇"
        }
    }
    
    var requirement: String {
        switch self {
        case .minnaNoNihongo: return "开始学习"
        case .n3: return "大家的日本语通过率60%"
        case .n2: return "N3通过率60%"
        case .n1: return "N2通过率60%"
        }
    }
}

// 学习进度管理
class LearningProgress: ObservableObject {
    static let shared = LearningProgress()
    
    @Published var masteredWords: Set<UUID> = []  // 已掌握的单词ID
    @Published var totalAttempts: [UUID: Int] = [:]  // 每个单词的学习次数
    
    private let masteredKey = "vocabulary_mastered_words"
    private let attemptsKey = "vocabulary_total_attempts"
    
    init() {
        loadData()
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: masteredKey),
           let decoded = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            masteredWords = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: attemptsKey),
           let decoded = try? JSONDecoder().decode([UUID: Int].self, from: data) {
            totalAttempts = decoded
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(masteredWords) {
            UserDefaults.standard.set(encoded, forKey: masteredKey)
        }
        
        if let encoded = try? JSONEncoder().encode(totalAttempts) {
            UserDefaults.standard.set(encoded, forKey: attemptsKey)
        }
    }
    
    func markAsMastered(_ wordId: UUID) {
        masteredWords.insert(wordId)
        totalAttempts[wordId, default: 0] += 1
        saveData()
    }
    
    func markAsUnknown(_ wordId: UUID) {
        totalAttempts[wordId, default: 0] += 1
        saveData()
    }
    
    func getPassRate(for level: String, allWords: [VocabularyWord]) -> Double {
        let levelWords = allWords.filter { $0.level == level }
        guard !levelWords.isEmpty else { return 0 }
        
        let mastered = levelWords.filter { masteredWords.contains($0.id) }.count
        return Double(mastered) / Double(levelWords.count)
    }
    
    func isLevelUnlocked(_ level: VocabularyLevel, allWords: [VocabularyWord]) -> Bool {
        switch level {
        case .minnaNoNihongo:
            return true
        case .n3:
            return getPassRate(for: "大家的日本语", allWords: allWords) >= 0.6
        case .n2:
            return getPassRate(for: "N3", allWords: allWords) >= 0.6
        case .n1:
            return getPassRate(for: "N2", allWords: allWords) >= 0.6
        }
    }
    
    func reset() {
        masteredWords.removeAll()
        totalAttempts.removeAll()
        saveData()
    }
}

// MARK: - 词汇主页

struct VocabularyView: View {
    @StateObject private var progress = LearningProgress.shared
    @State private var showResetAlert = false
    
    let allWords = VocabularyData.allWords
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 标题区域
                    VStack(spacing: 12) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("词汇学习")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("分级学习 · 通过率60%解锁下一级")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    
                    // 学习进度总览
                    ProgressOverviewCard(progress: progress, allWords: allWords)
                        .padding(.horizontal)
                    
                    // 级别选择卡片
                    ForEach(VocabularyLevel.allCases, id: \.self) { level in
                        LevelCard(
                            level: level,
                            isUnlocked: progress.isLevelUnlocked(level, allWords: allWords),
                            passRate: progress.getPassRate(for: level.rawValue, allWords: allWords),
                            totalWords: allWords.filter { $0.level == level.rawValue }.count,
                            masteredWords: allWords.filter { $0.level == level.rawValue && progress.masteredWords.contains($0.id) }.count
                        )
                    }
                    .padding(.horizontal)
                    
                    // 重置按钮
                    Button(action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置学习进度")
                        }
                        .font(.subheadline)
                        .foregroundColor(.red)
                    }
                    .padding(.top, 20)
                    .alert("确认重置", isPresented: $showResetAlert) {
                        Button("取消", role: .cancel) { }
                        Button("重置", role: .destructive) {
                            progress.reset()
                        }
                    } message: {
                        Text("这将清除所有学习进度，确定要继续吗？")
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("词汇学习")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 学习进度总览卡片
struct ProgressOverviewCard: View {
    @ObservedObject var progress: LearningProgress
    let allWords: [VocabularyWord]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学习进度")
                        .font(.headline)
                    Text("已掌握 \(allWords.filter { progress.masteredWords.contains($0.id) }.count) / \(allWords.count) 个单词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(Double(allWords.filter { progress.masteredWords.contains($0.id) }.count) / Double(allWords.count) * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("总体通过率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: Double(allWords.filter { progress.masteredWords.contains($0.id) }.count), total: Double(allWords.count))
                .accentColor(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// 级别选择卡片
struct LevelCard: View {
    let level: VocabularyLevel
    let isUnlocked: Bool
    let passRate: Double
    let totalWords: Int
    let masteredWords: Int
    
    @State private var showDetail = false
    
    var body: some View {
        NavigationLink(destination: LessonSelectionView(level: level, isUnlocked: isUnlocked)) {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    Circle()
                        .fill(isUnlocked ? level.color : Color.gray)
                        .frame(width: 60, height: 60)
                    
                    if isUnlocked {
                        Image(systemName: level.icon)
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                
                // 内容
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(level.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(isUnlocked ? .primary : .gray)
                        
                        if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Text(level.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isUnlocked {
                        HStack(spacing: 12) {
                            Text("\(masteredWords)/\(totalWords) 词")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\(Int(passRate * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(passRate >= 0.6 ? .green : .orange)
                        }
                    } else {
                        Text(level.requirement)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if isUnlocked {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - 课程选择视图

struct LessonSelectionView: View {
    let level: VocabularyLevel
    let isUnlocked: Bool
    
    @StateObject private var progress = LearningProgress.shared
    
    var lessons: [String] {
        if level == .minnaNoNihongo {
            return (1...50).map { "第\($0)课" }
        } else {
            return [level.rawValue]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if level == .minnaNoNihongo {
                    ForEach(lessons, id: \.self) { lesson in
                        NavigationLink(destination: VocabularyCardView(
                            level: level,
                            lesson: lesson,
                            words: VocabularyData.allWords.filter { $0.lesson == lesson }
                        )) {
                            LessonRow(lesson: lesson, progress: progress)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    NavigationLink(destination: VocabularyCardView(
                        level: level,
                        lesson: level.rawValue,
                        words: VocabularyData.allWords.filter { $0.level == level.rawValue }
                    )) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(level.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("\(VocabularyData.allWords.filter { $0.level == level.rawValue }.count) 个单词")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("通过率: \(Int(progress.getPassRate(for: level.rawValue, allWords: VocabularyData.allWords) * 100))%")
                                    .font(.caption)
                                    .foregroundColor(progress.getPassRate(for: level.rawValue, allWords: VocabularyData.allWords) >= 0.6 ? .green : .orange)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(level.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LessonRow: View {
    let lesson: String
    @ObservedObject var progress: LearningProgress
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let words = VocabularyData.allWords.filter { $0.lesson == lesson }
                let mastered = words.filter { progress.masteredWords.contains($0.id) }.count
                let rate = words.isEmpty ? 0 : Double(mastered) / Double(words.count)
                
                HStack(spacing: 12) {
                    Text("\(mastered)/\(words.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(rate * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(rate >= 0.6 ? .green : .orange)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 词汇卡片视图（Tinder风格）

struct VocabularyCardView: View {
    let level: VocabularyLevel
    let lesson: String
    let words: [VocabularyWord]
    
    @StateObject private var progress = LearningProgress.shared
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var showExample = false
    
    var remainingWords: [VocabularyWord] {
        Array(words[currentIndex...])
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if currentIndex < words.count {
                VStack(spacing: 20) {
                    // 进度条
                    ProgressView(value: Double(currentIndex), total: Double(words.count))
                        .padding(.horizontal)
                    
                    Text("\(currentIndex + 1) / \(words.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 卡片堆叠
                    ZStack {
                        ForEach(Array(remainingWords.enumerated()), id: \.element.id) { index, word in
                            CardView(
                                word: word,
                                showExample: showExample && index == 0,
                                onTap: {
                                    withAnimation {
                                        showExample.toggle()
                                    }
                                }
                            )
                            .offset(x: index == 0 ? offset.width : 0)
                            .rotationEffect(.degrees(Double(offset.width) / 20))
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if index == 0 {
                                            offset = gesture.translation
                                        }
                                    }
                                    .onEnded { gesture in
                                        if index == 0 {
                                            withAnimation {
                                                if abs(offset.width) > 100 {
                                                    offset.width > 0 ? swipeRight() : swipeLeft()
                                                } else {
                                                    offset = .zero
                                                }
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    .frame(height: 500)
                    
                    // 操作按钮
                    HStack(spacing: 80) {
                        Button(action: {
                            withAnimation {
                                swipeLeft()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.red)
                                Text("不认识")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button(action: {
                            withAnimation {
                                swipeRight()
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.green)
                                Text("已掌握")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .navigationTitle(lesson)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // 完成页面
                CompletionView(
                    totalWords: words.count,
                    masteredCount: words.filter { progress.masteredWords.contains($0.id) }.count,
                    onRestart: {
                        withAnimation {
                            currentIndex = 0
                            offset = .zero
                        }
                    }
                )
            }
        }
    }
    
    func swipeLeft() {
        if currentIndex < words.count {
            progress.markAsUnknown(words[currentIndex].id)
        }
        offset = CGSize(width: -500, height: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
            showExample = false
        }
    }
    
    func swipeRight() {
        if currentIndex < words.count {
            progress.markAsMastered(words[currentIndex].id)
        }
        offset = CGSize(width: 500, height: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentIndex += 1
            offset = .zero
            showExample = false
        }
    }
}

// MARK: - 单词卡片

struct CardView: View {
    let word: VocabularyWord
    let showExample: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 单词
            VStack(spacing: 12) {
                Text(word.word)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(word.pronunciation)
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text(word.meaning)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 40)
            
            // 例句
            if showExample {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "character.book.closed")
                                .foregroundColor(.orange)
                            Text("日语例句")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(word.japaneseExample)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "a.circle")
                                .foregroundColor(.green)
                            Text("英文例句")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(word.englishExample)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .transition(.opacity)
            }
            
            Spacer()
            
            // 提示
            Text(showExample ? "点击收起例句" : "点击查看例句")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .padding(.horizontal)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 完成页面

struct CompletionView: View {
    let totalWords: Int
    let masteredCount: Int
    let onRestart: () -> Void
    
    var passRate: Double {
        Double(masteredCount) / Double(totalWords)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: passRate >= 0.6 ? "party.popper.fill" : "flag.fill")
                .font(.system(size: 80))
                .foregroundColor(passRate >= 0.6 ? .green : .orange)
            
            Text(passRate >= 0.6 ? "太棒了！" : "继续加油！")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                Text("已掌握 \(masteredCount) / \(totalWords) 个单词")
                    .font(.headline)
                
                Text("通过率: \(Int(passRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(passRate >= 0.6 ? .green : .orange)
                
                if passRate >= 0.6 {
                    Text("🎉 已达到解锁下一级别的标准！")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("继续学习，达到60%通过率解锁下一级")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: onRestart) {
                Text("再来一次")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

// MARK: - 词汇数据

struct VocabularyData {
    static let allWords: [VocabularyWord] = {
        var words: [VocabularyWord] = []
        
        // 大家的日本语 1-50课示例词汇
        let minnaWords = [
            // 第1课
            ("私", "わたし", "我", "私は学生です。", "I am a student.", "第1课"),
            ("あなた", "あなた", "你", "あなたは日本人ですか。", "Are you Japanese?", "第1课"),
            ("日本人", "にほんじん", "日本人", "彼は日本人です。", "He is Japanese.", "第1课"),
            
            // 第2课
            ("本", "ほん", "书", "これは私の本です。", "This is my book.", "第2课"),
            ("雑誌", "ざっし", "杂志", "その雑誌は新しいです。", "That magazine is new.", "第2课"),
            ("新聞", "しんぶん", "报纸", "新聞を読みます。", "I read the newspaper.", "第2课"),
            
            // 第3课
            ("ここ", "ここ", "这里", "ここは学校です。", "Here is the school.", "第3课"),
            ("そこ", "そこ", "那里", "そこに本があります。", "There is a book over there.", "第3课"),
            ("あそこ", "あそこ", "那边", "あそこは駅です。", "That is the station over there.", "第3课"),
            
            // 第4课
            ("今", "いま", "现在", "今、何時ですか。", "What time is it now?", "第4课"),
            ("時間", "じかん", "时间", "時間がありません。", "I don't have time.", "第4课"),
            ("分", "ふん", "分钟", "あと5分です。", "It's 5 more minutes.", "第4课"),
            
            // 第5课
            ("行きます", "いきます", "去", "学校へ行きます。", "I go to school.", "第5课"),
            ("来ます", "きます", "来", "友達が来ます。", "A friend is coming.", "第5课"),
            ("帰ります", "かえります", "回去", "家に帰ります。", "I go home.", "第5课"),
            
            // 添加更多课程的词汇...
            // 第6-50课的词汇
            ("食べます", "たべます", "吃", "寿司を食べます。", "I eat sushi.", "第6课"),
            ("飲みます", "のみます", "喝", "お茶を飲みます。", "I drink tea.", "第6课"),
            
            ("買います", "かいます", "买", "本を買います。", "I buy a book.", "第7课"),
            ("売ります", "うります", "卖", "店は果物を売ります。", "The store sells fruit.", "第7课"),
            
            ("暑い", "あつい", "热", "今日は暑いです。", "Today is hot.", "第8课"),
            ("寒い", "さむい", "冷", "冬は寒いです。", "Winter is cold.", "第8课"),
            
            ("大きい", "おおきい", "大", "この部屋は大きいです。", "This room is big.", "第9课"),
            ("小さい", "ちいさい", "小", "小さい箱です。", "It's a small box.", "第9课"),
            
            ("新しい", "あたらしい", "新", "新しい車を買いました。", "I bought a new car.", "第10课"),
            ("古い", "ふるい", "旧", "この建物は古いです。", "This building is old.", "第10课"),
        ]
        
        for (word, pron, meaning, jpEx, enEx, lesson) in minnaWords {
            words.append(VocabularyWord(
                word: word,
                pronunciation: pron,
                meaning: meaning,
                japaneseExample: jpEx,
                englishExample: enEx,
                lesson: lesson,
                level: "大家的日本语"
            ))
        }
        
        // N3 词汇
        let n3Words = [
            ("影響", "えいきょう", "影响", "この本は私に大きな影響を与えました。", "This book had a big influence on me.", "N3"),
            ("経験", "けいけん", "经验", "日本で働く経験があります。", "I have experience working in Japan.", "N3"),
            ("機会", "きかい", "机会", "また会う機会があればいいですね。", "I hope we have a chance to meet again.", "N3"),
            ("環境", "かんきょう", "环境", "地球環境を守りましょう。", "Let's protect the global environment.", "N3"),
            ("関係", "かんけい", "关系", "二人の関係は良好です。", "Their relationship is good.", "N3"),
        ]
        
        for (word, pron, meaning, jpEx, enEx, level) in n3Words {
            words.append(VocabularyWord(
                word: word,
                pronunciation: pron,
                meaning: meaning,
                japaneseExample: jpEx,
                englishExample: enEx,
                lesson: level,
                level: "N3"
            ))
        }
        
        // N2 词汇
        let n2Words = [
            ("概念", "がいねん", "概念", "この概念は理解しにくいです。", "This concept is difficult to understand.", "N2"),
            ("傾向", "けいこう", "倾向", "最近、早婚化の傾向がある。", "Recently, there is a tendency to marry early.", "N2"),
            ("効果", "こうか", "效果", "薬の効果が現れました。", "The medicine took effect.", "N2"),
            ("特色", "とくしょく", "特色", "この町の特色は何ですか。", "What is the specialty of this town?", "N2"),
            ("性質", "せいしつ", "性质", "彼の性質は優しいです。", "His nature is gentle.", "N2"),
        ]
        
        for (word, pron, meaning, jpEx, enEx, level) in n2Words {
            words.append(VocabularyWord(
                word: word,
                pronunciation: pron,
                meaning: meaning,
                japaneseExample: jpEx,
                englishExample: enEx,
                lesson: level,
                level: "N2"
            ))
        }
        
        // N1 词汇
        let n1Words = [
            ("概念", "がいねん", "概念", "抽象的な概念を説明する。", "To explain abstract concepts.", "N1"),
            ("本質", "ほんしつ", "本质", "問題の本質を見極める。", "To grasp the essence of the problem.", "N1"),
            ("虚栄", "きょえい", "虚荣", "虚栄心を満たす。", "To satisfy vanity.", "N1"),
            ("憧憬", "どうけい", "憧憬", "未来への憧れを抱く。", "To have aspirations for the future.", "N1"),
            ("象徴", "しょうちょう", "象征", "桜は日本の象徴です。", "Cherry blossoms are a symbol of Japan.", "N1"),
        ]
        
        for (word, pron, meaning, jpEx, enEx, level) in n1Words {
            words.append(VocabularyWord(
                word: word,
                pronunciation: pron,
                meaning: meaning,
                japaneseExample: jpEx,
                englishExample: enEx,
                lesson: level,
                level: "N1"
            ))
        }
        
        return words
    }()
}

#Preview {
    VocabularyView()
}
