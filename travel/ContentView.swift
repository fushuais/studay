//
//  ContentView.swift
//  travel
//
//  Created by fushuai on 2026/2/23.
//

import SwiftUI
import Foundation
import AVFoundation

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ListeningView()
                .tabItem {
                    Label("听力", systemImage: "headphones")
                }
                .tag(0)

            VocabularyView()
                .tabItem {
                    Label("词汇", systemImage: "text.book.closed.fill")
                }
                .tag(1)

            LearningView()
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(2)

            NewsReadingView()
                .tabItem {
                    Label("阅读", systemImage: "newspaper.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
    }
}

struct ListeningView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("听力训练中心")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("按语言进入模块化听力训练，覆盖词句听辨、对话理解和复述。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    NavigationLink {
                        JapaneseListeningModuleView()
                    } label: {
                        LanguageModuleCard(
                            title: "日语",
                            subtitle: "N5-N2 听解训练与真题节奏",
                            icon: "character.book.closed.fill",
                            accent: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        FrenchListeningModuleView()
                    } label: {
                        LanguageModuleCard(
                            title: "法语",
                            subtitle: "发音分辨与生活场景听力",
                            icon: "waveform.badge.mic",
                            accent: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EnglishListeningModuleView()
                    } label: {
                        LanguageModuleCard(
                            title: "英语",
                            subtitle: "日常交流与职场听力理解",
                            icon: "waveform",
                            accent: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("听力")
        }
    }
}

struct JapaneseListeningModuleView: View {
    @State private var selectedMode: JapaneseListeningMode = .sentences
    @State private var selectedSentenceLevel = "N4"
    @State private var selectedEJUCategory: EJUListeningCategory = .all
    @State private var currentSentenceIndex = 0
    @State private var currentNewsIndex = 0
    @State private var currentEJUIndex = 0
    @State private var currentConversationIndex = 0
    @State private var selectedChoice = ""
    @State private var resultText = ""
    @State private var revealAnswer = false
    @State private var completedEJUQuestionIDs: Set<String> = []
    @StateObject private var speaker = JapaneseListeningSpeaker()

    private let sentenceLevels = ["N5", "N4", "N3", "N2"]

    private var minnaConversationData: MinnaConversationData? {
        MinnaConversationStore.shared.data
    }

    private var conversationLessons: [MinnaConversationLesson] {
        minnaConversationData?.lessons ?? []
    }

    private var currentConversation: MinnaConversationLesson? {
        guard !conversationLessons.isEmpty else { return nil }
        let idx = max(0, min(currentConversationIndex, conversationLessons.count - 1))
        return conversationLessons[idx]
    }

    private var openData: JapaneseListeningOpenData? {
        JapaneseListeningOpenStore.shared.data
    }

    private var sentenceItems: [JapaneseSentenceListeningItem] {
        guard let openData else { return [] }
        return openData.sentenceLevels[selectedSentenceLevel] ?? []
    }

    private var currentSentence: JapaneseSentenceListeningItem? {
        guard !sentenceItems.isEmpty else { return nil }
        let idx = max(0, min(currentSentenceIndex, sentenceItems.count - 1))
        return sentenceItems[idx]
    }

    private var newsItems: [JapaneseNHKNewsItem] {
        openData?.nhkNews ?? []
    }

    private var currentNews: JapaneseNHKNewsItem? {
        guard !newsItems.isEmpty else { return nil }
        let idx = max(0, min(currentNewsIndex, newsItems.count - 1))
        return newsItems[idx]
    }

    private var ejuQuestions: [EJUListeningQuestion] {
        EJUListeningQuestionStore.shared.questions
    }

    private var ejuOpenData: EJUOpenListeningData? {
        EJUOpenListeningStore.shared.data
    }

    private var ejuOpenTracks: [EJUOpenListeningTrack] {
        guard let ejuOpenData else { return [] }
        return ejuOpenData.papers.flatMap { $0.tracks }
    }

    private var filteredEJUQuestions: [EJUListeningQuestion] {
        guard selectedEJUCategory != .all else { return ejuQuestions }
        return ejuQuestions.filter { $0.category == selectedEJUCategory }
    }

    private var currentEJUQuestion: EJUListeningQuestion? {
        guard !filteredEJUQuestions.isEmpty else { return nil }
        let idx = max(0, min(currentEJUIndex, filteredEJUQuestions.count - 1))
        return filteredEJUQuestions[idx]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("日语听力训练")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("产品化学习流：分层内容、可操作训练、即时反馈。支持句子、NHK 新闻、EJU 听解与大家的日本语会话。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Picker("模式", selection: $selectedMode) {
                    ForEach(JapaneseListeningMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedMode) {
                    resetPracticeState()
                }

                HStack(spacing: 10) {
                    StatChip(title: "句子数", value: "\(sentenceItems.count)", accent: .orange)
                    StatChip(title: "新闻数", value: "\(newsItems.count)", accent: .blue)
                    StatChip(title: "EJU题数", value: "\(ejuQuestions.count)", accent: .purple)
                    StatChip(title: "真题音频", value: "\(ejuOpenTracks.count)", accent: .indigo)
                    StatChip(title: "会话数", value: "\(conversationLessons.count)", accent: .green)
                }

                if selectedMode == .sentences {
                    Picker("等级", selection: $selectedSentenceLevel) {
                        ForEach(sentenceLevels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedSentenceLevel) {
                        currentSentenceIndex = 0
                    }

                    if let sentence = currentSentence {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "ear.and.waveform")
                                    .foregroundColor(.orange)
                                Text("句子听力")
                                    .font(.headline)
                                Spacer()
                                Text("\(currentSentenceIndex + 1)/\(sentenceItems.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // 音频播放控制
                            HStack(spacing: 10) {
                                Button("播放") {
                                    speakSentence(slow: false)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)

                                Button("慢速") {
                                    speakSentence(slow: true)
                                }
                                .buttonStyle(.bordered)

                                Button("停止") {
                                    speaker.stop()
                                }
                                .buttonStyle(.bordered)
                            }

                            // 文章展示区域
                            VStack(alignment: .leading, spacing: 16) {
                                Text("句子内容")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding(.bottom, 4)

                                Text(sentence.jp)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)

                                Text(sentence.translation)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }

                            // 导航控制
                            HStack(spacing: 10) {
                                Button("上一条") {
                                    guard !sentenceItems.isEmpty else { return }
                                    currentSentenceIndex = max(currentSentenceIndex - 1, 0)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentSentenceIndex == 0)

                                Button("下一条") {
                                    guard !sentenceItems.isEmpty else { return }
                                    currentSentenceIndex = min(currentSentenceIndex + 1, sentenceItems.count - 1)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentSentenceIndex >= sentenceItems.count - 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let source = openData?.meta.sentenceSource {
                        Text("句子来源：\(source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if selectedMode == .news {
                    if let news = currentNews {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "newspaper.fill")
                                    .foregroundColor(.blue)
                                Text("NHK 新闻听力")
                                    .font(.headline)
                                Spacer()
                                Text("\(currentNewsIndex + 1)/\(newsItems.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // 音频播放控制
                            HStack(spacing: 10) {
                                Button("播放标题") {
                                    speakNewsTitle(slow: false)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)

                                Button("慢速") {
                                    speakNewsTitle(slow: true)
                                }
                                .buttonStyle(.bordered)

                                Button("停止") {
                                    speaker.stop()
                                }
                                .buttonStyle(.bordered)
                            }

                            // 文章展示区域
                            VStack(alignment: .leading, spacing: 16) {
                                Text("新闻内容")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .padding(.bottom, 4)

                                Text(news.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)

                                Text(news.summary)
                                    .font(.body)
                                    .foregroundColor(.secondary)

                                if !news.link.isEmpty {
                                    Link("查看原文", destination: URL(string: news.link)!)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }

                            // 导航控制
                            HStack(spacing: 10) {
                                Button("上一条") {
                                    guard !newsItems.isEmpty else { return }
                                    currentNewsIndex = max(currentNewsIndex - 1, 0)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentNewsIndex == 0)

                                Button("下一条") {
                                    guard !newsItems.isEmpty else { return }
                                    currentNewsIndex = min(currentNewsIndex + 1, newsItems.count - 1)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentNewsIndex >= newsItems.count - 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let source = openData?.meta.nhkSource {
                        Text("新闻来源：\(source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if selectedMode == .conversations {
                    if let conversation = currentConversation {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(.green)
                                Text("大家的日本语会话")
                                    .font(.headline)
                                Spacer()
                                Text("\(currentConversationIndex + 1)/\(conversationLessons.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("第\(conversation.lesson_number)课 - \(conversation.title)")
                                .font(.title3)
                                .fontWeight(.bold)

                            // 音频播放控制
                            HStack(spacing: 10) {
                                Button("播放整课") {
                                    speakConversationEntire(slow: false)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)

                                Button("慢速播放") {
                                    speakConversationEntire(slow: true)
                                }
                                .buttonStyle(.bordered)

                                Button("停止") {
                                    speaker.stop()
                                }
                                .buttonStyle(.bordered)

                                if let audioURL = conversation.audio_url {
                                    Button("播放音频文件") {
                                        if let url = URL(string: audioURL) {
                                            speaker.play(url: url)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }

                                if let filename = conversation.audio_filename {
                                    Text(filename)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            // 文章展示区域
                            VStack(alignment: .leading, spacing: 16) {
                                Text("会话内容")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .padding(.bottom, 4)

                                ForEach(Array(conversation.dialogues.enumerated()), id: \.element.id) { index, dialogue in
                                    HStack(alignment: .top, spacing: 12) {
                                        // 发言者头像
                                        Circle()
                                            .fill(dialogue.speaker == "田中" ? Color.blue : Color.orange)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text(String(dialogue.speaker.prefix(1)))
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            )

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(dialogue.speaker)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)

                                            // 日语句子
                                            Text(dialogue.japanese)
                                                .font(.body)
                                                .fontWeight(.medium)

                                            // 中文翻译
                                            Text(dialogue.chinese)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)

                                            // 英文翻译
                                            Text(dialogue.english)
                                                .font(.caption)
                                                .foregroundColor(.secondary.opacity(0.8))
                                        }

                                        Spacer()

                                        // 播放单个对话按钮
                                        Button {
                                            speakConversationDialogue(dialogueIndex: index, slow: false)
                                        } label: {
                                            Image(systemName: "play.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.green)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }

                            // 导航控制
                            HStack(spacing: 10) {
                                Button("上一课") {
                                    guard !conversationLessons.isEmpty else { return }
                                    currentConversationIndex = max(currentConversationIndex - 1, 0)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentConversationIndex == 0)

                                Button("下一课") {
                                    guard !conversationLessons.isEmpty else { return }
                                    currentConversationIndex = min(currentConversationIndex + 1, conversationLessons.count - 1)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentConversationIndex >= conversationLessons.count - 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.green.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let source = minnaConversationData?.meta.source {
                        Text("会话来源：\(source)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("EJU 听解分类")
                                .font(.headline)
                            Spacer()
                            Text("完成 \(completedEJUQuestionIDs.count)/\(ejuQuestions.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EJUListeningCategory.allCases, id: \.self) { category in
                                    Button {
                                        selectedEJUCategory = category
                                        currentEJUIndex = 0
                                        resetPracticeState()
                                    } label: {
                                        Text(category.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(selectedEJUCategory == category ? .white : .primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedEJUCategory == category ? Color.purple : Color.purple.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.purple.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let question = currentEJUQuestion {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "waveform.badge.magnifyingglass")
                                    .foregroundColor(.purple)
                                Text("EJU 听力选择题")
                                    .font(.headline)
                                Spacer()
                                Text("\(currentEJUIndex + 1)/\(filteredEJUQuestions.count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 10) {
                                StatChip(title: "分类", value: question.category.rawValue, accent: .purple)
                                StatChip(title: "难度", value: question.difficulty, accent: .purple)
                            }

                            // 音频播放控制
                            HStack(spacing: 10) {
                                Button("播放题干") {
                                    speakEJUPrompt(slow: false)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.purple)

                                Button("慢速") {
                                    speakEJUPrompt(slow: true)
                                }
                                .buttonStyle(.bordered)

                                Button("停止") {
                                    speaker.stop()
                                }
                                .buttonStyle(.bordered)
                            }

                            // 文章展示区域
                            VStack(alignment: .leading, spacing: 16) {
                                Text("听力内容")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                    .padding(.bottom, 4)

                                Text(question.prompt)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)

                                Text(question.script)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("解析")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.top, 8)

                                Text(question.explanation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // 导航控制
                            HStack(spacing: 10) {
                                Button("上一题") {
                                    guard !filteredEJUQuestions.isEmpty else { return }
                                    currentEJUIndex = max(currentEJUIndex - 1, 0)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentEJUIndex == 0)

                                Button("下一题") {
                                    guard !filteredEJUQuestions.isEmpty else { return }
                                    currentEJUIndex = min(currentEJUIndex + 1, filteredEJUQuestions.count - 1)
                                }
                                .buttonStyle(.bordered)
                                .disabled(currentEJUIndex >= filteredEJUQuestions.count - 1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.purple.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text("EJU 模式定位：先预判问题 -> 听音频 -> 对照文本和解析学习。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let ejuOpenData, !ejuOpenTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.indigo)
                                Text("开源 EJU 真题音频")
                                    .font(.headline)
                                Spacer()
                                Text("\(ejuOpenTracks.count) 条")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("自动抓取自 JASSO 公开样题，建议先听音频再做下方选择题。")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(Array(ejuOpenTracks.prefix(8))) { track in
                                HStack(spacing: 8) {
                                    Button("播放") {
                                        guard let url = URL(string: track.audioURL) else { return }
                                        speaker.play(url: url)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.indigo)

                                    Text(track.title)
                                        .font(.subheadline)
                                        .lineLimit(2)

                                    Spacer()

                                    Text(track.category)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            HStack {
                                Button("停止音频") {
                                    speaker.stop()
                                }
                                .buttonStyle(.bordered)

                                if let page = ejuOpenData.papers.first?.sourcePage,
                                   let link = URL(string: page) {
                                    Link("查看来源", destination: link)
                                        .font(.footnote)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.indigo.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("日语听力")
        .onDisappear {
            speaker.stop()
        }
    }

    private func sentenceOptions(for item: JapaneseSentenceListeningItem) -> [String] {
        guard sentenceItems.count >= 4 else { return [item.translation] }
        let currentIdx = sentenceItems.firstIndex(where: { $0.jp == item.jp && $0.translation == item.translation }) ?? 0
        let offsets = [31, 67, 101]
        var options = [item.translation]
        for offset in offsets {
            let candidate = sentenceItems[(currentIdx + offset) % sentenceItems.count].translation
            if candidate != item.translation && !options.contains(candidate) {
                options.append(candidate)
            }
        }
        if options.count < 4 {
            for candidate in sentenceItems.map(\.translation) where !options.contains(candidate) {
                options.append(candidate)
                if options.count == 4 { break }
            }
        }
        return rotateOptions(options)
    }

    private func newsOptions(for item: JapaneseNHKNewsItem) -> [String] {
        guard newsItems.count >= 4 else { return [item.summary] }
        let currentIdx = newsItems.firstIndex(where: { $0.title == item.title && $0.summary == item.summary }) ?? 0
        let offsets = [1, 3, 5]
        var options = [item.summary]
        for offset in offsets {
            let candidate = newsItems[(currentIdx + offset) % newsItems.count].summary
            if candidate != item.summary && !options.contains(candidate) {
                options.append(candidate)
            }
        }
        if options.count < 4 {
            for candidate in newsItems.map(\.summary) where !options.contains(candidate) {
                options.append(candidate)
                if options.count == 4 { break }
            }
        }
        return rotateOptions(options)
    }

    private func rotateOptions(_ options: [String]) -> [String] {
        guard options.count > 1 else { return options }
        let shift = abs(options[0].hashValue) % options.count
        return Array(options[shift...] + options[..<shift])
    }

    private func speakSentence(slow: Bool) {
        guard let sentence = currentSentence else { return }
        speaker.speak(text: sentence.jp, language: "ja-JP", rate: slow ? 0.35 : 0.5)
    }

    private func speakNewsTitle(slow: Bool) {
        guard let news = currentNews else { return }
        speaker.speak(text: news.title, language: "ja-JP", rate: slow ? 0.35 : 0.5)
    }

    private func speakEJUPrompt(slow: Bool) {
        guard let question = currentEJUQuestion else { return }
        speaker.speak(text: question.script, language: "ja-JP", rate: slow ? 0.35 : 0.5)
    }

    private func speakConversationDialogue(dialogueIndex: Int, slow: Bool) {
        guard let conversation = currentConversation,
              dialogueIndex < conversation.dialogues.count else { return }
        let dialogue = conversation.dialogues[dialogueIndex]
        speaker.speak(text: dialogue.japanese, language: "ja-JP", rate: slow ? 0.35 : 0.5)
    }

    private func speakConversationEntire(slow: Bool) {
        guard let conversation = currentConversation else { return }
        let fullText = conversation.dialogues.map { $0.japanese }.joined(separator: " ")
        speaker.speak(text: fullText, language: "ja-JP", rate: slow ? 0.35 : 0.5)
    }

    private func resetPracticeState() {
        selectedChoice = ""
        resultText = ""
        revealAnswer = false
    }
}

private enum JapaneseListeningMode: String, CaseIterable {
    case sentences = "句子听力"
    case news = "NHK新闻"
    case eju = "EJU听解"
    case conversations = "大家的日本语会话"
}

@MainActor
final class JapaneseListeningSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVPlayer?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: String, rate: Float) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        player?.pause()
        player = nil
    }

    func play(url: URL) {
        stop()
        player = AVPlayer(url: url)
        player?.play()
    }
}

struct FrenchListeningModuleView: View {
    var body: some View {
        List {
            Section("发音分辨") {
                Text("鼻化元音与连诵听辨")
                Text("闭口/开口音对比训练")
            }
            Section("场景听力") {
                Text("问路、点餐、购物对话理解")
                Text("酒店入住与交通广播信息提取")
            }
            Section("提升训练") {
                Text("短对话听写与关键词记录")
                Text("跟读复述（shadowing）")
            }
        }
        .navigationTitle("法语听力")
    }
}

struct EnglishListeningModuleView: View {
    var body: some View {
        List {
            Section("基础听力") {
                Text("连读、弱读、失爆识别")
                Text("数字、日期、价格快速抓取")
            }
            Section("场景理解") {
                Text("机场、酒店、会议常见对话")
                Text("电话沟通与信息确认")
            }
            Section("进阶训练") {
                Text("新闻摘要听力（主旨+细节）")
                Text("听后复述与口头总结")
            }
        }
        .navigationTitle("英语听力")
    }
}

struct LearningView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("语言学习中心")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("按模块系统学习，按等级持续进阶。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.18), Color.yellow.opacity(0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    NavigationLink {
                        JapaneseLearningView()
                    } label: {
                        LanguageModuleCard(
                            title: "日语",
                            subtitle: "JLPT N5-N1 分级训练",
                            icon: "character.book.closed.fill",
                            accent: .orange
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        FrenchLearningView()
                    } label: {
                        LanguageModuleCard(
                            title: "法语",
                            subtitle: "发音、语法、场景表达",
                            icon: "text.book.closed.fill",
                            accent: .blue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EnglishLearningView()
                    } label: {
                        LanguageModuleCard(
                            title: "英语",
                            subtitle: "核心词汇与真实场景沟通",
                            icon: "book.closed.fill",
                            accent: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("学习")
        }
    }
}

struct LanguageModuleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

struct FrenchLearningView: View {
    var body: some View {
        List {
            Section("基础入门") {
                Text("字母与发音规则")
                Text("日常问候与自我介绍")
            }

            Section("核心能力") {
                Text("常用动词变位（现在时）")
                Text("名词阴阳性与冠词")
                Text("旅行场景会话（点餐/问路/购物）")
            }
        }
        .navigationTitle("法语")
    }
}

struct EnglishLearningView: View {
    var body: some View {
        List {
            Section("基础能力") {
                Text("核心词汇 1000")
                Text("基础语法（时态/从句）")
            }

            Section("场景实战") {
                Text("机场与酒店对话")
                Text("餐厅点餐与过敏表达")
                Text("职场沟通（邮件/会议）")
            }
        }
        .navigationTitle("英语")
    }
}

struct JapaneseLearningView: View {
    private let levels: [JLPTLevel] = [
        JLPTLevel(
            title: "N5",
            focus: "入门基础",
            summary: "建立假名、词汇、基础语法框架",
            accent: .orange,
            vocabularyGoal: "800 词",
            kanjiGoal: "120 字",
            estimatedCycle: "8 周",
            grammarTopics: ["助词基础（は/が/を/に）", "ます形与基本时态", "存在句与数量表达"],
            readingTargets: ["短句理解", "通知/菜单识别"],
            listeningTargets: ["慢速问候与购物对话", "数字、日期、时间听辨"],
            speakingTargets: ["自我介绍", "点餐与问路基础句"],
            writingTargets: ["平假名、片假名默写", "短句改写"],
            weeklyPlan: ["周1-2：假名与发音", "周3-5：核心语法+词汇", "周6-8：场景口语+N5套题"],
            releaseChecklist: ["词汇正确率≥85%", "语法题正确率≥80%", "完成2次全真模拟"],
            resources: ["《新完全掌握 N5》", "NHK EASY 入门短句", "Anki N5 词卡包"]
        ),
        JLPTLevel(
            title: "N4",
            focus: "初级提升",
            summary: "采用日本考前对策顺序，先词汇后语法，再读解与听解，最后模考回收",
            accent: .pink,
            vocabularyGoal: "1800 词",
            kanjiGoal: "320 字",
            estimatedCycle: "12 周",
            grammarTopics: [
                "动词活用总整理（ます形/て形/ない形/辞书形）",
                "授受表达（あげる・くれる・もらう）",
                "条件与理由（たら・なら・ので・のに）",
                "许可、禁止、义务（てもいい・てはいけない・なければならない）",
                "考前高频语法对比（そうだ/ようだ、てしまう/ておく）"
            ],
            readingTargets: [
                "短篇读解（公告、邮件、说明文）200-400字",
                "按题型提取信息：目的、理由、条件、时间顺序",
                "限时训练：每篇控制在6-8分钟"
            ],
            listeningTargets: [
                "完成 N4 听解四题型（课题理解/要点理解/发话表达/即时应答）",
                "聚焦数字、时间、地点、人物关系等易错点",
                "每周至少2回真题速度精听+复述"
            ],
            speakingTargets: [
                "2-3分钟主题叙述（计划、经历、比较）",
                "场景角色扮演（车站/医院/学校/打工）",
                "使用理由句与条件句进行完整回答"
            ],
            writingTargets: [
                "每周2篇120-180字短文（邮件/日记/通知）",
                "语法点造句：每个重点语法至少8句",
                "错句改写与敬体统一训练"
            ],
            weeklyPlan: [
                "周1-3：文字词汇与汉字速记（日本塾常用先行阶段）",
                "周4-6：文法体系化+题型练习",
                "周7-9：读解分题型（指示词、因果、主旨）",
                "周10-11：听解专项+口头复述",
                "周12：2套完整模考 + 弱点回收"
            ],
            releaseChecklist: [
                "词汇汉字覆盖率≥92%",
                "文法专项正确率≥85%",
                "读解正确率≥82%，听解正确率≥80%",
                "完成2次完整模考，稳定超过目标线15分"
            ],
            resources: [
                "《日本语总まとめ N4（文字词汇/文法/读解/听解）》",
                "《新完全掌握 N4》",
                "JLPT 官方真题（N4）+ NHK EASY"
            ],
            quizQuestions: [
                JLPTQuizQuestion(
                    id: "n4_q1",
                    prompt: "「もう寝ないと。」最自然的含义是？",
                    options: ["还不用睡", "必须得睡了", "想睡就睡", "睡不着"],
                    correctIndex: 1,
                    explanation: "「〜ないと」是「不...不行」的口语省略表达。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q2",
                    prompt: "「食べちゃった」对应的标准形是？",
                    options: ["食べてしまった", "食べてもいい", "食べられた", "食べておく"],
                    correctIndex: 0,
                    explanation: "「〜ちゃった」常是「〜てしまった」的口语缩略。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q3",
                    prompt: "「早く来るように」在考题中常表示？",
                    options: ["推测", "命令/指示", "愿望", "原因"],
                    correctIndex: 1,
                    explanation: "「〜ように」接续可用于转述命令、指示或要求。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q4",
                    prompt: "「雨なので、行きません。」中「ので」语气特点是？",
                    options: ["更生硬", "更客观委婉", "更强命令", "表示并列"],
                    correctIndex: 1,
                    explanation: "「ので」比「から」更客观、礼貌，常用于说明理由。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q5",
                    prompt: "「〜てもいいです」正确功能是？",
                    options: ["禁止", "义务", "许可", "推测"],
                    correctIndex: 2,
                    explanation: "「〜てもいい」表示“可以……”，用于许可。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q6",
                    prompt: "「ておく」在备考语境中最常见含义是？",
                    options: ["正在进行", "事先准备", "被动受害", "能力变化"],
                    correctIndex: 1,
                    explanation: "「〜ておく」表示为了后续目的而提前做。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q7",
                    prompt: "「駅に着いたら、電話してください。」里的「たら」是？",
                    options: ["并列", "条件/时间先后", "转折", "举例"],
                    correctIndex: 1,
                    explanation: "「〜たら」常用于“……之后/如果……就……”的条件关系。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q8",
                    prompt: "「なければならない」最贴近哪一项？",
                    options: ["可以不做", "必须做", "大概会做", "想做"],
                    correctIndex: 1,
                    explanation: "「〜なければならない」表示义务，意为“必须……”。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q9",
                    prompt: "「日本語が話せるようになった」表示？",
                    options: ["状态保持", "能力变化", "被动结果", "推测判断"],
                    correctIndex: 1,
                    explanation: "「〜ようになる」常表示能力、习惯或状态发生变化。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q10",
                    prompt: "「あげる・くれる・もらう」主要考查哪类关系？",
                    options: ["时间顺序", "授受方向", "条件关系", "对比关系"],
                    correctIndex: 1,
                    explanation: "授受表达核心是“给与接受”的方向与说话人立场。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q11",
                    prompt: "N4 读解做题时最关键的第一步是？",
                    options: ["先看题干与问题", "先全文背诵", "先做听力", "先写答案再找依据"],
                    correctIndex: 0,
                    explanation: "先看题干有助于带着目标找信息，提高限时正确率。"
                ),
                JLPTQuizQuestion(
                    id: "n4_q12",
                    prompt: "N4 模考后最有效的复盘方式是？",
                    options: ["只看总分", "重做全卷不记录", "按错因分类回收", "直接跳到N3"],
                    correctIndex: 2,
                    explanation: "按“词汇/语法/审题/粗心”分类，才能精准修复弱点。"
                )
            ]
        ),
        JLPTLevel(
            title: "N3",
            focus: "中级提升",
            summary: "中级综合练习，强化词汇语法与读听应试能力",
            accent: .purple,
            vocabularyGoal: "3800 词",
            kanjiGoal: "650 字",
            estimatedCycle: "16 周",
            grammarTopics: ["中级核心句型", "逻辑接续", "逆接让步"],
            readingTargets: ["中篇读解", "主旨与依据定位"],
            listeningTargets: ["概要理解", "即时应答", "综合理解"],
            speakingTargets: ["主题表达", "观点展开"],
            writingTargets: ["意见文", "摘要改写"],
            weeklyPlan: ["词汇文法", "读解听解", "模考复盘"],
            releaseChecklist: ["正确率稳定达标"],
            resources: ["《新完全掌握 N3》"],
            quizQuestions: [
                JLPTQuizQuestion(
                    id: "n3_q1",
                    prompt: "「赤ちゃんに泣かれた」最准确的语法说明是？",
                    options: ["普通被动", "使役", "受身（受害/困扰）", "可能态"],
                    correctIndex: 2,
                    explanation: "这里体现“受他人动作影响而困扰”的受身用法。"
                ),
                JLPTQuizQuestion(
                    id: "n3_q2",
                    prompt: "「ご存じのように」在文章中最接近哪种功能？",
                    options: ["举例", "转折", "承接已知信息", "否定强调"],
                    correctIndex: 2,
                    explanation: "表示“正如您所知”，用于承接双方共识信息。"
                ),
                JLPTQuizQuestion(
                    id: "n3_q3",
                    prompt: "「電車に乗ろうとしたときに」表示的时间关系是？",
                    options: ["已经做完后", "正在做时", "正要做时", "重复发生时"],
                    correctIndex: 2,
                    explanation: "「〜ようとしたとき」表示“正要...的时候”。"
                ),
                JLPTQuizQuestion(
                    id: "n3_q4",
                    prompt: "「〜ことになる」在文章里常表示？",
                    options: ["个人瞬间决定", "外在规则/结果导向决定", "纯粹愿望", "完成动作"],
                    correctIndex: 1,
                    explanation: "多表示制度、安排或客观过程导致的结果。"
                )
            ]
        ),
        JLPTLevel(
            title: "N2",
            focus: "中高级表达",
            summary: "达到工作与学术场景可用水平，具备高密度输入输出能力",
            accent: .blue,
            vocabularyGoal: "6000 词",
            kanjiGoal: "1000 字",
            estimatedCycle: "20 周",
            grammarTopics: [
                "高阶语法辨析（に際して、に先立って、ものの、ことなく）",
                "抽象表达与名词句组织",
                "书面语与正式表达（报告、通知、提案）",
                "敬语体系（尊敬语/谦让语）在职场中的稳定应用"
            ],
            readingTargets: [
                "800-1200字评论文、社论、行业材料",
                "快速定位论点、反驳与结论",
                "完成限时长文多任务阅读（摘要+判断）"
            ],
            listeningTargets: [
                "新闻报道、会议纪要、讲座片段",
                "把握省略信息与暗示意图",
                "训练边听边记关键词与逻辑关系"
            ],
            speakingTargets: [
                "6分钟结构化陈述（问题-分析-建议）",
                "模拟面试、汇报、会议讨论",
                "对不同对象切换礼貌层级与措辞"
            ],
            writingTargets: [
                "每周1篇500字议论文 + 1篇商务邮件",
                "摘要、改写、立场对比写作",
                "建立个人高阶表达模板库"
            ],
            weeklyPlan: [
                "周1-8：高阶语法+词汇专题化输入",
                "周9-13：长文精读与听力速记训练",
                "周14-17：商务口语与写作模板训练",
                "周18-20：全真模考4套 + 弱项冲刺"
            ],
            releaseChecklist: [
                "阅读正确率≥82%，听力正确率≥80%",
                "写作评分稳定达到B+以上",
                "完成20次以上高阶话题口语输出",
                "4套模考均达到N2目标分"
            ],
            resources: [
                "《新完全掌握 N2》全套",
                "日本经济新闻/朝日新闻社论栏目",
                "商务日语会话与邮件模板库"
            ]
        ),
        JLPTLevel(
            title: "N1",
            focus: "高级应用",
            summary: "处理高难语篇，进行深度论证与精准表达",
            accent: .indigo,
            vocabularyGoal: "10000+ 词",
            kanjiGoal: "2000 字",
            estimatedCycle: "24 周",
            grammarTopics: ["高级文语与惯用表达", "语义细微差异辨析", "学术型连接与论证结构"],
            readingTargets: ["学术评论与政策文本", "跨段落逻辑推理", "高密度信息整合"],
            listeningTargets: ["讲座、访谈、辩论", "隐含立场识别", "多说话人信息整合"],
            speakingTargets: ["专业议题陈述与答辩", "反驳与追问", "高礼貌正式表达"],
            writingTargets: ["800字以上论述文", "摘要与评论写作", "风格一致性控制"],
            weeklyPlan: ["阶段一：高阶输入", "阶段二：精准输出", "阶段三：冲刺模考与复盘"],
            releaseChecklist: ["全科稳定达标", "高难阅读不过度失分", "口写输出可用于工作/学术场景"],
            resources: ["《新完全掌握 N1》", "学术讲座与评论节目", "历年真题精讲"]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(visibleLevels) { level in
                    NavigationLink {
                        JLPTLevelDetailView(level: level)
                    } label: {
                        JLPTLevelCard(level: level)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("日语")
    }

    private var visibleLevels: [JLPTLevel] {
        levels
    }
}

struct JLPTLevelDetailView: View {
    let level: JLPTLevel
    @State private var refreshToken = UUID()
    @State private var isPreQuizExpanded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if isPracticeOnlyLevel {
                    JLPTQuizSection(
                        title: "\(level.title) 选择题练习",
                        questions: mergedQuizQuestions,
                        accent: level.accent,
                        storageID: level.title
                    ) {
                        refreshToken = UUID()
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(level.focus)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(level.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(level.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    HStack(spacing: 10) {
                        StatChip(title: "词汇", value: level.vocabularyGoal, accent: level.accent)
                        StatChip(title: "汉字", value: level.kanjiGoal, accent: level.accent)
                        StatChip(title: "周期", value: level.estimatedCycle, accent: level.accent)
                    }

                    LearningDashboardCard(
                        accent: level.accent,
                        streakDays: streakDays,
                        todayCount: todayQuestionCount,
                        todayGoal: todayGoal,
                        masteryRate: masteryRate,
                        wrongCount: wrongCount,
                        attempts: attempts
                    )
                    .id(refreshToken)

                    if shouldCollapsePreQuizSection {
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isPreQuizExpanded.toggle()
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.compress.vertical")
                                        .foregroundColor(.orange)
                                    Text("选择题练习前导内容")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(isPreQuizExpanded ? "收起" : "展开")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: isPreQuizExpanded ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            if isPreQuizExpanded {
                                if let examOrder = examPrepOrder {
                                    JLPTDetailCard(title: "日本考前对策顺序", icon: "list.number", accent: .orange, items: examOrder)
                                }
                                if let dailyLoop = dailyLoopPlan {
                                    JLPTDetailCard(title: "每日学习闭环", icon: "arrow.triangle.2.circlepath", accent: .teal, items: dailyLoop)
                                }
                                if let n3Week = n3WeekOneGrammarPlan {
                                    JLPTDetailCard(title: "N3 语法 第1周（日本考前对策）", icon: "calendar.badge.clock", accent: .purple, items: n3Week)
                                }
                                if let n3Usage = n3UsageTips {
                                    JLPTDetailCard(title: "N3 第1周用法提示", icon: "lightbulb.fill", accent: .orange, items: n3Usage)
                                }
                            } else {
                                Text("已折叠，点击展开后查看学习顺序和闭环。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(level.accent.opacity(0.2), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    } else {
                        if let examOrder = examPrepOrder {
                            JLPTDetailCard(title: "日本考前对策顺序", icon: "list.number", accent: .orange, items: examOrder)
                        }

                        if let dailyLoop = dailyLoopPlan {
                            JLPTDetailCard(title: "每日学习闭环", icon: "arrow.triangle.2.circlepath", accent: .teal, items: dailyLoop)
                        }

                        if let n3Week = n3WeekOneGrammarPlan {
                            JLPTDetailCard(title: "N3 语法 第1周（日本考前对策）", icon: "calendar.badge.clock", accent: .purple, items: n3Week)
                        }

                        if let n3Usage = n3UsageTips {
                            JLPTDetailCard(title: "N3 第1周用法提示", icon: "lightbulb.fill", accent: .orange, items: n3Usage)
                        }
                    }

                    if !mergedQuizQuestions.isEmpty {
                        JLPTQuizSection(
                            title: "\(level.title) 选择题练习",
                            questions: mergedQuizQuestions,
                            accent: level.accent,
                            storageID: level.title
                        ) {
                            refreshToken = UUID()
                        }
                    }

                    JLPTDetailCard(title: "语法模块", icon: "text.book.closed.fill", accent: level.accent, items: level.grammarTopics)
                    JLPTDetailCard(title: "阅读目标", icon: "doc.text.fill", accent: level.accent, items: level.readingTargets)
                    JLPTDetailCard(title: "听力目标", icon: "headphones", accent: level.accent, items: level.listeningTargets)
                    JLPTDetailCard(title: "口语任务", icon: "mic.fill", accent: level.accent, items: level.speakingTargets)
                    JLPTDetailCard(title: "写作任务", icon: "pencil.line", accent: level.accent, items: level.writingTargets)
                    JLPTDetailCard(title: "分周计划", icon: "calendar", accent: level.accent, items: level.weeklyPlan)
                    JLPTDetailCard(title: "发行标准清单", icon: "checkmark.seal.fill", accent: .green, items: level.releaseChecklist)
                    JLPTDetailCard(title: "推荐资源", icon: "books.vertical.fill", accent: .blue, items: level.resources)
                }
            }
            .padding()
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .navigationTitle(level.title)
        .onAppear {
            if shouldCollapsePreQuizSection {
                isPreQuizExpanded = false
            }
        }
    }

    private var attempts: Int {
        UserDefaults.standard.integer(forKey: "jlpt_quiz_attempts_\(level.title)")
    }

    private var streakDays: Int {
        attempts == 0 ? 0 : max(1, UserDefaults.standard.integer(forKey: "jlpt_streak_\(level.title)"))
    }

    private var todayGoal: Int {
        level.title == "N3" ? 24 : 20
    }

    private var todayQuestionCount: Int {
        let key = "jlpt_today_questions_\(level.title)_\(dateStamp())"
        return UserDefaults.standard.integer(forKey: key)
    }

    private var masteryRate: Int {
        let score = UserDefaults.standard.integer(forKey: "jlpt_quiz_last_score_\(level.title)")
        let total = max(UserDefaults.standard.integer(forKey: "jlpt_quiz_last_total_\(level.title)"), 1)
        return Int((Double(score) / Double(total) * 100).rounded())
    }

    private var wrongCount: Int {
        let raw = UserDefaults.standard.string(forKey: "jlpt_quiz_wrong_\(level.title)") ?? ""
        return raw.split(separator: ",").count
    }

    private var shouldCollapsePreQuizSection: Bool {
        level.title == "N4"
    }

    private var isPracticeOnlyLevel: Bool {
        ["N4", "N3"].contains(level.title)
    }

    private func dateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    private var examPrepOrder: [String]? {
        switch level.title {
        case "N4":
            return [
                "第1步 文字词汇：先背高频词与汉字，日测+错词本回收",
                "第2步 文法：按出题频率刷核心句型，完成对比辨析",
                "第3步 读解：先短文后中篇，训练“找根据句”习惯",
                "第4步 听解：题型拆分训练，再上原速听力",
                "第5步 模考：整卷计时，按错因（词汇/语法/审题）回补"
            ]
        case "N3":
            return [
                "第1步 文字词汇：主题词库（社会/生活/工作）优先",
                "第2步 文法：句型分组记忆，做同类题横向对比",
                "第3步 读解：主旨题与信息匹配题并行训练",
                "第4步 听解：先脚本精听，再脱稿复述与跟读",
                "第5步 実戦模試：每周1套，次日只做弱项二刷"
            ]
        default:
            return nil
        }
    }

    private var dailyLoopPlan: [String]? {
        switch level.title {
        case "N4":
            return [
                "30分钟 词汇汉字复习（Anki/错词本）",
                "40分钟 文法讲解+10题应用",
                "30分钟 读解1篇（划出根拠句）",
                "25分钟 听解1套小题（复听+听写）",
                "15分钟 总结当天3个易错点并次日回看"
            ]
        case "N3":
            return [
                "35分钟 高频词汇与汉字复盘",
                "45分钟 文法专题（新学+旧题回刷）",
                "40分钟 读解限时训练（1-2篇）",
                "35分钟 听解真题与shadowing",
                "20分钟 口头复述/短写作输出，巩固当天输入"
            ]
        default:
            return nil
        }
    }

    private var n3WeekOneGrammarPlan: [String]? {
        guard level.title == "N3" else { return nil }
        return [
            "一日目：書かれている（被动状态）/ 赤ちゃんに泣かれた（受被害）/ 早く帰らせてください（使役请求）",
            "二日目：もう寝ないと（不...不行）/ 食べちゃった（てしまう口语）/ 書いとく（ておく口语）",
            "三日目：女みたいだ（比况）/ 春らしい（典型特征）/ 大人っぽい（带有...感觉）",
            "四日目：忘れ物をしないようにしましょう（劝告）/ 聞こえるように話す（目的）/ 使えるようになった（能力变化）",
            "五日目：ご存じのように（如您所知）/ 早く来るように（指示）/ 合格しますように（祈愿）",
            "六日目：やめようと思う（意志）/ 電車に乗ろうとしたときに（正要...时）",
            "七日目：周测复盘（日1-6全部做情境造句+20题混合测验）"
        ]
    }

    private var n3UsageTips: [String]? {
        guard level.title == "N3" else { return nil }
        return [
            "优先掌握“语法功能”：请求/劝告/目的/变化/祈愿，再记形态。",
            "每学完3个语法点，立即做“肯定句-否定句-过去式”三连变形。",
            "口语与书面要区分：食べちゃった、書いとく偏口语；考试写作优先标准形。",
            "每天最少完成6句情境造句：学校、打工、家庭、交通四类场景轮换。",
            "错题标注错因：接续错误 / 意义误判 / 语境不合，第二天先回看错因再刷题。"
        ]
    }

    private var workbookData: BeginnerWorkbookData? {
        BeginnerWorkbookStore.shared.data
    }

    private var intermediateData: IntermediateWorkbookData? {
        IntermediateWorkbookStore.shared.data
    }

    private var mergedQuizQuestions: [JLPTQuizQuestion] {
        if level.title == "N4", let workbookData {
            return level.quizQuestions + workbookGeneratedN4Questions(from: workbookData)
        }
        if level.title == "N3", let intermediateData {
            return level.quizQuestions + workbookGeneratedN3Questions(from: intermediateData)
        }
        return level.quizQuestions
    }

    private var mergedWeekTaskPlans: [StudyWeekPlan]? {
        guard var base = weekTaskPlans else { return nil }
        if level.title == "N4", let workbookData, let extra = workbookDrivenN4Plan(from: workbookData) {
            base.append(extra)
        }
        if level.title == "N3", let intermediateData, let extra = workbookDrivenN3Plan(from: intermediateData) {
            base.append(extra)
        }
        return base
    }

    private func workbookGeneratedN4Questions(from data: BeginnerWorkbookData) -> [JLPTQuizQuestion] {
        let vocab = Array(data.vocabBeginnerUp.prefix(14))
        let grammar = Array((data.grammarBeginnerUp + data.grammarBeginnerDown).prefix(10))
        var generated: [JLPTQuizQuestion] = []

        for (index, item) in vocab.enumerated() {
            let pool = vocab.map(\.meaning).filter { $0 != item.meaning }
            guard pool.count >= 3 else { continue }
            var options = [item.meaning, pool[0], pool[1], pool[2]]
            let correctIndex = index % 4
            options.swapAt(0, correctIndex)
            let lessonLabel = item.lesson.isEmpty ? "教材词汇" : item.lesson
            generated.append(
                JLPTQuizQuestion(
                    id: "n4_wb_vocab_\(index)",
                    prompt: "「\(item.word)（\(item.reading)）」最贴近的中文含义是？",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "\(lessonLabel) · \(item.partOfSpeech)。原义：\(item.meaning)"
                )
            )
        }

        for (index, item) in grammar.enumerated() {
            let pool = grammar.map(\.meaning).filter { $0 != item.meaning }
            guard pool.count >= 3 else { continue }
            var options = [item.meaning, pool[0], pool[1], pool[2]]
            let correctIndex = index % 4
            options.swapAt(0, correctIndex)
            let lessonLabel = item.lesson.isEmpty ? "教材语法" : item.lesson
            generated.append(
                JLPTQuizQuestion(
                    id: "n4_wb_grammar_\(index)",
                    prompt: "语法「\(item.pattern)」在题干中最常见的用法是？",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "\(lessonLabel) · \(item.category)。核心：\(item.meaning)"
                )
            )
        }

        return generated
    }

    private func workbookDrivenN4Plan(from data: BeginnerWorkbookData) -> StudyWeekPlan? {
        let vocab = Array(data.vocabBeginnerUp.prefix(21))
        let grammarUp = Array(data.grammarBeginnerUp.prefix(9))
        let grammarDown = Array(data.grammarBeginnerDown.prefix(9))
        guard !vocab.isEmpty, !grammarUp.isEmpty, !grammarDown.isEmpty else { return nil }

        let day1 = [
            "词汇导入：\(vocab[0].word)、\(vocab[1].word)、\(vocab[2].word)",
            "语法理解：\(grammarUp[0].pattern) / \(grammarUp[1].pattern)",
            "完成教材选择题 20 题（词汇+语法）"
        ]
        let day2 = [
            "词汇复习：\(vocab[3].word)、\(vocab[4].word)、\(vocab[5].word)",
            "语法理解：\(grammarUp[2].pattern) / \(grammarUp[3].pattern)",
            "造句训练 8 句并标注时态"
        ]
        let day3 = [
            "词汇复习：\(vocab[6].word)、\(vocab[7].word)、\(vocab[8].word)",
            "语法理解：\(grammarUp[4].pattern) / \(grammarUp[5].pattern)",
            "完成错题回收 15 题"
        ]
        let day4 = [
            "词汇复习：\(vocab[9].word)、\(vocab[10].word)、\(vocab[11].word)",
            "语法理解：\(grammarDown[0].pattern) / \(grammarDown[1].pattern)",
            "短文定位语法根据句 1 篇"
        ]
        let day5 = [
            "词汇复习：\(vocab[12].word)、\(vocab[13].word)、\(vocab[14].word)",
            "语法理解：\(grammarDown[2].pattern) / \(grammarDown[3].pattern)",
            "听解即时应答 10 题"
        ]
        let day6 = [
            "词汇复习：\(vocab[15].word)、\(vocab[16].word)、\(vocab[17].word)",
            "语法理解：\(grammarDown[4].pattern) / \(grammarDown[5].pattern)",
            "周测：教材专项 30 题"
        ]
        let day7 = [
            "词汇复盘：\(vocab[18].word)、\(vocab[19].word)、\(vocab[20].word)",
            "语法复盘：\(grammarDown[6].pattern) / \(grammarDown[7].pattern) / \(grammarDown[8].pattern)",
            "完成错题重练并总结 3 个薄弱点"
        ]

        return StudyWeekPlan(
            id: "w5",
            title: "第5周 教材专项导入（Excel 清洗版）",
            days: [
                StudyDayPlan(id: "d1", title: "周一", tasks: day1),
                StudyDayPlan(id: "d2", title: "周二", tasks: day2),
                StudyDayPlan(id: "d3", title: "周三", tasks: day3),
                StudyDayPlan(id: "d4", title: "周四", tasks: day4),
                StudyDayPlan(id: "d5", title: "周五", tasks: day5),
                StudyDayPlan(id: "d6", title: "周六", tasks: day6),
                StudyDayPlan(id: "d7", title: "周日", tasks: day7)
            ]
        )
    }

    private func workbookGeneratedN3Questions(from data: IntermediateWorkbookData) -> [JLPTQuizQuestion] {
        let source = Array((data.intermediate1 + data.intermediate2).prefix(24))
        guard source.count >= 8 else { return [] }
        var generated: [JLPTQuizQuestion] = []

        for (index, item) in source.enumerated() {
            let pool = source.map(\.meaning).filter { $0 != item.meaning }
            guard pool.count >= 3 else { continue }
            var options = [item.meaning, pool[0], pool[1], pool[2]]
            let correctIndex = index % 4
            options.swapAt(0, correctIndex)
            let readingText = item.reading.isEmpty ? "" : "（\(item.reading)）"
            generated.append(
                JLPTQuizQuestion(
                    id: "n3_wb_vocab_\(index)",
                    prompt: "中级词汇「\(item.word)\(readingText)」的含义是？",
                    options: options,
                    correctIndex: correctIndex,
                    explanation: "\(item.sheet) \(item.lesson) · \(item.partOfSpeech)。原义：\(item.meaning)"
                )
            )
        }
        return generated
    }

    private func workbookDrivenN3Plan(from data: IntermediateWorkbookData) -> StudyWeekPlan? {
        let source = Array((data.intermediate1 + data.intermediate2).prefix(28))
        guard source.count >= 21 else { return nil }

        func line(_ idx: Int) -> String {
            let item = source[idx]
            let reading = item.reading.isEmpty ? "" : "（\(item.reading)）"
            return "\(item.word)\(reading)：\(item.meaning)"
        }

        return StudyWeekPlan(
            id: "w5",
            title: "第5周 中级教材专项导入（Excel 清洗版）",
            days: [
                StudyDayPlan(id: "d1", title: "周一", tasks: ["词汇导入：\(line(0))", "词汇导入：\(line(1))", "完成中级词汇选择题 25 题"]),
                StudyDayPlan(id: "d2", title: "周二", tasks: ["词汇导入：\(line(2))", "词汇导入：\(line(3))", "词义辨析与造句 8 句"]),
                StudyDayPlan(id: "d3", title: "周三", tasks: ["词汇导入：\(line(4))", "词汇导入：\(line(5))", "错题回收 20 题"]),
                StudyDayPlan(id: "d4", title: "周四", tasks: ["词汇导入：\(line(6))", "词汇导入：\(line(7))", "阅读短文 1 篇并圈出新词"]),
                StudyDayPlan(id: "d5", title: "周五", tasks: ["词汇导入：\(line(8))", "词汇导入：\(line(9))", "听解关键词训练 15 分钟"]),
                StudyDayPlan(id: "d6", title: "周六", tasks: ["词汇导入：\(line(10))", "词汇导入：\(line(11))", "周测：中级词汇 40 题"]),
                StudyDayPlan(id: "d7", title: "周日", tasks: ["复盘词汇：\(line(12)) / \(line(13))", "复盘词汇：\(line(14)) / \(line(15))", "错题重练 + 下周计划"])
            ]
        )
    }

    private var weekTaskPlans: [StudyWeekPlan]? {
        switch level.title {
        case "N4":
            return [
                StudyWeekPlan(
                    id: "w1",
                    title: "第1周 文字词汇先行",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["背诵词汇 40 词并默写 15 词", "汉字 20 字读音+例词", "完成词汇选择题 20 题"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["词汇复习（前1日+新30词）", "汉字 20 字书写训练", "完成错词回收 15 题"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["场景词汇（学校/交通）35词", "长音/促音听辨 15 分钟", "词汇测验 25 题"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["词汇复盘 80 词", "汉字 25 字（音训读区分）", "阅读短文 1 篇并标关键词"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["词汇主题扩展（购物/医院）35词", "完成汉字填空 20 题", "听解小题 10 题"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["周测：词汇汉字综合 60 题", "整理错题本并分类", "回顾薄弱词 30 个"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["轻量复习 30 分钟", "复盘周学习记录", "设定下周语法重点"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w2",
                    title: "第2周 文法基础构建",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["学习动词活用总整理", "语法造句 12 句", "文法题 20 题"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["授受表达辨析（あげる/くれる/もらう）", "情境对话改写 8 题", "错题复练 15 题"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["条件句（たら/なら）专题", "文法选择 20 题", "口头复述 10 分钟"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["理由句（ので/のに）辨析", "句型替换练习 15 题", "短文中定位语法 1 篇"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["义务与许可表达整理", "语法混合题 25 题", "错因标注（接续/意义/语境）"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["周测：文法 50 题限时", "复盘 Top5 高频错点", "二刷错题 20 题"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["复习本周全部语法卡片", "完成 10 句自由造句", "制定下周读解计划"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w3",
                    title: "第3周 读解与听解提分",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["读解短文 2 篇（找根据句）", "听解课题理解 10 题", "错题复盘"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["信息匹配题 12 题", "听解要点理解 10 题", "shadowing 15 分钟"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["主旨题专项 12 题", "即时应答 15 题", "整理高频听力关键词"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["限时阅读 2 篇（每篇 8 分钟）", "听写 10 句", "口头复述 8 分钟"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["读听混合训练 40 分钟", "错题二刷", "总结本周弱项"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["半套模拟（读+听）", "按题型统计正确率", "针对最低题型回补"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["回看错题本", "轻量听力输入 20 分钟", "下周模考安排"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w4",
                    title: "第4周 模考冲刺与回收",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["完整模考 1 套", "记录耗时与错因", "错题回补 20 题"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["薄弱语法专题复练", "读解主旨题 10 题", "听解即时应答 10 题"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["完整模考 1 套", "复盘并更新错题本", "口头讲解 5 个错题"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["错题重练模式 30 题", "复习高频词 60 词", "语法卡片快扫"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["限时读解 3 篇", "听解精听 20 分钟", "总结最后冲刺清单"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["小模考 1 套", "保持手感不过度刷题", "睡前回看错题清单"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["考前轻复习", "整理考试物品", "早睡并维持节奏"])
                    ]
                )
            ]
        case "N3":
            return [
                StudyWeekPlan(
                    id: "w1",
                    title: "第1周 文法周（参考日本考前对策）",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["学习：書かれている/泣かれた/帰らせてください", "每个语法做 3 句变形", "文法选择题 20 题"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["学习：ないと/ちゃった/とく", "口语与书面体转换 12 题", "错题复练 15 题"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["学习：みたいだ/らしい/っぽい", "意义辨析 15 题", "情境造句 8 句"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["学习：ように（目的/劝告）/ようになる", "接续改错 15 题", "短文应用 1 篇"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["学习：ご存じのように/ように（指示）/ように（祈愿）", "敬语语境判断 10 题", "语法综合 20 题"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["学习：ようと思う/ようとしたときに", "时态变化练习 12 题", "周测混合题 30 题"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["复盘周错题", "整理 20 个易混语法", "完成 1 次错题重练"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w2",
                    title: "第2周 词汇+文法并行",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["主题词汇（社会）45词", "文法专题 1 组", "选择题 25 题"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["主题词汇（生活）45词", "文法辨析 15 题", "听写关键词 12 条"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["主题词汇（工作）45词", "句型替换 12 题", "错题复练 20 题"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["汉字复盘 35 字", "语法短测 20 题", "阅读小短文 1 篇"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["词汇总复习 120 词", "语法混合题 30 题", "口头输出 10 分钟"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["词汇文法周测 60 题", "按错因分类", "二刷最低模块"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["轻量复盘", "更新个人错题库", "制定读解计划"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w3",
                    title: "第3周 读解题型突破",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["主旨题 8 题", "信息匹配题 6 题", "记录根据句"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["指示词题 10 题", "推断题 8 题", "复盘错误逻辑"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["限时读解 2 篇", "错题改写 6 题", "词汇回收 30 词"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["中篇读解 2 篇", "段落结构标注", "主张-依据提取训练"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["读解混合 20 题", "错题二刷", "总结个人解题步骤"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["半套读解模拟", "计时与节奏复盘", "回补低正确率题型"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["读解错题回看", "轻量阅读输入", "准备听解周"])
                    ]
                ),
                StudyWeekPlan(
                    id: "w4",
                    title: "第4周 听解+实战模考",
                    days: [
                        StudyDayPlan(id: "d1", title: "周一", tasks: ["概要理解 12 题", "听写 10 句", "shadowing 15 分钟"]),
                        StudyDayPlan(id: "d2", title: "周二", tasks: ["即时应答 20 题", "语气判断专项", "错题复盘"]),
                        StudyDayPlan(id: "d3", title: "周三", tasks: ["综合理解 10 题", "脚本精听 20 分钟", "脱稿复述 8 分钟"]),
                        StudyDayPlan(id: "d4", title: "周四", tasks: ["完整模考 1 套", "统计读听正确率", "弱项回补 30 分钟"]),
                        StudyDayPlan(id: "d5", title: "周五", tasks: ["错题重练 30 题", "高频语法快扫", "词汇冲刺 60 词"]),
                        StudyDayPlan(id: "d6", title: "周六", tasks: ["完整模考 1 套", "考场节奏演练", "整理最终错题清单"]),
                        StudyDayPlan(id: "d7", title: "周日", tasks: ["轻量复习", "复盘四周学习成果", "制定下阶段计划"])
                    ]
                )
            ]
        default:
            return nil
        }
    }
}

struct JLPTLevel: Identifiable {
    let id = UUID()
    let title: String
    let focus: String
    let summary: String
    let accent: Color
    let vocabularyGoal: String
    let kanjiGoal: String
    let estimatedCycle: String
    let grammarTopics: [String]
    let readingTargets: [String]
    let listeningTargets: [String]
    let speakingTargets: [String]
    let writingTargets: [String]
    let weeklyPlan: [String]
    let releaseChecklist: [String]
    let resources: [String]
    var quizQuestions: [JLPTQuizQuestion] = []
}

struct JLPTQuizQuestion: Identifiable {
    let id: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

struct JLPTQuizSection: View {
    let title: String
    let questions: [JLPTQuizQuestion]
    let accent: Color
    let storageID: String
    var onSessionComplete: (() -> Void)? = nil

    @State private var selectedAnswers: [String: Int] = [:]
    @State private var submitted = false
    @State private var mode: QuizMode = .all
    @State private var sessionQuestions: [JLPTQuizQuestion] = []
    @State private var wrongQuestionIDs: Set<String> = []

    private var score: Int {
        activeQuestions.reduce(0) { partial, question in
            partial + ((selectedAnswers[question.id] == question.correctIndex) ? 1 : 0)
        }
    }

    private var activeQuestions: [JLPTQuizQuestion] {
        if mode == .wrongOnly {
            let filtered = questions.filter { wrongQuestionIDs.contains($0.id) }
            return filtered.isEmpty ? sessionQuestions : filtered
        }
        return sessionQuestions
    }

    private var answeredCount: Int {
        activeQuestions.filter { selectedAnswers[$0.id] != nil }.count
    }

    private var canSubmit: Bool {
        !activeQuestions.isEmpty && answeredCount == activeQuestions.count
    }

    private var wrongCount: Int {
        activeQuestions.count - score
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(accent)
                Text(title)
                    .font(.headline)
            }

            Picker("练习模式", selection: $mode) {
                Text("全量练习").tag(QuizMode.all)
                Text("错题重练").tag(QuizMode.wrongOnly)
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) {
                resetSession(reshuffle: false)
            }

            if mode == .wrongOnly && wrongQuestionIDs.isEmpty {
                Text("当前没有错题，先完成一次全量练习。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("进度：\(answeredCount) / \(activeQuestions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("未完成：\(max(activeQuestions.count - answeredCount, 0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ProgressView(value: Double(answeredCount), total: Double(max(activeQuestions.count, 1)))
                    .tint(accent)
            }

            ForEach(Array(activeQuestions.enumerated()), id: \.element.id) { idx, question in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(idx + 1). \(question.prompt)")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(question.options.enumerated()), id: \.offset) { optionIndex, option in
                        Button {
                            selectedAnswers[question.id] = optionIndex
                        } label: {
                            HStack {
                                Image(systemName: selectedAnswers[question.id] == optionIndex ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(selectedAnswers[question.id] == optionIndex ? accent : .secondary)
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedAnswers[question.id] == optionIndex ? accent.opacity(0.12) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAnswers[question.id] == optionIndex ? accent.opacity(0.45) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if submitted {
                        let isCorrect = selectedAnswers[question.id] == question.correctIndex
                        Text(isCorrect ? "回答正确" : "回答错误，正确答案：\(question.options[question.correctIndex])")
                            .font(.caption)
                            .foregroundColor(isCorrect ? .green : .red)
                        Text(question.explanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 10) {
                Button("提交答案") {
                    guard canSubmit else { return }
                    submitted = true
                    let wrongs = activeQuestions
                        .filter { selectedAnswers[$0.id] != $0.correctIndex }
                        .map(\.id)
                    wrongQuestionIDs.formUnion(wrongs)
                    saveWrongQuestionIDs()
                    saveSessionSnapshot()
                    updateStudyStreak()
                    addTodayQuestionCount(by: activeQuestions.count)
                    onSessionComplete?()
                }
                .buttonStyle(.borderedProminent)
                .tint(accent)
                .disabled(!canSubmit)
                .frame(maxWidth: .infinity)

                Button("重做") {
                    resetSession(reshuffle: true)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }

            if submitted {
                Text("得分：\(score) / \(activeQuestions.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(accent)
                Text("正确率：\(accuracyRate)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(resultAdvice)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if wrongCount > 0 {
                    Text("错题数：\(wrongCount)，可切换到“错题重练”继续练习。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            sessionQuestions = questions.shuffled()
            loadWrongQuestionIDs()
        }
    }

    private var resultAdvice: String {
        let total = max(activeQuestions.count, 1)
        let ratio = Double(score) / Double(total)
        if ratio >= 0.9 { return "掌握优秀：当前题组完成度高。" }
        if ratio >= 0.7 { return "掌握良好：当前题组基本达标。" }
        return "需要巩固：当前题组正确率偏低。"
    }

    private var accuracyRate: Int {
        let total = max(activeQuestions.count, 1)
        return Int((Double(score) / Double(total) * 100).rounded())
    }

    private func resetSession(reshuffle: Bool) {
        selectedAnswers.removeAll()
        submitted = false
        if reshuffle {
            sessionQuestions = questions.shuffled()
        }
    }

    private func storageKey() -> String {
        "jlpt_quiz_wrong_\(storageID)"
    }

    private func loadWrongQuestionIDs() {
        let raw = UserDefaults.standard.string(forKey: storageKey()) ?? ""
        let ids = raw.split(separator: ",").map(String.init)
        wrongQuestionIDs = Set(ids)
    }

    private func saveWrongQuestionIDs() {
        let raw = wrongQuestionIDs.joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: storageKey())
    }

    private func saveSessionSnapshot() {
        UserDefaults.standard.set(score, forKey: "jlpt_quiz_last_score_\(storageID)")
        UserDefaults.standard.set(activeQuestions.count, forKey: "jlpt_quiz_last_total_\(storageID)")
        let attemptsKey = "jlpt_quiz_attempts_\(storageID)"
        let attempts = UserDefaults.standard.integer(forKey: attemptsKey)
        UserDefaults.standard.set(attempts + 1, forKey: attemptsKey)
    }

    private func updateStudyStreak() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.string(from: Date())
        let calendar = Calendar.current
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterday = formatter.string(from: yesterdayDate)

        let lastDateKey = "jlpt_last_study_date_\(storageID)"
        let streakKey = "jlpt_streak_\(storageID)"
        let last = UserDefaults.standard.string(forKey: lastDateKey) ?? ""
        var streak = UserDefaults.standard.integer(forKey: streakKey)

        if last == today {
            return
        } else if last == yesterday {
            streak += 1
        } else {
            streak = 1
        }

        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(today, forKey: lastDateKey)
    }

    private func addTodayQuestionCount(by value: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let key = "jlpt_today_questions_\(storageID)_\(formatter.string(from: Date()))"
        let old = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(old + value, forKey: key)
    }
}

enum QuizMode {
    case all
    case wrongOnly
}

struct StudyWeekPlan: Identifiable {
    let id: String
    let title: String
    let days: [StudyDayPlan]
}

struct StudyDayPlan: Identifiable {
    let id: String
    let title: String
    let tasks: [String]
}

struct BeginnerWorkbookData: Codable {
    let meta: BeginnerWorkbookMeta
    let grammarBeginnerUp: [BeginnerGrammarItem]
    let grammarBeginnerDown: [BeginnerGrammarItem]
    let vocabBeginnerUp: [BeginnerVocabItem]
}

struct BeginnerWorkbookMeta: Codable {
    let sourceFile: String
    let generatedAt: String
    let counts: BeginnerWorkbookCounts
}

struct BeginnerWorkbookCounts: Codable {
    let grammarBeginnerUp: Int
    let grammarBeginnerDown: Int
    let vocabBeginnerUp: Int
}

struct BeginnerGrammarItem: Codable {
    let category: String
    let pattern: String
    let meaning: String
    let lesson: String
}

struct BeginnerVocabItem: Codable {
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    let lesson: String
}

struct BeginnerWorkbookStore {
    static let shared = BeginnerWorkbookStore()
    let data: BeginnerWorkbookData?

    private init() {
        guard let url = Bundle.main.url(forResource: "jlpt_beginner_summary", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else {
            data = nil
            return
        }
        data = try? JSONDecoder().decode(BeginnerWorkbookData.self, from: raw)
    }
}

struct IntermediateWorkbookData: Codable {
    let meta: IntermediateWorkbookMeta
    let intermediate1: [IntermediateVocabItem]
    let intermediate2: [IntermediateVocabItem]
}

struct IntermediateWorkbookMeta: Codable {
    let sourceFile: String
    let generatedAt: String
    let counts: IntermediateWorkbookCounts
}

struct IntermediateWorkbookCounts: Codable {
    let intermediate1: Int
    let intermediate2: Int
    let total: Int
}

struct IntermediateVocabItem: Codable {
    let word: String
    let reading: String
    let meaning: String
    let partOfSpeech: String
    let lesson: String
    let sheet: String
}

struct IntermediateWorkbookStore {
    static let shared = IntermediateWorkbookStore()
    let data: IntermediateWorkbookData?

    private init() {
        guard let url = Bundle.main.url(forResource: "jlpt_intermediate_summary", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else {
            data = nil
            return
        }
        data = try? JSONDecoder().decode(IntermediateWorkbookData.self, from: raw)
    }
}

struct JLPTOSSListeningData: Codable {
    let meta: JLPTOSSListeningMeta
    let levels: [String: [JLPTOSSListeningItem]]
}

struct JLPTOSSListeningMeta: Codable {
    let source: String
    let files: [String: String]
    let description: String
}

struct JLPTOSSListeningItem: Codable {
    let word: String
    let reading: String
    let meaning: String
    let pitchAccents: [String]
}

struct JLPTOSSListeningStore {
    static let shared = JLPTOSSListeningStore()
    let data: JLPTOSSListeningData?

    private init() {
        guard let url = Bundle.main.url(forResource: "jlpt_listening_oss", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else {
            data = nil
            return
        }
        data = try? JSONDecoder().decode(JLPTOSSListeningData.self, from: raw)
    }
}

struct JapaneseListeningOpenData: Codable {
    let meta: JapaneseListeningOpenMeta
    let sentenceLevels: [String: [JapaneseSentenceListeningItem]]
    let nhkNews: [JapaneseNHKNewsItem]
}

struct JapaneseListeningOpenMeta: Codable {
    let sentenceSource: String
    let nhkSource: String
    let description: String
}

struct JapaneseSentenceListeningItem: Codable {
    let jp: String
    let translation: String
}

struct JapaneseNHKNewsItem: Codable {
    let title: String
    let summary: String
    let link: String
    let pubDate: String
}

struct JapaneseListeningOpenStore {
    static let shared = JapaneseListeningOpenStore()
    let data: JapaneseListeningOpenData?

    private init() {
        guard let url = Bundle.main.url(forResource: "japanese_listening_open_content", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else {
            data = nil
            return
        }
        data = try? JSONDecoder().decode(JapaneseListeningOpenData.self, from: raw)
    }
}

struct EJUOpenListeningData: Codable {
    let meta: EJUOpenListeningMeta
    let papers: [EJUOpenListeningPaper]
}

struct EJUOpenListeningMeta: Codable {
    let source: String
    let fetchedAt: String
    let indexURL: String
    let paperCount: Int
    let trackCount: Int
}

struct EJUOpenListeningPaper: Codable {
    let title: String
    let sourcePage: String
    let scriptPDF: String
    let tracks: [EJUOpenListeningTrack]
}

struct EJUOpenListeningTrack: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let audioURL: String
}

struct EJUOpenListeningStore {
    static let shared = EJUOpenListeningStore()
    let data: EJUOpenListeningData?

    private init() {
        guard let url = Bundle.main.url(forResource: "eju_listening_oss", withExtension: "json"),
              let raw = try? Data(contentsOf: url) else {
            data = nil
            return
        }
        data = try? JSONDecoder().decode(EJUOpenListeningData.self, from: raw)
    }
}

enum EJUListeningCategory: String, CaseIterable {
    case all = "全部"
    case campus = "校园生活"
    case lecture = "讲义理解"
    case chart = "图表信息"
    case integrated = "综合判断"
}

struct EJUListeningQuestion: Identifiable {
    let id: String
    let category: EJUListeningCategory
    let difficulty: String
    let prompt: String
    let script: String
    let options: [String]
    let answerIndex: Int
    let explanation: String
}

struct EJUListeningQuestionStore {
    static let shared = EJUListeningQuestionStore()

    let questions: [EJUListeningQuestion] = [
        EJUListeningQuestion(
            id: "eju-001",
            category: .campus,
            difficulty: "基础",
            prompt: "你将听到留学生与教务员的对话，请判断办理课程变更的截止时间。",
            script: "学生：すみません、履修変更の締切はいつですか。職員：今週金曜日の午後五時までです。オンライン申請は午後四時半で閉まります。",
            options: ["周四下午五点", "周五下午五点", "周五晚上七点", "下周一中午"],
            answerIndex: 1,
            explanation: "关键词是「今週金曜日の午後五時まで」。四点半是线上系统关闭时间，不是最终截止。"
        ),
        EJUListeningQuestion(
            id: "eju-002",
            category: .campus,
            difficulty: "基础",
            prompt: "请判断学生最终选择的咨询方式。",
            script: "学生：奨学金の相談は対面ですか。先生：火曜は対面、水曜はオンラインです。学生：では授業の後に参加できる水曜のオンラインにします。",
            options: ["周二线下面谈", "周三线上咨询", "电话咨询", "邮件咨询"],
            answerIndex: 1,
            explanation: "末尾「水曜のオンラインにします」直接给出最终选择。"
        ),
        EJUListeningQuestion(
            id: "eju-003",
            category: .lecture,
            difficulty: "中级",
            prompt: "你将听到课堂说明，判断老师强调的阅读顺序。",
            script: "先生：来週の授業では、まず要約を読んで全体像をつかみます。その後、第二章の実験結果を確認し、最後に考察を比較してください。",
            options: ["先看实验结果，再看摘要", "摘要→第二章结果→比较考察", "直接比较考察和结论", "第二章结果→考察→摘要"],
            answerIndex: 1,
            explanation: "信号词「まず」「その後」「最後に」明确了三步顺序。"
        ),
        EJUListeningQuestion(
            id: "eju-004",
            category: .lecture,
            difficulty: "中级",
            prompt: "请判断讲师对小组报告的核心要求。",
            script: "講師：発表資料は見やすさより、根拠の明確さを重視します。データの出典を示し、主張と結論のつながりを説明してください。",
            options: ["版面美观最重要", "需要增加动画效果", "强调依据与论证连接", "只要结论正确即可"],
            answerIndex: 2,
            explanation: "讲师明确对比了「見やすさより、根拠の明確さ」。"
        ),
        EJUListeningQuestion(
            id: "eju-005",
            category: .chart,
            difficulty: "中级",
            prompt: "你将听到图表说明，判断哪个时间段增长最快。",
            script: "説明します。利用者数は四月が百人、五月が百二十人、六月が百八十人、七月が二百人です。増加幅が最も大きいのは五月から六月です。",
            options: ["四月到五月", "五月到六月", "六月到七月", "七月到八月"],
            answerIndex: 1,
            explanation: "题干已给出增长幅最大的是「五月から六月」。"
        ),
        EJUListeningQuestion(
            id: "eju-006",
            category: .chart,
            difficulty: "中级",
            prompt: "根据说明判断预算调整方向。",
            script: "今年度は広告費を一割減らし、その分をサポート体制に回します。研究開発費は現状維持です。",
            options: ["广告费增加，研发减少", "广告费减少，支持投入增加", "全部预算保持不变", "研发投入转到广告"],
            answerIndex: 1,
            explanation: "「広告費を一割減らし、その分をサポート体制に回します」是关键句。"
        ),
        EJUListeningQuestion(
            id: "eju-007",
            category: .integrated,
            difficulty: "进阶",
            prompt: "你将听到两位学生讨论，判断最终行动方案。",
            script: "A：図書館で準備したいけど、席が空いてないかも。B：じゃあ先にオンラインで資料を共有して、空いたら合流しよう。A：それなら時間を無駄にしないね。そうしよう。",
            options: ["两人立刻去图书馆排队", "先线上共享资料，再视情况会合", "取消当天学习计划", "改成电话讨论"],
            answerIndex: 1,
            explanation: "B 提出方案后 A 表示同意，形成最终决策。"
        ),
        EJUListeningQuestion(
            id: "eju-008",
            category: .integrated,
            difficulty: "进阶",
            prompt: "请判断发言人的隐含态度。",
            script: "担当者：確かに計画は魅力的です。ただ、期限が短すぎると品質に影響します。実現するなら段階的に進めるべきです。",
            options: ["完全反对计划", "无条件支持立即执行", "认可方向但主张分阶段推进", "对计划没有意见"],
            answerIndex: 2,
            explanation: "转折词「ただ」后给出限制条件，态度是审慎支持。"
        ),
        EJUListeningQuestion(
            id: "eju-009",
            category: .campus,
            difficulty: "中级",
            prompt: "请判断学生申请宿舍失败的主要原因。",
            script: "職員：申請書は届いていますが、保証人欄が未記入です。今日中に提出できれば再審査できます。",
            options: ["申请时间已过", "保证人栏未填写", "费用未缴纳", "成绩不达标"],
            answerIndex: 1,
            explanation: "「保証人欄が未記入」是失败原因。"
        ),
        EJUListeningQuestion(
            id: "eju-010",
            category: .lecture,
            difficulty: "进阶",
            prompt: "请判断教授要求先完成的任务。",
            script: "教授：アンケート分析の前に、回答の分類基準を統一してください。基準が揃わないと比較ができません。",
            options: ["先做图表设计", "先统一分类标准", "先写结论部分", "先扩充样本数量"],
            answerIndex: 1,
            explanation: "「分析の前に」后的动作是优先任务。"
        ),
        EJUListeningQuestion(
            id: "eju-011",
            category: .chart,
            difficulty: "进阶",
            prompt: "根据说明判断哪个渠道转化率最低。",
            script: "資料によると、検索広告が四・二％、SNSが二・八％、メールが五・一％です。最も低いのはSNSです。",
            options: ["搜索广告", "SNS", "邮件", "线下活动"],
            answerIndex: 1,
            explanation: "发言人明确指出「最も低いのはSNS」。"
        ),
        EJUListeningQuestion(
            id: "eju-012",
            category: .integrated,
            difficulty: "进阶",
            prompt: "综合发言判断会议结论。",
            script: "部長：予算は限られています。A案は効果が高いがコストが重い。B案は効果は中程度だが実施が早い。では、今期はB案、来期にA案を検討しましょう。",
            options: ["立即执行A案", "本期先做B案，下期再评估A案", "A案和B案同时执行", "两案全部取消"],
            answerIndex: 1,
            explanation: "最后一句是明确结论。"
        )
    ]
}

struct WeeklyCheckInCard: View {
    let levelTitle: String
    let accent: Color
    let plans: [StudyWeekPlan]

    @State private var checkedTaskIDs: Set<String> = []

    private var totalTaskCount: Int {
        plans.reduce(0) { partial, week in
            partial + week.days.reduce(0) { $0 + $1.tasks.count }
        }
    }

    private var completedTaskCount: Int {
        checkedTaskIDs.count
    }

    private var progress: Double {
        Double(completedTaskCount) / Double(max(totalTaskCount, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.square.stack.fill")
                    .foregroundColor(accent)
                Text("周计划打卡进度")
                    .font(.headline)
                Spacer()
                Text("\(completedTaskCount)/\(totalTaskCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress, total: 1)
                .tint(accent)

            Text("按“周计划 -> 每日任务”逐项打卡，适合考前节奏化推进。")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(plans) { week in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(week.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("完成 \(weekCompletedCount(week))/\(weekTaskCount(week))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    ForEach(week.days) { day in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(day.title)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(Array(day.tasks.enumerated()), id: \.offset) { index, task in
                                let taskID = makeTaskID(weekID: week.id, dayID: day.id, taskIndex: index)
                                Button {
                                    toggle(taskID: taskID)
                                } label: {
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: checkedTaskIDs.contains(taskID) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(checkedTaskIDs.contains(taskID) ? accent : .secondary)
                                            .padding(.top, 1)
                                        Text(task)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(10)
                .background(accent.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            loadCheckInState()
        }
    }

    private func makeTaskID(weekID: String, dayID: String, taskIndex: Int) -> String {
        "\(weekID)_\(dayID)_\(taskIndex)"
    }

    private func storageKey() -> String {
        "jlpt_weekly_checkin_\(levelTitle)"
    }

    private func toggle(taskID: String) {
        if checkedTaskIDs.contains(taskID) {
            checkedTaskIDs.remove(taskID)
        } else {
            checkedTaskIDs.insert(taskID)
        }
        saveCheckInState()
    }

    private func loadCheckInState() {
        let raw = UserDefaults.standard.string(forKey: storageKey()) ?? ""
        checkedTaskIDs = Set(raw.split(separator: ",").map(String.init))
    }

    private func saveCheckInState() {
        let raw = checkedTaskIDs.sorted().joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: storageKey())
    }

    private func weekTaskCount(_ week: StudyWeekPlan) -> Int {
        week.days.reduce(0) { $0 + $1.tasks.count }
    }

    private func weekCompletedCount(_ week: StudyWeekPlan) -> Int {
        week.days.reduce(0) { partial, day in
            let count = day.tasks.indices.filter { index in
                checkedTaskIDs.contains(makeTaskID(weekID: week.id, dayID: day.id, taskIndex: index))
            }.count
            return partial + count
        }
    }
}

struct LearningDashboardCard: View {
    let accent: Color
    let streakDays: Int
    let todayCount: Int
    let todayGoal: Int
    let masteryRate: Int
    let wrongCount: Int
    let attempts: Int

    private var goalRatio: Double {
        Double(min(todayCount, todayGoal)) / Double(max(todayGoal, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("学习仪表盘")
                    .font(.headline)
                Spacer()
                Text("已训练 \(attempts) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                MetricPill(title: "连续学习", value: "\(streakDays) 天", accent: accent)
                MetricPill(title: "掌握率", value: "\(masteryRate)%", accent: .green)
                MetricPill(title: "错题库", value: "\(wrongCount) 题", accent: .orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("今日目标")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(todayCount) / \(todayGoal) 题")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ProgressView(value: goalRatio, total: 1)
                    .tint(accent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct JLPTLevelCard: View {
    let level: JLPTLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(level.title)
                    .font(.headline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(level.accent.opacity(0.2))
                    .clipShape(Capsule())

                Spacer()

                Text(level.estimatedCycle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(level.focus)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(level.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Text("词汇 \(level.vocabularyGoal)")
                Text("·")
                Text("汉字 \(level.kanjiGoal)")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(level.accent.opacity(0.24), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct JLPTDetailCard: View {
    let title: String
    let icon: String
    let accent: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(accent)
                Text(title)
                    .font(.headline)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(accent.opacity(0.8))
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct StatChip: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 大家的日本语会话数据模型
struct MinnaConversationData: Codable {
    let meta: MinnaConversationMeta
    let lessons: [MinnaConversationLesson]
}

struct MinnaConversationMeta: Codable {
    let source: String
    let description: String
    let total_lessons: Int
    let generated_at: String
}

struct MinnaConversationLesson: Codable, Identifiable {
    var id: UUID = UUID()
    let lesson_number: Int
    let title: String
    let dialogues: [Dialogue]
    let audio_url: String?
    let audio_filename: String?

    enum CodingKeys: String, CodingKey {
        case id
        case lesson_number
        case title
        case dialogues
        case audio_url
        case audio_filename
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        lesson_number = try container.decode(Int.self, forKey: .lesson_number)
        title = try container.decode(String.self, forKey: .title)
        dialogues = try container.decode([Dialogue].self, forKey: .dialogues)
        audio_url = try container.decodeIfPresent(String.self, forKey: .audio_url)
        audio_filename = try container.decodeIfPresent(String.self, forKey: .audio_filename)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lesson_number, forKey: .lesson_number)
        try container.encode(title, forKey: .title)
        try container.encode(dialogues, forKey: .dialogues)
        try container.encodeIfPresent(audio_url, forKey: .audio_url)
        try container.encodeIfPresent(audio_filename, forKey: .audio_filename)
    }
}

struct Dialogue: Codable, Identifiable {
    var id: UUID = UUID()
    let speaker: String
    let japanese: String
    let chinese: String
    let english: String

    enum CodingKeys: String, CodingKey {
        case id
        case speaker
        case japanese
        case chinese
        case english
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        speaker = try container.decode(String.self, forKey: .speaker)
        japanese = try container.decode(String.self, forKey: .japanese)
        chinese = try container.decode(String.self, forKey: .chinese)
        english = try container.decode(String.self, forKey: .english)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(japanese, forKey: .japanese)
        try container.encode(chinese, forKey: .chinese)
        try container.encode(english, forKey: .english)
    }
}

@MainActor
final class MinnaConversationStore: ObservableObject {
    static let shared = MinnaConversationStore()
    @Published var data: MinnaConversationData?

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "minna_conversation_lessons", withExtension: "json") else {
            print("❌ 未找到 minna_conversation_lessons.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.data = try JSONDecoder().decode(MinnaConversationData.self, from: data)
            print("✓ 大家的日本语会话数据加载成功: \(self.data?.lessons.count ?? 0) 课")
        } catch {
            print("❌ 加载大家的日本语会话数据失败: \(error)")
        }
    }
}

// MARK: - 日本新闻阅读功能

struct JapaneseNewsItem: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let summary: String
    let content: String
    let imageUrl: String?
    let source: String
    let publishedDate: String
    let category: String

    enum CodingKeys: String, CodingKey {
        case id, title, summary, content, imageUrl, source, publishedDate, category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        content = try container.decode(String.self, forKey: .content)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        source = try container.decode(String.self, forKey: .source)
        publishedDate = try container.decode(String.self, forKey: .publishedDate)
        category = try container.decode(String.self, forKey: .category)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(content, forKey: .content)
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(source, forKey: .source)
        try container.encode(publishedDate, forKey: .publishedDate)
        try container.encode(category, forKey: .category)
    }
}

struct JapaneseNewsData: Codable {
    let meta: NewsMeta
    let news: [JapaneseNewsItem]
}

struct NewsMeta: Codable {
    let lastUpdated: String
    let source: String
    let totalCount: Int
}

@MainActor
final class JapaneseNewsStore: ObservableObject {
    static let shared = JapaneseNewsStore()
    @Published var data: JapaneseNewsData?

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "japanese_news", withExtension: "json") else {
            print("❌ 未找到 japanese_news.json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.data = try JSONDecoder().decode(JapaneseNewsData.self, from: data)
            print("✓ 日本新闻数据加载成功: \(self.data?.news.count ?? 0) 条")
        } catch {
            print("❌ 加载日本新闻数据失败: \(error)")
        }
    }
}

struct NewsReadingView: View {
    @StateObject private var newsStore = JapaneseNewsStore.shared
    @State private var selectedCategory = "全部"
    @State private var selectedNews: JapaneseNewsItem?

    private let categories = ["全部", "政治", "经济", "社会", "科技", "文化", "体育"]

    private var filteredNews: [JapaneseNewsItem] {
        guard let news = newsStore.data?.news else { return [] }
        if selectedCategory == "全部" {
            return news
        }
        return news.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 顶部分类选择器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                withAnimation {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))

                // 瀑布流新闻列表
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredNews) { item in
                            NewsCard(item: item)
                                .onTapGesture {
                                    selectedNews = item
                                }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("日本新闻")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedNews) { item in
                NewsDetailView(newsItem: item)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

struct NewsCard: View {
    let item: JapaneseNewsItem

    var categoryColor: Color {
        switch item.category {
        case "政治": return .red
        case "经济": return .orange
        case "社会": return .blue
        case "科技": return .purple
        case "文化": return .pink
        case "体育": return .green
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片 - 占据大部分卡片空间
            ZStack {
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                    case .failure:
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 200)
                            .overlay {
                                Image(systemName: "newspaper.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }

                // 分类标签 - 叠加在图片上
                VStack {
                    HStack {
                        Text(item.category)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            // 内容区域
            VStack(alignment: .leading, spacing: 8) {
                // 标题
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .foregroundColor(.primary)

                // 摘要
                Text(item.summary)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .lineSpacing(2)
                    .foregroundColor(.secondary)

                // 底部信息
                HStack(spacing: 8) {
                    // 来源
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10))
                        Text(item.source)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)

                    Spacer()

                    // 时间
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(formatDate(item.publishedDate))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            let now = Date()
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0

            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "昨天"
            } else if days < 7 {
                return "\(days)天前"
            } else {
                formatter.dateFormat = "MM-dd"
                return formatter.string(from: date)
            }
        }
        return dateString
    }
}

struct NewsDetailView: View {
    let newsItem: JapaneseNewsItem
    @Environment(\.dismiss) private var dismiss

    var categoryColor: Color {
        switch newsItem.category {
        case "政治": return .red
        case "经济": return .orange
        case "社会": return .blue
        case "科技": return .purple
        case "文化": return .pink
        case "体育": return .green
        default: return .gray
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 大图封面
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: URL(string: newsItem.imageUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(.systemGray5), Color(.systemGray6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 280)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 280)
                            case .failure:
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(.systemGray5), Color(.systemGray6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 280)
                                    .overlay {
                                        Image(systemName: "newspaper.fill")
                                            .font(.system(size: 70))
                                            .foregroundColor(.gray.opacity(0.4))
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // 渐变遮罩
                        VStack {
                            Spacer()
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 120)
                        }

                        // 叠加信息
                        VStack(alignment: .leading, spacing: 8) {
                            // 分类标签
                            Text(newsItem.category)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(categoryColor)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                            // 标题
                            Text(newsItem.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .padding(20)
                    }

                    // 内容区域
                    VStack(alignment: .leading, spacing: 20) {
                        // 元信息
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.secondary)
                                Text(newsItem.source)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.secondary)
                                Text(newsItem.publishedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // 正文
                        VStack(alignment: .leading, spacing: 16) {
                            Text(newsItem.content)
                                .font(.system(size: 16))
                                .lineSpacing(8)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
