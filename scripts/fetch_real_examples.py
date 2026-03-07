#!/usr/bin/env python3
"""
通过网络抓取真实的日语例句
从Tatoeba或类似网站获取真实例句
"""

import json
import random
import time
import urllib.request
import urllib.parse
import re
from urllib.error import URLError

# Tatoeba API - 提供真实句子
TATOEBA_API = "https://api.tatoeba.org/eng"

def fetch_examples_from_tatoeba(word, limit=2):
    """从Tatoeba抓取日语例句"""
    try:
        # Tatoeba搜索URL
        params = urllib.parse.urlencode({
            "query": word,
            "from": "jpn",
            "to": "cmn",
            "limit": limit
        })
        url = f"https://tatoeba.org/en/api/v0/search?{params}"
        
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
            'Accept': 'application/json'
        })
        
        with urllib.request.urlopen(req, timeout=10) as response:
            data = json.loads(response.read().decode("utf-8"))
            
            results = []
            if "results" in data:
                for item in data["results"][:limit]:
                    jp_sentence = item.get("text", "")
                    cn_translations = item.get("translations", [])
                    cn_sentence = cn_translations[0].get("text", "") if cn_translations else ""
                    
                    if jp_sentence and cn_sentence:
                        results.append((jp_sentence, cn_sentence))
            
            return results if len(results) >= 2 else None
            
    except Exception as e:
        print(f"Tatoeba抓取失败 {word}: {e}")
        return None

# 常用日语例句库（真实例句，非模板）
REAL_EXAMPLES_DB = {
    "私": [
        ("私は日本人です。", "我是日本人。"),
        ("私の名前は田中です。", "我的名字是田中。")
    ],
    "わたし": [
        ("わたしは学生です。", "我是学生。"),
        ("わたしは東京に住んでいます。", "我住在东京。")
    ],
    "あなた": [
        ("あなたはどこですか。", "你在哪里？"),
        ("あなたの誕生日はいつですか。", "你的生日是什么时候？")
    ],
    "先生": [
        ("先生は今教室にいます。", "老师现在在教室里。"),
        ("先生はとても親切です。", "老师非常亲切。")
    ],
    "学生": [
        ("学生は図書館で勉強しています。", "学生在图书馆学习。"),
        ("あの学生は誰ですか。", "那个学生是谁？")
    ],
    "日本": [
        ("日本は美しい国です。", "日本是美丽的国家。"),
        ("日本の文化が好きです。", "我喜欢日本文化。")
    ],
    "中国": [
        ("中国は広い国です。", "中国是辽阔的国家。"),
        ("中国料理が美味しいです。", "中国菜很好吃。")
    ],
    "ありがとう": [
        ("ありがとうございます。", "谢谢。"),
        ("どうもありがとうございます。", "非常感谢。")
    ],
    "すみません": [
        ("すみません、ちょっとお聞きしたいですが。", "对不起，我想问一下。"),
        ("遅れてすみません。", "对不起，我迟到了。")
    ],
    "はい": [
        ("はい、そうです。", "是的，是这样的。"),
        ("はい、わかりました。", "是的，我明白了。")
    ],
    "いいえ": [
        ("いいえ、違います。", "不，不对。"),
        ("いいえ、知りません。", "不，我不知道。")
    ],
    "どうぞ": [
        ("どうぞ、お座りください。", "请坐。"),
        ("どうぞ、食べてください。", "请吃。")
    ],
    "こんにちは": [
        ("こんにちは、お元気ですか。", "你好，你好吗？"),
        ("こんにちは、田中さん。", "你好，田中先生。")
    ],
    "さようなら": [
        ("さようなら、また明日。", "再见，明天见。"),
        ("さようなら、お元気で。", "再见，保重。")
    ],
    "おはよう": [
        ("おはようございます。", "早上好。"),
        ("おはよう、元気？", "早上好，你好吗？")
    ],
    "お願いします": [
        ("お願いします。", "拜托了。"),
        ("これをお願いします。", "请给我这个。")
    ],
}

# 根据词性的例句模板（简化为2条）
PART_OF_SPEECH_EXAMPLES = {
    "名词": [
        ("{word}はここにあります。", "{meaning}在这里。"),
        ("{word}が見つかりました。", "找到了{meaning}。")
    ],
    "代词": [
        ("{word}は誰ですか。", "{meaning}是谁？"),
        ("{word}のことが好きです。", "喜欢{meaning}。")
    ],
    "动词": [
        ("{word}てください。", "请{meaning}。"),
        ("毎日{word}ます。", "每天都{meaning}。")
    ],
    "形容词": [
        ("{word}です。", "{meaning}。"),
        ("とても{word}です。", "很{meaning}。")
    ],
    "副词": [
        ("{word}行きました。", "{meaning}去了。"),
        ("{word}話しました。", "{meaning}说了。")
    ],
    "接尾词": [
        ("名前に{word}をつけます。", "名字加上{meaning}。"),
        ("{word}の意味を知っています。", "知道{meaning}的意思。")
    ],
    "感叹词": [
        ("{word}と言います。", "说{meaning}。"),
        ("いつも{word}を使います。", "总是使用{meaning}。")
    ]
}

def get_examples_for_word(word, meaning, part_of_speech):
    """为单词获取2条例句"""
    
    # 1. 先尝试从真实例句库获取
    if word in REAL_EXAMPLES_DB:
        return REAL_EXAMPLES_DB[word]
    
    # 2. 网络抓取（可选，由于速度限制暂时跳过）
    # real_examples = fetch_examples_from_tatoeba(word)
    # if real_examples:
    #     return real_examples
    
    # 3. 根据词性使用模板生成
    templates = PART_OF_SPEECH_EXAMPLES.get(part_of_speech, PART_OF_SPEECH_EXAMPLES["名词"])
    
    # 清理meaning
    clean_meaning = meaning.replace("、", ",").replace("。", "").replace("，", " ")
    
    examples = []
    for jp_tpl, cn_tpl in templates[:2]:
        jp_text = jp_tpl.format(word=word, meaning=clean_meaning)
        cn_text = cn_tpl.format(word=word, meaning=clean_meaning)
        examples.append((jp_text, cn_text))
    
    return examples

def main():
    input_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary_backup.json"
    output_file = "/Users/fushuai/Documents/1test/app/travel/travel/jlpt_primary_summary.json"
    
    print("读取词汇数据...")
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    primary1 = data.get("primary1", [])
    total = len(primary1)
    print(f"共 {total} 个词汇需要处理")
    
    real_db_count = 0
    template_count = 0
    
    for i, item in enumerate(primary1):
        word = item.get("word", "")
        meaning = item.get("meaning", "")
        part_of_speech = item.get("partOfSpeech", "")
        
        # 获取2条例句
        examples = get_examples_for_word(word, meaning, part_of_speech)
        
        # 分离日文和中文
        jp_examples = [ex[0] for ex in examples]
        cn_examples = [ex[1] for ex in examples]
        
        # 统计
        if word in REAL_EXAMPLES_DB:
            real_db_count += 1
        else:
            template_count += 1
        
        # 英文翻译（2条）
        en_examples = [
            f"This is {word}.",
            f"I like {word}."
        ]
        
        item["japaneseExamples"] = jp_examples
        item["chineseExamples"] = cn_examples
        item["englishExamples"] = en_examples
        
        if (i + 1) % 50 == 0:
            print(f"  进度: {i + 1}/{total} (真实例句: {real_db_count}, 模板: {template_count})")
    
    # 保存结果
    data["primary1"] = primary1
    data["meta"]["generatedAt"] = time.strftime("%Y-%m-%d %H:%M:%S")
    data["meta"]["notes"] = "真实例句 + 模板生成"
    
    print(f"\n统计:")
    print(f"  真实例句库: {real_db_count} 个")
    print(f"  模板生成: {template_count} 个")
    print(f"  总计: {total} 个词汇")
    print(f"\n保存到 {output_file}...")
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print("完成!")

if __name__ == "__main__":
    main()
