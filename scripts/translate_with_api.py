#!/usr/bin/env python3
"""
调用开源翻译API获取准确的中文翻译
使用LibreTranslate公共API或MyMemory API
"""

import json
import random
import urllib.request
import urllib.parse
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
import sys

# 尝试多个开源翻译API
APIS = [
    ("MyMemory", "https://api.mymemory.translated.net/get", "ja|zho"),
]

def translate(text, api_index=0, max_retries=2):
    """调用开源API翻译日文到中文"""
    for retry in range(max_retries):
        try:
            if api_index == 0:  # MyMemory
                params = urllib.parse.urlencode({
                    "q": text,
                    "langpair": "ja|zh-CN"
                })
                url = f"https://api.mymemory.translated.net/get?{params}"
                
            req = urllib.request.Request(url, headers={
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)'
            })
            
            with urllib.request.urlopen(req, timeout=8) as response:
                data = json.loads(response.read().decode("utf-8"))
                if data.get("responseStatus") == 200:
                    result = data.get("responseData", {}).get("translatedText", "")
                    if result and len(result) > 2:
                        return result
                        
        except Exception as e:
            time.sleep(0.3)
    
    return None

# 日语例句模板
TEMPLATES = {
    "名词": [
        ("これは{word}です。", "这是{meaning}。"),
        ("{word}は使えますか。", "可以使用{meaning}吗？"),
        ("{word}が好きです。", "我喜欢{meaning}。"),
        ("{word}はどこにありますか。", "{meaning}在哪里？"),
        ("{word}をください。", "请给我{meaning}。"),
    ],
    "代词": [
        ("那是{word}です。", "那是{meaning}。"),
        ("{word}は何ですか。", "{meaning}是什么？"),
        ("{word}が好きです。", "喜欢{meaning}。"),
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

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_with_examples.json"
    
    print("读取词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇需要处理")
    print("使用开源API翻译日文例句...")
    
    success_count = 0
    fail_count = 0
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "")
        part_of_speech = item.get("partOfSpeech", "default")
        
        # 获取模板
        templates = TEMPLATES.get(part_of_speech, TEMPLATES["default"])
        selected = templates[:3]
        
        # 生成日语例句
        jp_examples = [tpl[0].format(word=word, meaning=meaning) for tpl in selected]
        
        # 翻译日文到中文
        cn_examples = []
        for jp_ex in jp_examples:
            cn_trans = translate(jp_ex)
            if cn_trans:
                cn_examples.append(cn_trans)
                success_count += 1
            else:
                # 使用模板翻译
                cn_examples.append(tpl[1].format(meaning=meaning))
                fail_count += 1
            time.sleep(0.2)  # 避免API限流
        
        # 英文翻译
        en_examples = [
            f"This is {word}.",
            f"I use {word}.",
            f"I like {word}."
        ]
        
        item["japaneseExamples"] = jp_examples
        item["chineseExamples"] = cn_examples
        item["englishExamples"] = en_examples
        
        if (i + 1) % 20 == 0:
            print(f"  进度: {i + 1}/{total} (API成功: {success_count}, 失败: {fail_count})")
    
    # 保存结果
    data["primary1"] = primary1
    data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n翻译完成! 成功: {success_count}, 失败: {fail_count}")
    print(f"保存到 {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
