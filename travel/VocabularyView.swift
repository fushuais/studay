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
    let chineseExample: String
    let lesson: String  // 课程编号，如 "第1课"
    let level: String   // 级别，如 "大家的日本语", "N3", "N2", "N1"
    
    init(word: String, pronunciation: String, meaning: String, japaneseExample: String, englishExample: String, chineseExample: String, lesson: String, level: String) {
        self.id = UUID()
        self.word = word
        self.pronunciation = pronunciation
        self.meaning = meaning
        self.japaneseExample = japaneseExample
        self.englishExample = englishExample
        self.chineseExample = chineseExample
        self.lesson = lesson
        self.level = level
    }
    
    init(from appWord: AppVocabularyWord) {
        self.id = appWord.id
        self.word = appWord.word
        self.pronunciation = appWord.reading
        self.meaning = appWord.meaning
        self.japaneseExample = appWord.japaneseExample
        self.englishExample = appWord.englishExample
        self.chineseExample = appWord.chineseExample
        self.lesson = appWord.lesson
        self.level = appWord.level
    }
}

// 学习级别
enum VocabularyLevel: String, CaseIterable {
    case primary = "标准日本语初级上册"
    case minnaNoNihongo = "大家的日本语"
    case n3 = "N3"
    case n2 = "N2"
    case n1 = "N1"
    
    var icon: String {
        switch self {
        case .primary: return "graduationcap.fill"
        case .minnaNoNihongo: return "book.fill"
        case .n3: return "star.fill"
        case .n2: return "star.circle.fill"
        case .n1: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .primary: return .green
        case .minnaNoNihongo: return .orange
        case .n3: return .blue
        case .n2: return .purple
        case .n1: return .red
        }
    }
    
    var description: String {
        switch self {
        case .primary: return "基础词汇 第1-24课"
        case .minnaNoNihongo: return "基础词汇 1-50课"
        case .n3: return "中级词汇"
        case .n2: return "中高级词汇"
        case .n1: return "高级词汇"
        }
    }
    
    var requirement: String {
        switch self {
        case .primary: return "开始学习"
        case .minnaNoNihongo: return "初级上册通过率60%"
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
    
    func getPassRate(for level: String, allWords: [AppVocabularyWord]) -> Double {
        let levelWords = allWords.filter { $0.level == level }
        guard !levelWords.isEmpty else { return 0 }
        
        let mastered = levelWords.filter { masteredWords.contains($0.id) }.count
        return Double(mastered) / Double(max(levelWords.count, 1))
    }
    
    func isLevelUnlocked(_ level: VocabularyLevel, allWords: [AppVocabularyWord]) -> Bool {
        // 现在所有级别默认解锁，无需通过率限制
        return true
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
    @StateObject private var dataManager = VocabularyDataManager.shared
    @State private var showResetAlert = false
    
    var allWords: [AppVocabularyWord] {
        dataManager.allWords
    }
    
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
                        
                        Text("分级学习 · 所有级别均可自由学习")
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
    let allWords: [AppVocabularyWord]
    
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
                    Text("\(Int(Double(allWords.filter { progress.masteredWords.contains($0.id) }.count) / Double(max(allWords.count, 1)) * 100))%")
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
    @StateObject private var dataManager = VocabularyDataManager.shared
    
    var lessons: [String] {
        // 对于「标准日本语初级上册」和「大家的日本语」，按实际数据中的 lesson 分课展示
        if level == .primary || level == .minnaNoNihongo {
            let levelWords = dataManager.allWords.filter { $0.level == level.rawValue }
            let lessonSet = Set(levelWords.map { $0.lesson })
            return lessonSet.sorted { lhs, rhs in
                lessonIndex(from: lhs) < lessonIndex(from: rhs)
            }
        }
        // 其他级别（N3/N2/N1）仍然按整级别作为一个单元
        return [level.rawValue]
    }
    
    /// 从类似「第1课」「第10课」的字符串中提取课号，用于排序
    private func lessonIndex(from lesson: String) -> Int {
        let digits = lesson.compactMap { $0.wholeNumberValue }
        if digits.isEmpty { return 0 }
        return Int(digits.map(String.init).joined()) ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if level == .primary || level == .minnaNoNihongo {
                    ForEach(lessons, id: \.self) { lesson in
                        NavigationLink(destination: VocabularyCardView(
                            level: level,
                            lesson: lesson,
                            words: dataManager.allWords.filter { $0.level == level.rawValue && $0.lesson == lesson }
                        )) {
                            LessonRow(lesson: lesson, level: level, progress: progress, dataManager: dataManager)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    NavigationLink(destination: VocabularyCardView(
                        level: level,
                        lesson: level.rawValue,
                        words: dataManager.allWords.filter { $0.level == level.rawValue }
                    )) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(level.rawValue)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("\(dataManager.allWords.filter { $0.level == level.rawValue }.count) 个单词")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                let passRate = progress.getPassRate(for: level.rawValue, allWords: dataManager.allWords)
                                Text("通过率: \(Int(passRate * 100))%")
                                    .font(.caption)
                                    .foregroundColor(passRate >= 0.6 ? .green : .orange)
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
    let level: VocabularyLevel
    @ObservedObject var progress: LearningProgress
    @ObservedObject var dataManager: VocabularyDataManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                let words = dataManager.allWords.filter { $0.level == level.rawValue && $0.lesson == lesson }
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
    let words: [AppVocabularyWord]
    
    @StateObject private var progress = LearningProgress.shared
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var showExample = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if words.isEmpty {
                VStack(spacing: 16) {
                    Text("本课暂无单词")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("请返回上一页选择有单词的课程。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if currentIndex < words.count {
                VStack(spacing: 20) {
                    // 进度条
                    ProgressView(value: Double(currentIndex), total: Double(words.count))
                        .padding(.horizontal)
                    
                    Text("\(currentIndex + 1) / \(words.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 单张卡片（当前单词）
                    CardView(
                        word: words[currentIndex],
                        showExample: showExample,
                        onTap: {
                            withAnimation {
                                showExample.toggle()
                            }
                        }
                    )
                    .offset(x: offset.width)
                    .rotationEffect(.degrees(Double(offset.width) / 20))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { _ in
                                withAnimation {
                                    if abs(offset.width) > 100 {
                                        offset.width > 0 ? swipeRight() : swipeLeft()
                                    } else {
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    
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
    let word: AppVocabularyWord
    let showExample: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 单词
            VStack(spacing: 12) {
                Text(word.word)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(word.reading)
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
                            Text("中文翻译")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(word.chineseExample)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "textformat.abc")
                                .foregroundColor(.blue)
                            Text("英文翻译")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text(word.englishExample)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
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
        .frame(height: 580)
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
        Double(masteredCount) / Double(max(totalWords, 1))
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



#Preview {
    VocabularyView()
}
