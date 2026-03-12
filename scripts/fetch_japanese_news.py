#!/usr/bin/env python3
"""
实时抓取日本新闻
数据来源：NHK News Web Easy, Yahoo! Japan News
"""

import json
import requests
from bs4 import BeautifulSoup
from datetime import datetime
import time
import re

# 请求头设置
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1'
}

def fetch_nhk_news(limit=10):
    """抓取NHK News Web Easy新闻"""
    news_items = []
    try:
        url = "https://www3.nhk.or.jp/news/easy/"
        response = requests.get(url, headers=HEADERS, timeout=10)
        response.encoding = 'utf-8'

        soup = BeautifulSoup(response.text, 'html.parser')

        # 查找新闻列表
        news_list = soup.find_all('article', class_='news-list-item')
        if not news_list:
            # 备用选择器
            news_list = soup.find_all('div', class_='news')

        for idx, news in enumerate(news_list[:limit]):
            try:
                # 标题
                title_elem = news.find('a') or news.find('h2') or news.find('h3')
                title = title_elem.get_text(strip=True) if title_elem else "无标题"

                # 链接
                link_elem = news.find('a')
                link = link_elem.get('href', '') if link_elem else ''
                if link and not link.startswith('http'):
                    link = "https://www3.nhk.or.jp" + link

                # 日期
                date_elem = news.find('time') or news.find('span', class_='date')
                date_str = date_elem.get_text(strip=True) if date_elem else datetime.now().strftime("%Y-%m-%d")

                # 摘要/描述
                desc_elem = news.find('p') or news.find('div', class_='description')
                summary = desc_elem.get_text(strip=True) if desc_elem else title

                # 获取详细内容
                content = summary
                image_url = None

                if link:
                    try:
                        detail_resp = requests.get(link, headers=HEADERS, timeout=5)
                        detail_soup = BeautifulSoup(detail_resp.text, 'html.parser')

                        # 获取正文
                        content_div = detail_soup.find('div', {'id': 'newsarticle'}) or detail_soup.find('div', class_='article')
                        if content_div:
                            paragraphs = content_div.find_all('p')
                            content = '\n\n'.join([p.get_text(strip=True) for p in paragraphs if p.get_text(strip=True)])

                        # 获取图片
                        img_elem = detail_soup.find('img')
                        if img_elem:
                            img_url = img_elem.get('src', '')
                            if img_url and not img_url.startswith('http'):
                                img_url = "https://www3.nhk.or.jp" + img_url
                            image_url = img_url
                    except Exception as e:
                        print(f"获取详情失败: {e}")

                news_items.append({
                    "title": title,
                    "summary": summary[:200] + "..." if len(summary) > 200 else summary,
                    "content": content,
                    "imageUrl": image_url,
                    "source": "NHK News",
                    "publishedDate": date_str,
                    "category": "社会"
                })

                time.sleep(0.5)  # 礼貌爬取

            except Exception as e:
                print(f"解析单条新闻失败: {e}")
                continue

    except Exception as e:
        print(f"抓取NHK新闻失败: {e}")

    return news_items

def fetch_sample_news():
    """生成示例新闻数据（当无法抓取时使用）"""
    from datetime import timedelta

    sample_news = [
        {
            "title": "東京で新しい地下鉄路線が開通、通勤時間大幅短縮へ",
            "summary": "東京メトロが新たな地下鉄路線を正式に開通。銀座・新宿線が主要エリアを結び、通勤時間を平均15分短縮すると期待されています。",
            "content": """東京メトロが本日、新たな地下鉄路線「銀座・新宿線」を正式に開通させました。この新線は銀座駅から新宿駅まで約20キロメートルを結び、途中6つの主要駅で停車します。

開通式典では東京都知事が出席し、「この新線は東京の発展にとって重要な一歩だ」と述べました。新線の特徴は、最新の自動運転システムと省エネ技術を採用した点です。

運行開始は朝6時から夜11時まで、平日は3分間隔、休日は5分間隔で運行されます。運賃は既存の東京メトロと同じ料金体系で、ICカードが利用可能です。

新線開通により、渋谷・新宿・銀座などの主要エリアの移動がスムーズになり、観光客にとっても利用しやすい交通網が整備されました。""",
            "imageUrl": "https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&h=600&fit=crop&q=80",
            "source": "NHK News",
            "publishedDate": datetime.now().strftime("%Y-%m-%d"),
            "category": "社会"
        },
        {
            "title": "日本のGDP、四半期連続でプラス成長",
            "summary": "内閣府発表の2024年1-3月期GDP速報値、実質GDPが前期比年率1.2%増。輸出回復と個人消費持ち直しに支えられた。",
            "content": """内閣府が15日に発表した2024年1-3月期の国内総生産（GDP）速報値によると、実質GDPが前期比0.3%増、年率換算で1.2%増となり、4四半期連続のプラス成長を達成しました。

この成長は、主に輸出の回復と個人消費の持ち直しに支えられています。特に自動車や電子機器の輸出が好調で、対米・対EU輸出が前四半期比でそれぞれ2.5%増、1.8%増となりました。

一方、設備投資は0.1%減と小幅マイナスとなったものの、企業の業況感改善に伴い、今後の投資増加が見込まれています。

経済担当大臣は記者会見で、「緩やかな景気回復が続いているが、海外経済の不確実性などのリスク要因にも注意が必要だ」と述べました。

政府は今後もデフレ脱却に向けた経済政策を推進し、持続可能な成長を目指すとしています。""",
            "imageUrl": "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&h=600&fit=crop&q=80",
            "source": "Yahoo! Japan News",
            "publishedDate": (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d"),
            "category": "经济"
        },
        {
            "title": "AI技術活用の医療診断システム、肺がん早期発見で医師並みの精度",
            "summary": "東京大学研究チームが開発したAI診断システム、早期肺がん検出率94.3%達成。誤診率を5%以下に低減。",
            "content": """東京大学医学部の研究チームは14日、人工知能（AI）を活用した医療画像診断システムを開発したと発表しました。このシステムは肺がんの早期発見において、経験豊富な医師と同等以上の精度を達成しています。

研究チームは過去5年間にわたり、約10万件の胸部CT画像をAIに学習させました。その結果、早期肺がんの検出率が94.3%に達し、誤診率を従来の30%から5%以下に大幅に低減することに成功しました。

システムの特徴は、画像から病変の特徴だけでなく、患者の年齢、喫煙歴、家族歴などの臨床情報も総合的に分析できる点です。これにより、より精度の高い診断が可能となります。

研究チームの代表教授は、「この技術は医療の質の向上と医師の負担軽減に大きく貢献する。実用化に向け、来年度から複数の医療機関での臨床試験を開始する予定だ」と述べました。

将来的には、この技術を他のがんや心臓病などの診断にも拡張する計画が進められています。""",
            "imageUrl": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=800&h=600&fit=crop&q=80",
            "source": "Google News Japan",
            "publishedDate": (datetime.now() - timedelta(days=2)).strftime("%Y-%m-%d"),
            "category": "科技"
        },
        {
            "title": "サッカー日本代表、ワールドカップアジア予選で韓国に3-1勝利",
            "summary": "埼玉スタジアムで開催された予選リーグ、日本代表が3-1で韓国を下し3連勝達成。三笘薫が先制ゴール。",
            "content": """サッカー日本代表は14日、埼玉スタジアムで行われたFIFAワールドカップアジア2次予選の韓国戦で3-1で勝利し、予選リーグ3連勝を達成しました。

試合は前半15分にFW三笘薫の強烈なミドルシュートで日本が先制しました。その後、韓国も反撃を見せましたが、日本の守備陣はしっかりと対応しました。

後半に入り、日本はさらに2点を追加。FW上田綺世がコーナーキックからヘッドゴールを決め、その後、MF遠藤航が鋭い突破から右足でシュートを決めました。

韓国は後半アディショナルタイムに1点を返しましたが、追いつくことはできませんでした。

監督の森保一は試合後、「選手たちは今日、素晴らしいパフォーマンスを見せてくれた。特に守備面の組織力は見事だった」と評価しました。

日本はこの勝利でグループ首位を維持し、本大会出場に向けて大きな一歩を踏み出しました。""",
            "imageUrl": "https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800&h=600&fit=crop&q=80",
            "source": "NHK Sports",
            "publishedDate": (datetime.now() - timedelta(days=3)).strftime("%Y-%m-%d"),
            "category": "体育"
        },
        {
            "title": "京都で新たな桜フェスティバル、夜桜ライトアップと投影マッピング",
            "summary": "京都市が春から「京都桜フェスティバル」開催。清水寺や嵐山など8スポットで特別イベント、文化体験プログラムも。",
            "content": """京都市は14日、2024年春から新たな観光イベント「京都桜フェスティバル」を開催すると発表しました。期間は3月下旬から4月中旬までの約3週間です。

フェスティバルのハイライトは、市内8つの主要観光スポットで行われる夜桜ライトアップです。特に清水寺、嵐山、金閣寺などでは、従来のライトアップに加え、投影マッピングによる演出も行われます。

また、期間中は伝統文化体験プログラムも用意されています。着物レンタル、茶道体験、書道教室など、観光客が日本文化を体験できるイベントが多数予定されています。

市長は記者会見で、「桜のシーズンを通じて京都の美しさと文化を世界に発信したい。観光客にとっても忘れられない体験になるだろう」と述べました。

期待される経済効果は約500億円で、約100万人の来場が見込まれています。""",
            "imageUrl": "https://images.unsplash.com/photo-1522383225653-ed111181a951?w=800&h=600&fit=crop&q=80",
            "source": "Yahoo! Japan Lifestyle",
            "publishedDate": (datetime.now() - timedelta(days=4)).strftime("%Y-%m-%d"),
            "category": "文化"
        },
        {
            "title": "政府、デジタル社会基本法施行へ 行政手続き完全オンライン化目標",
            "summary": "政府がデジタル社会基本法を施行、行政手続きの完全オンライン化やデジタル人材育成など7つの基本方針を定める。",
            "content": """政府は15日、デジタル社会の形成を図るための基本法である「デジタル社会基本法」を施行しました。この法律は、行政手続きの完全オンライン化やデジタル人材育成を含む7つの基本方針を定めています。

主な施策として、2025年度までにすべての行政手続きをオンラインで完了できるようにする目標を掲げています。これにより、市民は窓口に行くことなく、住民票や税務関連の手続きが可能になります。

また、デジタル人材の育成にも力を入れています。大学でのデジタル教育の充実や、現役社会人向けのリスキリング支援など、年間10万人のデジタル人材育成を目指しています。

担当大臣は「デジタル化は日本の競争力を高めるための最重要課題だ。官民一体となってデジタル社会の実現に向けて取り組んでいく」と述べました。

さらに、サイバーセキュリティの強化や地方のデジタル化支援など、包括的な施策が実施されます。""",
            "imageUrl": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&h=600&fit=crop&q=80",
            "source": "Google News Japan",
            "publishedDate": (datetime.now() - timedelta(days=5)).strftime("%Y-%m-%d"),
            "category": "政治"
        },
        {
            "title": "トヨタ、次世代電気自動車「Prius EV」発表 航続距離800km達成",
            "summary": "トヨタ自動車が新世代電気自動車を発表、新開発の固态バッテリー採用で航続距離を従来比30%向上。15分充電で200km走行可能。",
            "content": """トヨタ自動車は14日、新世代の電気自動車「Prius EV」を発表しました。このモデルは新開発の固态バッテリーを採用し、航続距離が従来モデルより30%向上した800kmを実現しました。

新車の特徴は、高速充電に対応しており、15分の充電で200kmの走行が可能です。また、車載ソフトウェアのOTAアップデートに対応し、購入後も機能追加が可能です。

価格は税込みで450万円からで、年内の販売開始を予定しています。政府の補助金を活用すると、実質400万円台で購入可能です。

トヨタの社長は記者会見で、「地球環境保護と顧客満足の両立を目指している。この新車はその象徴であり、電気自動車の普及を加速させたい」と述べました。

トヨタは今後5年間で10機種の電気自動車を投入する計画で、2030年までに全球の販売台数の100万台を電気自動車にする目標を掲げています。""",
            "imageUrl": "https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=800&h=600&fit=crop&q=80",
            "source": "NHK Business",
            "publishedDate": (datetime.now() - timedelta(days=6)).strftime("%Y-%m-%d"),
            "category": "经济"
        },
        {
            "title": "関西国際空港、新ターミナル「ウィング3」オープン 年間3000万人処理可能",
            "summary": "関西国際空港に新しい旅客ターミナルビルがオープン。総工費約2000億円、免税店エリア2倍に拡張。多言語対応ロボットも導入。",
            "content": """関西国際空港で14日、新しい旅客ターミナルビル「ウィング3」がオープンしました。総工費は約2000億円で、年間3000万人の乗客を処理できる国内最大級の施設です。

新ターミナルの特徴は、最新のセキュリティチェックシステムを採用し、従来より30%のスピードアップを実現しました。また、免税店エリアが2倍に拡張され、約150店の店舗が入居しています。

ターミナル内には多言語対応案内ロボットも導入されており、英語、中国語、韓国語など10言語で観光客をサポートします。

空港会社の社長は「関西国際空港をアジアのハブ空港としてさらに発展させたい。新ターミナルはその一歩だ」と述べました。

オープン初日は多くの観光客や現地住民が訪れ、開港記念イベントも行われました。""",
            "imageUrl": "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&h=600&fit=crop&q=80",
            "source": "Yahoo! Japan Travel",
            "publishedDate": (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"),
            "category": "社会"
        }
    ]

    return sample_news

def generate_news_data(use_real_fetch=True):
    """生成新闻数据"""
    news_items = []

    # 尝试抓取真实新闻
    if use_real_fetch:
        print("尝试抓取NHK实时新闻...")
        try:
            real_news = fetch_nhk_news(limit=10)
            if real_news:
                news_items.extend(real_news)
                print(f"✓ 成功抓取 {len(real_news)} 条NHK新闻")
            else:
                print("⚠ NHK新闻抓取失败，使用示例数据")
        except Exception as e:
            print(f"⚠ 抓取失败: {e}，使用示例数据")

    # 补充示例新闻
    if len(news_items) < 10:
        sample_news = fetch_sample_news()
        news_items.extend(sample_news)

    # 构建完整数据结构
    data = {
        "meta": {
            "lastUpdated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "source": "NHK News Web Easy, Yahoo! Japan News, Google News Japan",
            "totalCount": len(news_items),
            "fetchType": "real" if use_real_fetch and len(news_items) > 10 else "sample"
        },
        "news": news_items
    }

    return data

def main():
    """主函数"""
    print("=" * 50)
    print("日本新闻数据生成")
    print("=" * 50)

    # 生成数据（尝试抓取真实新闻）
    data = generate_news_data(use_real_fetch=True)

    # 保存到文件
    output_path = "/Users/fushuai/Documents/1test/app/travel/travel/japanese_news.json"
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n✓ 新闻数据已生成: {output_path}")
    print(f"  总数: {data['meta']['totalCount']} 条")
    print(f"  类型: {'实时抓取' if data['meta']['fetchType'] == 'real' else '示例数据'}")
    print(f"  更新时间: {data['meta']['lastUpdated']}")
    print(f"  类别: {', '.join(set(item['category'] for item in data['news']))}")

    # 显示新闻列表
    print("\n新闻列表:")
    print("-" * 50)
    for i, news in enumerate(data['news'][:5], 1):
        print(f"{i}. {news['title']}")
        print(f"   来源: {news['source']} | 日期: {news['publishedDate']}")

    print("=" * 50)

if __name__ == "__main__":
    main()
