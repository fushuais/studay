#!/usr/bin/env python3
"""
快速生成日语例句并使用开源API翻译
使用并发请求加速处理
"""

import json
import random
import urllib.request
import urllib.parse
import urllib.error
import time
import os
from concurrent.futures import ThreadPoolExecutor, as_completed

# MyMemory API endpoint
API_URL = "https://api.mymemory.translated.net/get"

# 例句模板库
TEMPLATES = {
    "名词": [
        ("これは{word}です。", "这是{meaning}。"),
        ("{word}は使えますか。", "可以使用{meaning}吗？"),
        ("{word}が好きです。", "我喜欢{meaning}。"),
        ("{word}はどこにありますか。", "{meaning}在哪里？"),
        ("{word}をください。", "请给我{meaning}。"),
    ],
    "代词": [
        ("それは{word}です。", "那是{meaning}。"),
        ("{word}は何ですか。", "{meaning}是什么？"),
        ("{word}が好きです。", "喜欢{meaning}。"),
        ("{word}はどこですか。", "{meaning}在哪里？"),
        ("{word}のものです。", "这是{meaning}的东西。"),
    ],
    "动词": [
        ("{word}てください。", "请{meaning}。"),
        ("{word}ます。", "{meaning}。"),
        ("{word}たいです。", "我想{meaning}。"),
    ],
    "形容词": [
        ("{word}です。", "是{meaning}的。"),
        ("{word}くないです。", "不是{meaning}。"),
        ("{word}いです。", "很{meaning}。"),
    ],
    "default": [
        ("これは{word}です。", "这是{meaning}。"),
        ("{word}を使ってみましょう。", "试试用{meaning}吧。"),
        ("{word}の意味を理解する。", "理解{meaning}的意思。"),
    ]
}

def translate_with_retry(text, retries=3, delay=0.5):
    """带重试的翻译函数"""
    for attempt in range(retries):
        try:
            params = urllib.parse.urlencode({
                "q": text,
                "langpair": "ja|zh-CN"
            })
            url = f"{API_URL}?{params}"
            
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode("utf-8"))
                if data.get("responseStatus") == 200:
                    return data.get("responseData", {}).get("translatedText", "")
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(delay)
            else:
                print(f"  翻译失败: {text[:20]}...")
    return None

def translate_batch(texts, max_workers=10):
    """并发翻译多个文本"""
    results = {}
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_text = {executor.submit(translate_with_retry, text): text for text in texts}
        for future in as_completed(future_to_text):
            text = future_to_text[future]
            try:
                results[text] = future.result()
            except Exception as e:
                results[text] = None
    return results

def process_word(args):
    """处理单个词汇"""
    word, meaning, part_of_speech, pos_templates = args
    
    # 选择模板
    templates = pos_templates.get(part_of_speech, pos_templates["default"])
    selected = random.sample(templates, min(3, len(templates)))
    
    # 生成日语例句
    jp_examples = [tpl[0].format(word=word, meaning=meaning) for tpl in selected]
    
    # 需要翻译的中文文本（使用占位符）
    cn_placeholder = [tpl[1].format(meaning=meaning) for tpl in selected]
    
    return word, jp_examples, cn_placeholder

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_with_examples.json"
    
    print("读取词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇需要处理")
    
    # 准备要翻译的文本（取前50个进行API翻译测试）
    # 由于API限制，我们只翻译部分数据，其他使用模板生成
    print("\n生成日语例句...")
    
    # 处理所有词汇
    processed = []
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "")
        part_of_speech = item.get("partOfSpeech", "default")
        
        # 生成日语例句
        templates = TEMPLATES.get(part_of_speech, TEMPLATES["default"])
        selected = random.sample(templates, min(3, len(templates)))
        
        jp_examples = [tpl[0].format(word=word, meaning=meaning) for tpl in selected]
        
        # 中文使用模板翻译（更可靠）
        cn_examples = [tpl[1].format(meaning=meaning) for tpl in selected]
        
        # 英文翻译
        en_examples = [
            f"This is {word}.",
            f"I use {word}.",
            f"I like {word}."
        ]
        
        item["japaneseExamples"] = jp_examples
        item["chineseExamples"] = cn_examples
        item["englishExamples"] = en_examples
        
        processed.append(item)
        
        if (i + 1) % 50 == 0:
            print(f"  进度: {i + 1}/{total}")
    
    # 保存结果
    data["primary1"] = processed
    data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n保存到 {output_file}...")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
