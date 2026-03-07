#!/usr/bin/env python3
"""
生成更自然的日语例句，包含正确的中文翻译
"""

import json
import random
import time

def get_natural_examples(word, meaning):
    """根据单词生成3条自然的日语例句和中文翻译"""
    
    # 1. 识别词性（简单启发式）
    if word in ["私", "わたし", "あなた", "彼", "彼女", "あの人", "わたしたち"]:
        # 代词
        return [
            ("これは{word}です。", f"这是{meaning}。"),
            ("{word}は日本語で「{word}」と言います。", f"{meaning}用日语叫作「{word}」。"),
            ("私は{word}のことを知っています。", f"我知道{meaning}的事情。")
        ]
    elif word in ["先生", "教師", "学生", "会社員", "医者"]:
        # 职业/身份
        return [
            ("私は{word}です。", f"我是{meaning}。"),
            ("{word}は仕事をしています。", f"{meaning}在工作。"),
            ("{word}になることが夢です。", f"梦想成为{meaning}。")
        ]
    elif word in ["日本", "中国", "アメリカ", "イギリス"]:
        # 国家
        return [
            ("私は{word}から来ました。", f"我从{meaning}来的。"),
            ("{word}はとても美しい国です。", f"{meaning}是很美的国家。"),
            ("{word}に行きたいです。", f"我想去{meaning}。")
        ]
    elif word in ["ありがとう", "すみません", "はい", "いいえ", "どうぞ"]:
        # 感叹词
        return [
            ("{word}！", f"{meaning}！"),
            ("{word}、ありがとうございます。", f"{meaning}，谢谢。"),
            ("いつも{word}と言います。", f"总是说{meaning}。")
        ]
    elif meaning in ["～", "～个", "～人"] or word.startswith("～"):
        # 接尾词
        return [
            ("{word}は名前につけます。", f"{meaning}是加在名字后面的。"),
            ("田中{word}と呼びます。", f"叫作田中{meaning}。"),
            ("{word}の使い方を覚えました。", f"记住了{meaning}的用法。")
        ]
    elif "。" in meaning or "、" in meaning:
        # 描述性词汇
        return [
            ("{word}はとても大切です。", f"{meaning}很重要。"),
            ("{word}について話しましょう。", f"让我们来谈谈{meaning}。"),
            ("{word}を勉強しています。", f"正在学习{meaning}。")
        ]
    else:
        # 默认
        return [
            ("これは{word}です。", f"这是{meaning}。"),
            ("{word}を使います。", f"使用{meaning}。"),
            ("{word}が好きです。", f"喜欢{meaning}。")
        ]

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_backup.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    
    print("读取原始词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇")
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "")
        
        # 生成3条自然例句
        examples = get_natural_examples(word, meaning)
        
        jp_examples = [ex[0].format(word=word, meaning=meaning) for ex in examples]
        cn_examples = [ex[1].format(word=word, meaning=meaning) for ex in examples]
        
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
    
    print(f"\n保存到 {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
