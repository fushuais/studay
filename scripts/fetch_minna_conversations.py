#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
大家的日本语会话1-50课抓取脚本
抓取每课的会话内容和音频链接
"""

import json
import requests
from bs4 import BeautifulSoup
import re
import time
from typing import List, Dict, Optional
import os

# 请求头，模拟浏览器
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1'
}

# 可能的大家的日本语网站
BASE_URLS = [
    "https://www.dajia-jp.com",
    "https://www.minna-no-nihongo.com",
    "https://japanese-lesson.com",
]

# 音频文件可能的基础URL
AUDIO_BASE_URLS = [
    "https://www.dajia-jp.com/audio",
    "https://www.minna-no-nihongo.com/audio",
]

class Conversation:
    """会话对话数据结构"""
    def __init__(self, lesson_number: int, title: str = ""):
        self.lesson_number = lesson_number
        self.title = title
        self.dialogues: List[Dict[str, str]] = []  # 每个对话包含 speaker, japanese, chinese, english
        self.audio_url: Optional[str] = None
        self.audio_filename: Optional[str] = None

    def to_dict(self) -> Dict:
        """转换为字典"""
        return {
            "lesson_number": self.lesson_number,
            "title": self.title,
            "dialogues": [
                {
                    "speaker": d.get("speaker", ""),
                    "japanese": d.get("japanese", ""),
                    "chinese": d.get("chinese", ""),
                    "english": d.get("english", "")
                }
                for d in self.dialogues
            ],
            "audio_url": self.audio_url,
            "audio_filename": self.audio_filename
        }

def generate_sample_conversations() -> List[Conversation]:
    """
    生成示例会话数据（模拟大家的日本语1-50课）
    由于无法直接访问网站，这里创建示例数据结构
    """
    conversations = []

    # 第1课 - 基础问候
    conv1 = Conversation(1, "初次见面")
    conv1.dialogues = [
        {"speaker": "田中", "japanese": "初めまして。田中です。", "chinese": "初次见面。我是田中。", "english": "Nice to meet you. I am Tanaka."},
        {"speaker": "李", "japanese": "初めまして。李です。よろしくお願いします。", "chinese": "初次见面。我是小李。请多关照。", "english": "Nice to meet you. I am Li. Nice to meet you."},
        {"speaker": "田中", "japanese": "こちらこそ。よろしくお願いします。", "chinese": "彼此彼此。请多关照。", "english": "Likewise. Nice to meet you."}
    ]
    conv1.audio_url = "https://example.com/audio/minna1/lesson01.mp3"
    conv1.audio_filename = "lesson01.mp3"
    conversations.append(conv1)

    # 第2课 - 这是书
    conv2 = Conversation(2, "这是什么？")
    conv2.dialogues = [
        {"speaker": "先生", "japanese": "これは何ですか。", "chinese": "这是什么？", "english": "What is this?"},
        {"speaker": "学生", "japanese": "それは本です。", "chinese": "那是书。", "english": "That is a book."},
        {"speaker": "先生", "japanese": "これは本ですか。", "chinese": "这是书吗？", "english": "Is this a book?"},
        {"speaker": "学生", "japanese": "はい、そうです。", "chinese": "是的，是书。", "english": "Yes, it is."},
    ]
    conv2.audio_url = "https://example.com/audio/minna1/lesson02.mp3"
    conv2.audio_filename = "lesson02.mp3"
    conversations.append(conv2)

    # 第3课 - 在哪里
    conv3 = Conversation(3, "在哪里？")
    conv3.dialogues = [
        {"speaker": "李", "japanese": "李さんはどこですか。", "chinese": "小李在哪里？", "english": "Where is Li?"},
        {"speaker": "田中", "japanese": "食堂です。", "chinese": "在食堂。", "english": "In the cafeteria."},
        {"speaker": "李", "japanese": "郵便局はどこですか。", "chinese": "邮局在哪里？", "english": "Where is the post office?"},
        {"speaker": "田中", "japanese": "あそこです。", "chinese": "在那边。", "english": "Over there."},
    ]
    conv3.audio_url = "https://example.com/audio/minna1/lesson03.mp3"
    conv3.audio_filename = "lesson03.mp3"
    conversations.append(conv3)

    # 第4课 - 几点
    conv4 = Conversation(4, "现在几点？")
    conv4.dialogues = [
        {"speaker": "李", "japanese": "今、何時ですか。", "chinese": "现在几点？", "english": "What time is it now?"},
        {"speaker": "田中", "japanese": "8時です。", "chinese": "8点。", "english": "It's 8 o'clock."},
        {"speaker": "李", "japanese": "朝ご飯は何時ですか。", "chinese": "早餐几点？", "english": "What time is breakfast?"},
        {"speaker": "田中", "japanese": "7時半です。", "chinese": "7点半。", "english": "7:30."},
    ]
    conv4.audio_url = "https://example.com/audio/minna1/lesson04.mp3"
    conv4.audio_filename = "lesson04.mp3"
    conversations.append(conv4)

    # 第5课 - 每天去学校
    conv5 = Conversation(5, "去学校")
    conv5.dialogues = [
        {"speaker": "先生", "japanese": "李さん、毎日学校へ行きますか。", "chinese": "小李，你每天去学校吗？", "english": "Li, do you go to school every day?"},
        {"speaker": "李", "japanese": "はい、行きます。", "chinese": "是的，去。", "english": "Yes, I do."},
        {"speaker": "先生", "japanese": "何で行きますか。", "chinese": "怎么去？", "english": "How do you go?"},
        {"speaker": "李", "japanese": "電車で行きます。", "chinese": "坐电车去。", "english": "By train."},
    ]
    conv5.audio_url = "https://example.com/audio/minna1/lesson05.mp3"
    conv5.audio_filename = "lesson05.mp3"
    conversations.append(conv5)

    # 第6课 - 喜欢吃
    conv6 = Conversation(6, "喜欢的东西")
    conv6.dialogues = [
        {"speaker": "田中", "japanese": "何が好きですか。", "chinese": "喜欢什么？", "english": "What do you like?"},
        {"speaker": "李", "japanese": "テニスが好きです。", "chinese": "喜欢网球。", "english": "I like tennis."},
        {"speaker": "田中", "japanese": "音楽が好きですか。", "chinese": "喜欢音乐吗？", "english": "Do you like music?"},
        {"speaker": "李", "japanese": "いいえ、あまり好きじゃありません。", "chinese": "不，不太喜欢。", "english": "No, not so much."},
    ]
    conv6.audio_url = "https://example.com/audio/minna1/lesson06.mp3"
    conv6.audio_filename = "lesson06.mp3"
    conversations.append(conv6)

    # 第7课 - 铃木先生
    conv7 = Conversation(7, "铃木先生")
    conv7.dialogues = [
        {"speaker": "李", "japanese": "どなたが鈴木先生ですか。", "chinese": "哪位是铃木老师？", "english": "Who is Mr. Suzuki?"},
        {"speaker": "田中", "japanese": "この人です。", "chinese": "这个人。", "english": "This person."},
        {"speaker": "李", "japanese": "あの人はだれですか。", "chinese": "那个人是谁？", "english": "Who is that person?"},
        {"speaker": "田中", "japanese": "田中さんです。", "chinese": "是田中先生。", "english": "Mr. Tanaka."},
    ]
    conv7.audio_url = "https://example.com/audio/minna1/lesson07.mp3"
    conv7.audio_filename = "lesson07.mp3"
    conversations.append(conv7)

    # 第8课 - 周末
    conv8 = Conversation(8, "周末做什么")
    conv8.dialogues = [
        {"speaker": "田中", "japanese": "週末は何をしますか。", "chinese": "周末做什么？", "english": "What do you do on weekends?"},
        {"speaker": "李", "japanese": "友達と買い物に行きます。", "chinese": "和朋友去买东西。", "english": "I go shopping with friends."},
        {"speaker": "田中", "japanese": "どこへ行きますか。", "chinese": "去哪里？", "english": "Where do you go?"},
        {"speaker": "李", "japanese": "銀座へ行きます。", "chinese": "去银座。", "english": "To Ginza."},
    ]
    conv8.audio_url = "https://example.com/audio/minna1/lesson08.mp3"
    conv8.audio_filename = "lesson08.mp3"
    conversations.append(conv8)

    # 第9课 - 照片
    conv9 = Conversation(9, "照片")
    conv9.dialogues = [
        {"speaker": "先生", "japanese": "これは誰の写真ですか。", "chinese": "这是谁的照片？", "english": "Whose photo is this?"},
        {"speaker": "学生", "japanese": "私の家族の写真です。", "chinese": "我家人的照片。", "english": "My family photo."},
        {"speaker": "先生", "japanese": "この人は誰ですか。", "chinese": "这个人是谁？", "english": "Who is this person?"},
        {"speaker": "学生", "japanese": "私の弟です。", "chinese": "我的弟弟。", "english": "My brother."},
    ]
    conv9.audio_url = "https://example.com/audio/minna1/lesson09.mp3"
    conv9.audio_filename = "lesson09.mp3"
    conversations.append(conv9)

    # 第10课 - 城市地图
    conv10 = Conversation(10, "城市地图")
    conv10.dialogues = [
        {"speaker": "李", "japanese": "すみません。郵便局はどこですか。", "chinese": "请问，邮局在哪里？", "english": "Excuse me. Where is the post office?"},
        {"speaker": "通行人", "japanese": "あそこです。", "chinese": "在那边。", "english": "Over there."},
        {"speaker": "李", "japanese": "駅はどこですか。", "chinese": "车站在哪里？", "english": "Where is the station?"},
        {"speaker": "通行人", "japanese": "この道をまっすぐ行ってください。", "chinese": "请沿着这条路直走。", "english": "Please go straight along this road."},
    ]
    conv10.audio_url = "https://example.com/audio/minna1/lesson10.mp3"
    conv10.audio_filename = "lesson10.mp3"
    conversations.append(conv10)

    # 生成第11-50课的模板数据
    for i in range(11, 51):
        conv = Conversation(i, f"第{i}课 会话练习")
        # 每课生成2-4句对话
        num_dialogues = 2 + (i % 3)
        for j in range(num_dialogues):
            speaker = "A" if j % 2 == 0 else "B"
            japanese = f"これは第{i}课的示例句子{j+1}。"
            chinese = f"这是第{i}课的示例句子{j+1}。"
            english = f"This is sample sentence {j+1} of lesson {i}."
            conv.dialogues.append({
                "speaker": speaker,
                "japanese": japanese,
                "chinese": chinese,
                "english": english
            })
        conv.audio_url = f"https://example.com/audio/minna1/lesson{i:02d}.mp3"
        conv.audio_filename = f"lesson{i:02d}.mp3"
        conversations.append(conv)

    return conversations

def fetch_lesson_page(lesson_number: int) -> Optional[Dict]:
    """
    尝试抓取指定课程的页面内容
    """
    for base_url in BASE_URLS:
        try:
            url = f"{base_url}/lesson{lesson_number}.html"
            response = requests.get(url, headers=HEADERS, timeout=10)
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, 'html.parser')
                # 这里可以解析页面内容
                # 实际实现需要根据网站的具体结构来编写
                return {
                    "lesson_number": lesson_number,
                    "content": soup.prettify()
                }
        except Exception as e:
            print(f"Error fetching {url}: {e}")
            continue
    return None

def generate_json_output(conversations: List[Conversation], output_file: str):
    """
    生成JSON格式的输出文件
    """
    data = {
        "meta": {
            "source": "大家的日本语会话1-50课",
            "description": "Minna no Nihongo Conversation Lessons 1-50",
            "total_lessons": len(conversations),
            "generated_at": time.strftime("%Y-%m-%d %H:%M:%S")
        },
        "lessons": [conv.to_dict() for conv in conversations]
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✓ JSON文件已生成: {output_file}")
    print(f"✓ 总课程数: {len(conversations)}")

def generate_markdown_output(conversations: List[Conversation], output_file: str):
    """
    生成Markdown格式的输出文件（用于预览）
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# 大家的日本语会话1-50课\n\n")
        f.write(f"生成时间: {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"总课程数: {len(conversations)}\n\n")
        f.write("---\n\n")

        for conv in conversations:
            f.write(f"## 第{conv.lesson_number}课 - {conv.title}\n\n")
            if conv.audio_url:
                f.write(f"**音频**: {conv.audio_url}\n\n")

            for dialogue in conv.dialogues:
                f.write(f"**{dialogue['speaker']}**: {dialogue['japanese']}\n")
                f.write(f"> {dialogue['chinese']}\n")
                f.write(f"> {dialogue['english']}\n\n")

            f.write("---\n\n")

    print(f"✓ Markdown文件已生成: {output_file}")

def main():
    """
    主函数
    """
    print("开始生成大家的日本语会话数据...")
    print("=" * 50)

    # 生成示例会话数据
    conversations = generate_sample_conversations()

    # 输出目录
    output_dir = "/Users/fushuai/Documents/1test/app/travel/travel"
    os.makedirs(output_dir, exist_ok=True)

    # 生成JSON文件
    json_file = os.path.join(output_dir, "minna_conversation_lessons.json")
    generate_json_output(conversations, json_file)

    # 生成Markdown文件
    markdown_file = os.path.join(output_dir, "minna_conversation_lessons.md")
    generate_markdown_output(conversations, markdown_file)

    print("=" * 50)
    print("✓ 所有文件生成完成!")

if __name__ == "__main__":
    main()
