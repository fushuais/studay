#!/usr/bin/env python3
"""
生成更准确的日语例句，使用开源API翻译
"""

import json
import random
import urllib.request
import urllib.parse
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

API_URL = "https://api.mymemory.translated.net/get"

def translate(text):
    """翻译日文到中文"""
    try:
        params = urllib.parse.urlencode({"q": text, "langpair": "ja|zh-CN"})
        url = f"{API_URL}?{params}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode("utf-8"))
            if data.get("responseStatus") == 200:
                return data.get("responseData", {}).get("translatedText", "")
    except:
        pass
    return None

# 更好的日语例句模板
def get_examples(word, meaning):
    """根据词性生成自然日语例句"""
    
    # 基础常用表达
    examples_ja = [
        f"これは{word}です。",
        f"それは{word}ですか。",
        f"{word}が好きです。",
        f"{word}を使います。",
        f"{word}はどこにありますか。",
        f"{word}をください。",
        f"私は{word}を持っています。",
        f"{word}を見てください。",
        f"{word}の意味は「{meaning}」です。",
        f"{word}は大切です。"
    ]
    
    # 选择3个不同的
    selected = random.sample(examples_ja, 3)
    return selected

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    
    print("读取词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇")
    
    # 生成例句并翻译
    translated_count = 0
    template_count = 0
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "").split(",")[0]  # 取第一个意思
        
        # 日语例句
        jp_examples = get_examples(word, meaning)
        
        # 中文翻译 - 尝试API
        cn_examples = []
        for jp_ex in jp_examples:
            cn = translate(jp_ex)
            if cn:
                cn_examples.append(cn)
                translated_count += 1
            else:
                # 回退到模板
                cn_examples.append(f"[{meaning}]")
                template_count += 1
            time.sleep(0.15)  # 避免限流
        
        # 英文
        en_examples = [
            f"This is {word}.",
            f"I like {word}.",
            f"I use {word}."
        ]
        
        item["japaneseExamples"] = jp_examples
        item["chineseExamples"] = cn_examples
        item["englishExamples"] = en_examples
        
        if (i + 1) % 30 == 0:
            print(f"  进度: {i + 1}/{total}")
    
    data["primary1"] = primary1
    data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
    
    print(f"\n翻译: {translated_count}, 模板: {template_count}")
    print(f"保存到 {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
