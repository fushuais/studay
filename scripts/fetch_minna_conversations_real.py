#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
大家的日本语会话抓取脚本 - 网站实际抓取版本
用于从实际的大家的日本语网站抓取1-50课的会话内容和音频链接

使用说明：
1. 确保已安装依赖：pip install requests beautifulsoup4 lxml
2. 运行脚本：python3 fetch_minna_conversations_real.py
3. 输出文件将保存在 travel/ 目录下

注意：
- 需要根据实际网站结构调整解析逻辑
- 音频文件可能需要单独下载
- 建议设置合理的请求间隔，避免对服务器造成压力
"""

import json
import requests
from bs4 import BeautifulSoup
import re
import time
import os
from typing import List, Dict, Optional
from urllib.parse import urljoin, urlparse
import html

# 请求头配置
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,ja;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Referer': 'https://www.google.com/',
}

# 常见的大家的日本语相关网站（需要确认实际可用的网站）
POTENTIAL_SITES = [
    {
        'name': '大家的日本语官网',
        'base_url': 'https://www.dajia-jp.com',
        'lesson_url_pattern': '/lesson{:02d}.html'
    },
    {
        'name': 'Minna no Nihongo Official',
        'base_url': 'https://www.minna-no-nihongo.com',
        'lesson_url_pattern': '/lessons/{:02d}'
    },
    {
        'name': 'Japanese Lesson',
        'base_url': 'https://japanese-lesson.com',
        'lesson_url_pattern': '/minna/lesson{:02d}'
    },
    {
        'name': '日语学习网',
        'base_url': 'https://www.japanese-learning.com',
        'lesson_url_pattern': '/minna/{:02d}'
    }
]

# 请求间隔（秒）
REQUEST_DELAY = 1

class ConversationScraper:
    """会话抓取器"""

    def __init__(self, site_config: Dict):
        self.base_url = site_config['base_url']
        self.lesson_url_pattern = site_config['lesson_url_pattern']
        self.session = requests.Session()
        self.session.headers.update(HEADERS)

    def fetch_page(self, url: str) -> Optional[str]:
        """
        获取页面内容
        """
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            response.encoding = response.apparent_encoding
            return response.text
        except Exception as e:
            print(f"❌ 获取页面失败 {url}: {e}")
            return None

    def parse_lesson_page(self, lesson_number: int, html_content: str) -> Optional[Dict]:
        """
        解析课程页面，提取会话内容和音频链接
        这是一个模板方法，需要根据实际网站结构进行修改
        """
        soup = BeautifulSoup(html_content, 'lxml')

        # 尝试不同的选择器模式
        # 1. 查找会话标题
        title_selectors = [
            'h1.lesson-title',
            'h1.title',
            '.lesson-title h1',
            '.title',
            'h2:first-of-type'
        ]

        title = f"第{lesson_number}课"
        for selector in title_selectors:
            element = soup.select_one(selector)
            if element:
                title = element.get_text(strip=True)
                break

        # 2. 查找会话对话
        dialogues = []
        dialogue_selectors = [
            '.dialogue .line',
            '.conversation .line',
            '.kaiwa .line',
            '.kaigi .line',
            'div.dialogue',
            'div.conversation'
        ]

        for selector in dialogue_selectors:
            elements = soup.select(selector)
            if elements:
                for element in elements:
                    dialogue = self._parse_dialogue_element(element)
                    if dialogue:
                        dialogues.append(dialogue)
                if dialogues:  # 如果找到了对话，就不再尝试其他选择器
                    break

        # 如果没有找到对话，尝试其他格式
        if not dialogues:
            dialogues = self._parse_alternative_dialogue_format(soup)

        # 3. 查找音频链接
        audio_url = None
        audio_filename = None

        audio_selectors = [
            'audio source',
            '.audio-player source',
            'a[href$=".mp3"]',
            'a[href$=".m4a"]',
            'a.audio-link'
        ]

        for selector in audio_selectors:
            element = soup.select_one(selector)
            if element:
                href = element.get('src') or element.get('href')
                if href:
                    audio_url = urljoin(self.base_url, href)
                    audio_filename = os.path.basename(urlparse(href).path)
                    break

        return {
            "lesson_number": lesson_number,
            "title": title,
            "dialogues": dialogues,
            "audio_url": audio_url,
            "audio_filename": audio_filename
        }

    def _parse_dialogue_element(self, element) -> Optional[Dict]:
        """
        解析单个对话元素
        """
        try:
            # 尝试提取说话者
            speaker_selectors = ['.speaker', '.name', '.role', 'span.speaker']
            speaker = ""
            for selector in speaker_selectors:
                speaker_elem = element.select_one(selector)
                if speaker_elem:
                    speaker = speaker_elem.get_text(strip=True)
                    break

            # 尝试提取日语
            japanese_selectors = ['.japanese', '.ja', '.jp', 'p.japanese']
            japanese = ""
            for selector in japanese_selectors:
                jp_elem = element.select_one(selector)
                if jp_elem:
                    japanese = jp_elem.get_text(strip=True)
                    break

            # 尝试提取中文翻译
            chinese_selectors = ['.chinese', '.zh', '.cn', 'p.chinese']
            chinese = ""
            for selector in chinese_selectors:
                cn_elem = element.select_one(selector)
                if cn_elem:
                    chinese = cn_elem.get_text(strip=True)
                    break

            # 尝试提取英文翻译
            english_selectors = ['.english', '.en', 'p.english']
            english = ""
            for selector in english_selectors:
                en_elem = element.select_one(selector)
                if en_elem:
                    english = en_elem.get_text(strip=True)
                    break

            # 如果没有找到特定类名，尝试从文本中提取
            if not japanese:
                text = element.get_text(strip=True)
                # 这里可以添加更复杂的文本解析逻辑
                japanese = text

            return {
                "speaker": speaker,
                "japanese": japanese,
                "chinese": chinese,
                "english": english
            }
        except Exception as e:
            print(f"⚠️  解析对话元素失败: {e}")
            return None

    def _parse_alternative_dialogue_format(self, soup) -> List[Dict]:
        """
        尝试解析其他格式的对话
        """
        dialogues = []

        # 尝试查找包含日语和中文的段落
        paragraphs = soup.find_all('p')
        for p in paragraphs:
            text = p.get_text(strip=True)
            # 如果段落同时包含日文和中文字符
            if self._contains_japanese(text) and self._contains_chinese(text):
                # 这里可以添加更智能的分割逻辑
                dialogue = {
                    "speaker": "",
                    "japanese": text,
                    "chinese": "",
                    "english": ""
                }
                dialogues.append(dialogue)

        return dialogues

    def _contains_japanese(self, text: str) -> bool:
        """检查是否包含日文字符"""
        return bool(re.search(r'[\u3040-\u309F\u30A0-\u30FF]', text))

    def _contains_chinese(self, text: str) -> bool:
        """检查是否包含中文字符"""
        return bool(re.search(r'[\u4E00-\u9FFF]', text))

    def scrape_lesson(self, lesson_number: int) -> Optional[Dict]:
        """
        抓取指定课程
        """
        lesson_url = self.base_url + self.lesson_url_pattern.format(lesson_number)
        print(f"📖 抓取第{lesson_number}课: {lesson_url}")

        html_content = self.fetch_page(lesson_url)
        if not html_content:
            return None

        lesson_data = self.parse_lesson_page(lesson_number, html_content)

        # 添加请求延迟
        time.sleep(REQUEST_DELAY)

        return lesson_data

    def scrape_all_lessons(self, start: int = 1, end: int = 50) -> List[Dict]:
        """
        抓取所有课程
        """
        lessons = []

        for lesson_number in range(start, end + 1):
            lesson_data = self.scrape_lesson(lesson_number)
            if lesson_data:
                lessons.append(lesson_data)
                print(f"✓ 第{lesson_number}课抓取成功")
            else:
                print(f"✗ 第{lesson_number}课抓取失败")
                # 创建占位数据
                lessons.append(self._create_placeholder_lesson(lesson_number))

        return lessons

    def _create_placeholder_lesson(self, lesson_number: int) -> Dict:
        """
        创建占位课程数据
        """
        return {
            "lesson_number": lesson_number,
            "title": f"第{lesson_number}课（未抓取到数据）",
            "dialogues": [
                {
                    "speaker": "A",
                    "japanese": f"これは第{lesson_number}课の例文です。",
                    "chinese": f"这是第{lesson_number}课的例句。",
                    "english": f"This is a sample sentence from lesson {lesson_number}."
                }
            ],
            "audio_url": None,
            "audio_filename": None
        }

def generate_json_output(lessons: List[Dict], output_file: str, site_name: str):
    """
    生成JSON格式输出
    """
    data = {
        "meta": {
            "source": site_name,
            "description": "Minna no Nihongo Conversation Lessons 1-50",
            "total_lessons": len(lessons),
            "generated_at": time.strftime("%Y-%m-%d %H:%M:%S")
        },
        "lessons": lessons
    }

    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"✓ JSON文件已生成: {output_file}")
    print(f"✓ 总课程数: {len(lessons)}")

def main():
    """
    主函数
    """
    print("=" * 60)
    print("大家的日本语会话抓取脚本")
    print("=" * 60)

    # 测试所有可能的网站
    successful_site = None
    scraper = None

    for site_config in POTENTIAL_SITES:
        print(f"\n🔍 测试网站: {site_config['name']}")
        scraper = ConversationScraper(site_config)

        # 测试访问主页
        test_url = site_config['base_url']
        print(f"📍 测试URL: {test_url}")

        html_content = scraper.fetch_page(test_url)
        if html_content:
            print(f"✓ 网站可访问")
            successful_site = site_config
            break
        else:
            print(f"✗ 网站无法访问")

    if not successful_site:
        print("\n❌ 所有网站均无法访问，使用占位数据")
        scraper = ConversationScraper(POTENTIAL_SITES[0])

    print(f"\n🚀 开始抓取课程...")
    print("=" * 60)

    # 抓取1-50课
    lessons = scraper.scrape_all_lessons(start=1, end=50)

    # 统计结果
    successful_lessons = [l for l in lessons if l.get('dialogues') and len(l['dialogues']) > 1]
    print(f"\n📊 抓取统计:")
    print(f"   总课程数: {len(lessons)}")
    print(f"   成功抓取: {len(successful_lessons)}")

    # 输出目录
    output_dir = "/Users/fushuai/Documents/1test/app/travel/travel"
    os.makedirs(output_dir, exist_ok=True)

    # 生成JSON文件
    json_file = os.path.join(output_dir, "minna_conversation_lessons.json")
    generate_json_output(lessons, json_file, successful_site['name'] if successful_site else "占位数据")

    print("=" * 60)
    print("✓ 抓取完成!")

if __name__ == "__main__":
    main()
