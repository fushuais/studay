# 🎓 日语学习 App

> 轻松掌握日语 - 专业的iOS日语学习应用

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018.0%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[📱 查看演示网站](https://fushuais.github.io/studay/)

## ✨ 功能特点

### 📚 词汇学习
系统的日语词汇学习功能：
- 🎯 N5-N1 级别词汇分类
- 🔤 日语假名、汉字、读音学习
- 📖 详细的中文释义和例句
- 💾 离线词汇库支持
- ⭐ 收藏重要词汇

### 👂 听力训练
专业的日语听力练习：
- 🎧 标准日语发音训练
- 📝 JLPT 考试听力模拟
- 🔄 重复播放和速度调节
- ✅ 听力理解测试

### 📝 语法练习
系统的日语语法学习：
- 📚 基础到高级语法讲解
- ✍️ 语法填空练习
- 🔄 语法结构分析
- 📈 学习进度跟踪

### 📰 日语新闻阅读
实时日本新闻阅读体验：
- 🌐 多源新闻（NHK、Yahoo、Google）
- 🏷️ 分类浏览（政治、经济、社会、科技、文化、体育）
- 💬 小红书风格瀑布流布局
- 👍 社交互动（点赞、收藏、分享）
- 📱 优化的详情页阅读体验

## 📱 技术栈

- **语言**: Swift 5.0
- **框架**: SwiftUI
- **最低版本**: iOS 18.0
- **架构**: MVVM
- **特性**:
  - JSON 词汇数据管理
  - 现代化UI设计
  - 响应式布局
  - 底部Tab导航
  - 离线学习支持

## 🚀 快速开始

### 环境要求

- macOS 14.0+
- Xcode 16.3+
- iOS 18.0+

### 安装步骤

1. 克隆仓库
```bash
git clone https://github.com/fushuais/travel.git
cd travel
```

2. 打开项目
```bash
open travel.xcodeproj
```

3. 选择模拟器或真机，点击运行按钮 (⌘R)

## 📸 截图

<div align="center">
  <img src="screenshots/vocabulary.png" width="250" alt="词汇学习页面">
  <img src="screenshots/listening.png" width="250" alt="听力训练页面">
  <img src="screenshots/grammar.png" width="250" alt="语法练习页面">
</div>

## 🃏 词汇卡片学习

采用 Tinder 风格的卡片式学习方式，左滑标记"不认识"，右滑标记"已掌握"：

```
┌─────────────────────────────┐
│           私                 │  ← 日语单词（大字橙色）
│          わたし              │  ← 假名读音
│           我                  │  ← 中文意思（大字）
│                             │
│  ┌─────────────────────┐    │
│  │ 📖 日语例句          │    │
│  │ これは私の例文です。 │    │  ← 点击卡片展开
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🟢 中文翻译          │    │
│  │ 这是「私」的例句：我。│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🔵 英文翻译          │    │
│  │ This is an example  │    │
│  │ of 私.              │    │
│  └─────────────────────┘    │
│                             │
│  ┌───────┐       ┌───────┐  │
│  │   ❌   │       │   ✓   │  │
│  │ 不认识 │       │ 已掌握 │  │
│  └───────┘       └───────┘  │
└─────────────────────────────┘
```

**卡片特点：**
- 📚 支持多级别词汇：标准日本语初级、大家的日本语、N3-N1
- 🎯 按课程分课学习
- 📖 例句包含日语、中文翻译、英文翻译
- 💾 学习进度自动保存
- 📊 通过率统计

## 🎨 设计特色

- **现代化UI**: 采用卡片式设计，美观大方
- **流畅动画**: 丰富的交互动画和过渡效果
- **响应式**: 完美支持iPhone和iPad
- **主题色**: 蓝色主题，代表学习与智慧

## 📂 项目结构

```
travel/
├── travel/
│   ├── travelApp.swift          # 应用入口
│   ├── ContentView.swift        # 主视图(TabView)
│   ├── VocabularyView.swift     # 词汇学习页面
│   ├── LocationView.swift       # 其他功能页面
│   ├── jlpt_intermediate_summary.json  # 词汇数据
│   └── Assets.xcassets/         # 资源文件
├── travelTests/                 # 单元测试
├── travelUITests/               # UI测试
└── docs/                        # 宣传网页
    ├── index.html
    └── admin.html
```

## 🔧 配置说明

### 数据管理

项目包含完整的JLPT词汇数据，支持离线学习：

```json
{
  "word": "ありがとう",
  "reading": "arigatou", 
  "meaning": "谢谢",
  "level": "N5"
}
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📝 开发计划

- [x] 添加发音功能
- [x] 实现学习进度跟踪
- [x] 添加测试和评估功能
- [ ] 集成语音识别
- [ ] 添加每日学习提醒
- [ ] 用户学习数据分析

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 👨‍💻 作者

- **Fu Shuai** - [GitHub](https://github.com/fushuais)

## 🙏 致谢

- 词汇数据来源: JLPT官方词汇表
- 设计灵感: Apple Design Resources
- Icons: SF Symbols

## 📧 联系方式

如有问题或建议，请通过以下方式联系：

- 📧 Email: your.email@example.com
- 🐦 Twitter: @yourusername
- 💼 LinkedIn: your-profile

---

<div align="center">
  <p>Made with ❤️ for Japanese learners</p>
  <p>© 2026 日语学习 App. All rights reserved.</p>
</div>
