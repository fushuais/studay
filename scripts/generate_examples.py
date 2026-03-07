#!/usr/bin/env python3
"""
生成日语例句并调用开源翻译API获取中文翻译
使用 MyMemory Translation API (免费开源翻译API)
"""

import json
import random
import urllib.request
import urllib.parse
import time

# MyMemory API  endpoint
API_URL = "https://api.mymemory.translated.net/get"

def translate(text, source_lang="ja", target_lang="zh"):
    """调用MyMemory API翻译日文到中文"""
    try:
        params = urllib.parse.urlencode({
            "q": text,
            "langpair": f"{source_lang}|{target_lang}"
        })
        url = f"{API_URL}?{params}"
        
        with urllib.request.urlopen(url, timeout=10) as response:
            data = json.loads(response.read().decode("utf-8"))
            if data.get("responseStatus") == 200:
                return data.get("responseData", {}).get("translatedText", "")
            else:
                print(f"翻译失败: {data}")
                return None
    except Exception as e:
        print(f"翻译错误: {e}")
        return None

# 根据词性生成不同类型的日语例句模板
def generate_japanese_examples(word, part_of_speech):
    """生成3条不同的日语例句"""
    
    # 基础例句模板库
    templates = {
        "名词": [
            "これは{word}です。",
            "{word}は使えますか。",
            "{word}が好きです。",
            "{word}はどこにありますか。",
            "{word}をください。",
            "{word}は何ですか。",
            "{word}があります。",
            "{word}を使います。",
            "{word}を見てください。",
            "{word}を持っています。"
        ],
        "代词": [
            "それは{word}です。",
            "{word}は何ですか。",
            "{word}が好きです。",
            "{word}はどこですか。",
            "{word}のものです。",
            "{word}を見てください。",
            "{word}があります。",
            "{word}を使いました。",
            "{word}をお願いします。",
            "{word}はどうですか。"
        ],
        "动词": [
            "{word}てください。",
            "{word}ます。",
            "{word}たいです。",
            "{word}ましょう。",
            "{word}てください。",
            "{word}てください。",
            "{word}ることができません。",
            "{word}ています。",
            "{word}てください。",
            "{word}たいです。"
        ],
        "形容词": [
            "{word}です。",
            "{word}くないです。",
            "{word}いです。",
            "{word}くないです。",
            "{word}くて美しいです。",
            "{word}そうな外観です。",
            "{word}くないです。",
            "{word}すぎます。",
            "{word}くないです。",
            "{word}くないです。"
        ],
        "副词": [
            "{word}行動します。",
            "{word}食べます。",
            "{word}歩きます。",
            "{word}見ます。",
            "{word}話します。",
            "{word}します。",
            "{word}になります。",
            "{word}思っています。",
            "{word}来ていました。",
            "{word}書いてください。"
        ],
        "数词": [
            "{word}個あります。",
            "{word}つあります。",
            "{word}人います。",
            "{word}円かかります。",
            "{word}回あります。",
            "{word}枚あります。",
            "{word}本あります。",
            "{word}杯あります。",
            "{word}匹あります。",
            "{word}袋あります。"
        ],
        "连词": [
            "{word}、を使います。",
            "{word}、それとも",
            "{word}だから",
            "{word}しかし",
            "{word}そして",
            "{word}或个人",
            "{word}および",
            "{word}あるいは",
            "{word}そもそも",
            "{word}つまり"
        ],
        "感叹词": [
            "{word}ございます。",
            "{word}なくなります。",
            "{word}いたします。",
            "{word}存じます。",
            "{word}なさい。",
            "{word}ございます。",
            "{word}いたします。",
            "{word}存じます。",
            "{word}なくなります。",
            "{word}ございます。"
        ],
        "接头词": [
            "{word}見る",
            "{word}食べる",
            "{word}飲む",
            "{word}行く",
            "{word}来る",
            "{word}書く",
            "{word}読む",
            "{word}話す",
            "{word}聞く",
            "{word}買う"
        ],
        "接尾词": [
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word",
            "~$word"
        ],
        "default": [
            "これは{word}です。",
            "{word}を使います。",
            "{word}が好きです。",
            "{word}はどこですか。",
            "{word}をください。",
            "{word}は何ですか。",
            "{word}があります。",
            "{word}を使います。",
            "{word}を見てください。",
            "{word}を持っています。"
        ]
    }
    
    # 根据词性选择模板，或使用默认模板
    pos_key = part_of_speech if part_of_speech in templates else "default"
    selected_templates = templates.get(pos_key, templates["default"])
    
    # 随机选择3个不同的模板
    selected = random.sample(selected_templates, 3)
    
    # 生成3条例句
    examples = []
    for template in selected:
        example = template.format(word=word)
        examples.append(example)
    
    return examples

def process_vocabulary_file(input_file, output_file):
    """处理词汇文件，生成例句和翻译"""
    
    # 读取JSON文件
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 处理每个词汇
    primary1 = data.get("primary1", [])
    total = len(primary1)
    
    print(f"开始处理 {total} 个词汇...")
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        part_of_speech = item.get("partOfSpeech", "")
        
        # 生成3条日语例句
        japanese_examples = generate_japanese_examples(word, part_of_speech)
        
        # 翻译成中文
        chinese_examples = []
        for jp_example in japanese_examples:
            translation = translate(jp_example)
            if translation:
                chinese_examples.append(translation)
            else:
                # 如果翻译失败，使用占位符
                chinese_examples.append(f"[翻译失败] {jp_example}")
            # 避免API限流
            time.sleep(0.3)
        
        # 英文例句（简化版）
        english_examples = [
            f"This is {word}.",
            f"I use {word}.",
            f"I like {word}."
        ]
        
        # 更新item
        item["japaneseExamples"] = japanese_examples
        item["chineseExamples"] = chinese_examples
        item["englishExamples"] = english_examples
        
        # 进度提示
        if (i + 1) % 10 == 0:
            print(f"进度: {i + 1}/{total}")
    
    # 更新meta
    if "meta" in data:
        data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
        data["meta"]["counts"]["total"] = len(primary1)
    
    # 保存结果
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"处理完成！结果已保存到 {output_file}")

if __name__ == "__main__":
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_with_examples.json"
    
    process_vocabulary_file(input_file, output_file)
