//
//  ContentView.swift
//  travel
//
//  Created by fushuai on 2026/2/23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LocationView()
                .tabItem {
                    Label("探索", systemImage: "map.fill")
                }
                .tag(0)
            
            FoodView()
                .tabItem {
                    Label("美食", systemImage: "fork.knife")
                }
                .tag(1)
            
            AccommodationView()
                .tabItem {
                    Label("居住", systemImage: "house.fill")
                }
                .tag(2)

            LearningView()
                .tabItem {
                    Label("学习", systemImage: "book.fill")
                }
                .tag(3)
        }
        .accentColor(.orange)
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
            }
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
            summary: "从生活表达走向完整叙述，形成稳定输出能力",
            accent: .pink,
            vocabularyGoal: "1800 词",
            kanjiGoal: "320 字",
            estimatedCycle: "12 周",
            grammarTopics: [
                "动词变形体系（て形/ない形/辞书形/意向形）",
                "授受表达（あげる・くれる・もらう）",
                "连接与因果（ので、のに、ながら、てしまう）",
                "许可、禁止、义务（てもいい、てはいけない、なければならない）",
                "状态变化与经验（ようになる、ことがある）"
            ],
            readingTargets: [
                "200-350字生活短文与通知",
                "理解电车时刻、商店公告、活动说明",
                "准确抓取因果、转折、条件句关系"
            ],
            listeningTargets: [
                "日常语速对话（学校、医院、车站）",
                "听懂请求、建议、委婉拒绝",
                "完成N4听力四题型专项训练"
            ],
            speakingTargets: [
                "完成2-3分钟连续描述（行程、经历、计划）",
                "角色扮演：租房、请假、预约、投诉",
                "使用复合句进行理由说明"
            ],
            writingTargets: [
                "每周2篇150字日记/邮件",
                "同义句改写与错句修正",
                "语法点主题造句（每点10句）"
            ],
            weeklyPlan: [
                "周1-4：动词与句型基础巩固",
                "周5-8：阅读听力分题型突破",
                "周9-10：口语写作强化",
                "周11-12：2套全真模考 + 错题闭环"
            ],
            releaseChecklist: [
                "词汇与汉字覆盖率≥90%",
                "阅读正确率≥82%，听力正确率≥80%",
                "完成至少30篇精听与20篇短写作",
                "模考稳定达到及格线以上15分"
            ],
            resources: [
                "《TRY! N4》+《新完全掌握 N4》",
                "NHK EASY + 青空文库初级素材",
                "Shadowing 日本语初中级"
            ]
        ),
        JLPTLevel(
            title: "N3",
            focus: "中级过渡",
            summary: "进入中级语域，建立新闻/说明文理解与议题表达能力",
            accent: .purple,
            vocabularyGoal: "3800 词",
            kanjiGoal: "650 字",
            estimatedCycle: "16 周",
            grammarTopics: [
                "复杂从句与名词化（わけだ、ことになる、ようだ）",
                "逻辑连接（つまり、したがって、にもかかわらず）",
                "语气与态度表达（はず、べき、わけではない）",
                "敬体与简体切换，书面语过渡"
            ],
            readingTargets: [
                "450-700字说明文、专栏与公告",
                "识别主张、论据、让步与结论",
                "掌握高频接续词提升阅读速度"
            ],
            listeningTargets: [
                "电台访谈/校园广播/工作沟通",
                "抓取隐含意图与说话人立场",
                "专项突破图表题、即时应答题"
            ],
            speakingTargets: [
                "完成4分钟主题表达（学习、社会、文化）",
                "进行观点比较与理由展开",
                "小组讨论中完成追问与回应"
            ],
            writingTargets: [
                "每周1篇300字意见文 + 1篇摘要",
                "论点-论据-结论三段式写作",
                "常见误用表达对照纠错"
            ],
            weeklyPlan: [
                "周1-6：语法体系化 + 词汇分领域扩充",
                "周7-10：中长文阅读精讲与限时训练",
                "周11-13：听力语块与跟读复述",
                "周14-16：综合模考3套 + 口写打磨"
            ],
            releaseChecklist: [
                "阅读速度达到每分钟450字以上（易文）",
                "听力正确率≥78%，阅读正确率≥80%",
                "至少完成12次主题口语录音复盘",
                "3次模考总分稳定高于目标线10%"
            ],
            resources: [
                "《新完全掌握 N3（文法/読解/聴解）》",
                "日本新闻慢速音频与社论摘要",
                "italki/HelloTalk 主题讨论练习"
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("JLPT 学习路径")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("从 N5 到 N1 的分级课程，支持按目标逆推学习计划。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                ForEach(levels) { level in
                    NavigationLink {
                        JLPTLevelDetailView(level: level)
                    } label: {
                        JLPTLevelCard(level: level)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("日语")
    }
}

struct JLPTLevelDetailView: View {
    let level: JLPTLevel

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
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

                JLPTDetailCard(title: "语法模块", icon: "text.book.closed.fill", accent: level.accent, items: level.grammarTopics)
                JLPTDetailCard(title: "阅读目标", icon: "doc.text.fill", accent: level.accent, items: level.readingTargets)
                JLPTDetailCard(title: "听力目标", icon: "headphones", accent: level.accent, items: level.listeningTargets)
                JLPTDetailCard(title: "口语任务", icon: "mic.fill", accent: level.accent, items: level.speakingTargets)
                JLPTDetailCard(title: "写作任务", icon: "pencil.line", accent: level.accent, items: level.writingTargets)
                JLPTDetailCard(title: "分周计划", icon: "calendar", accent: level.accent, items: level.weeklyPlan)
                JLPTDetailCard(title: "发行标准清单", icon: "checkmark.seal.fill", accent: .green, items: level.releaseChecklist)
                JLPTDetailCard(title: "推荐资源", icon: "books.vertical.fill", accent: .blue, items: level.resources)
            }
            .padding()
        }
        .navigationTitle(level.title)
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

#Preview {
    ContentView()
}
