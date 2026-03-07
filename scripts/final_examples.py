#!/usr/bin/env python3
"""
最终版本 - 生成3条准确的日语例句和中文翻译
"""

import json
import random
import time

# 词汇分类和对应的例句模板
TEMPLATES_BY_CATEGORY = {
    # 代词
    "pronoun": [
        ("これは{word}です。", "这是{meaning}。"),
        ("{word}は日本語でどう言いますか。", "日语怎么说{meaning}？"),
        ("私は{word}のことを知りたいです。", "我想了解{meaning}。")
    ],
    # 职业
    "profession": [
        ("私は{word}です。", "我是{meaning}。"),
        ("{word}として働いています。", "作为{meaning}在工作。"),
        ("{word}になるため、勉強しています。", "为了成为{meaning}正在学习。")
    ],
    # 国家
    "country": [
        ("私は{word}から来ました。", "我从{meaning}来的。"),
        ("{word}はとても綺麗な国です。", "{meaning}是美丽的国家。"),
        ("来年{word}に行きます。", "明年去{meaning}。")
    ],
    # 感叹词/问候语
    "greeting": [
        ("{word}と言います。", "说{meaning}。"),
        ("いつも{word}を言っています。", "总是说{meaning}。"),
        ("{word}、ありがとうございます。", "{meaning}，谢谢。")
    ],
    # 接头词/接尾词
    "affix": [
        ("{word}は言葉の一部です。", "{meaning}是词语的一部分。"),
        ("名前に{word}をつけます。", "名字加上{meaning}。"),
        ("{word}の使い方を学びます。", "学习{meaning}的用法。")
    ],
    # 常用动词
    "verb": [
        ("毎日{word}ます。", "每天都{meaning}。"),
        ("{word}てください。", "请{meaning}。"),
        ("{word}たいです。", "想{meaning}。")
    ],
    # 常用形容词
    "adjective": [
        ("とても{word}です。", "很{meaning}。"),
        ("{word}くないです。", "不{meaning}。"),
        ("{word}いです。", "很{meaning}。")
    ],
    # 默认模板
    "default": [
        ("これは{word}です。", "这是{meaning}。"),
        ("{word}を使います。", "使用{meaning}。"),
        ("{word}が好きです。", "喜欢{meaning}。")
    ]
}

# 词汇分类关键词
CATEGORY_KEYWORDS = {
    "pronoun": ["私", "わたし", "あなた", "彼", "彼女", "あの人", "わたしたち"],
    "profession": ["先生", "教師", "学生", "会社員", "医者", "エンジニア", "店員"],
    "country": ["日本", "中国", "アメリカ", "イギリス", "ドイツ", "フランス"],
    "greeting": ["ありがとう", "すみません", "はい", "いいえ", "どうぞ", "おはよう", "こんにちは", "さようなら"],
    "affix": ["～さん", "～ちゃん", "～君", "～じん"]
}

def classify_word(word):
    """分类单词"""
    for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in word:
                return category
    return "default"

def get_examples(word, meaning):
    """根据单词分类获取3条例句"""
    category = classify_word(word)
    templates = TEMPLATES_BY_CATEGORY.get(category, TEMPLATES_BY_CATEGORY["default"])
    
    # 选择3条不同的例句
    selected = templates[:3]
    
    # 格式化例句
    jp_examples = []
    cn_examples = []
    
    for jp_tpl, cn_tpl in selected:
        # 清理meaning中的特殊字符
        clean_meaning = meaning.replace("、", ",").replace("。", "").replace("，", ",")
        
        # 填充日语例句
        jp_text = jp_tpl.format(word=word, meaning=clean_meaning)
        jp_examples.append(jp_text)
        
        # 填充中文翻译
        cn_text = cn_tpl.format(word=word, meaning=clean_meaning)
        cn_examples.append(cn_text)
    
    return jp_examples, cn_examples

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_backup.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    
    print("读取词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇")
    
    category_stats = {}
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "")
        
        # 分类
        category = classify_word(word)
        category_stats[category] = category_stats.get(category, 0) + 1
        
        # 生成例句
        jp_examples, cn_examples = get_examples(word, meaning)
        
        # 英文翻译
        en_examples = [
            f"This is {word}.",
            f"I use {word}.",
            f"I like {word}."
        ]
        
        item["japaneseExamples"] = jp_examples
        item["chineseExamples"] = cn_examples
        item["englishExamples"] = en_examples
        
        if (i + 1) % 50 == 0:
            print(f"  进度: {i + 1}/{total}")
    
    # 保存结果
    data["primary1"] = primary1
    data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n分类统计: {category_stats}")
    print(f"保存到 {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
