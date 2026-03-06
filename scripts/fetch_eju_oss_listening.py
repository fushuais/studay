#!/usr/bin/env python3
import json
import re
import ssl
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = "https://www.jasso.go.jp"
INDEX_URL = "https://www.jasso.go.jp/ryugaku/eju/examinee/pastpaper_sample/index.html"


def fetch(url: str, ctx: ssl.SSLContext) -> str:
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": "Mozilla/5.0 (Codex EJU Fetcher)",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ja,en-US;q=0.9,en;q=0.8",
            "Referer": "https://www.jasso.go.jp/",
        },
    )
    return urllib.request.urlopen(req, context=ctx, timeout=60).read().decode("utf-8", errors="ignore")


def extract_page_links(index_html: str) -> list[str]:
    links = []
    for href in re.findall(r'href="([^"]*pastpaper_[^"]+\.html)"', index_html):
        full = urllib.parse.urljoin(BASE, href)
        if full not in links:
            links.append(full)
    return links


def clean_text(text: str) -> str:
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", text)).strip()


def extract_title(html: str) -> str:
    m = re.search(r"<title>(.*?)</title>", html, re.IGNORECASE | re.DOTALL)
    if m:
        return clean_text(m.group(1))
    return "EJU 過去問サンプル"


def extract_script_link(html: str, page_url: str) -> str:
    m = re.search(r'href="([^"]+\.pdf)"[^>]*>\s*Audio and Script', html, re.IGNORECASE)
    if not m:
        return ""
    return urllib.parse.urljoin(page_url, m.group(1))


def extract_audio_links(html: str, page_url: str) -> list[str]:
    urls = []
    for href in re.findall(r'href="([^"]+\.wav)"', html, re.IGNORECASE):
        full = urllib.parse.urljoin(page_url, href)
        if full not in urls:
            urls.append(full)
    return urls


def category_from_filename(url: str) -> str:
    name = url.rsplit("/", 1)[-1].lower()
    if "ac" in name:
        return "聴解"
    if "al" in name:
        return "聴読解"
    return "総合"


def build_payload(ctx: ssl.SSLContext) -> dict:
    index_html = fetch(INDEX_URL, ctx)
    page_links = extract_page_links(index_html)
    page_links = page_links[:10]

    papers = []
    for page_url in page_links:
        try:
            html = fetch(page_url, ctx)
        except Exception:
            continue
        audio_links = extract_audio_links(html, page_url)
        if not audio_links:
            continue
        script_link = extract_script_link(html, page_url)
        title = extract_title(html)
        tracks = []
        for i, audio_url in enumerate(audio_links, start=1):
            tracks.append(
                {
                    "id": f"{page_url.rsplit('/', 1)[-1].replace('.html', '')}-{i:02d}",
                    "title": f"{title} 音声 {i}",
                    "category": category_from_filename(audio_url),
                    "audioURL": audio_url,
                }
            )
        papers.append(
            {
                "title": title,
                "sourcePage": page_url,
                "scriptPDF": script_link,
                "tracks": tracks,
            }
        )

    total_tracks = sum(len(p["tracks"]) for p in papers)
    return {
        "meta": {
            "source": "JASSO EJU pastpaper sample (open web)",
            "fetchedAt": datetime.now(timezone.utc).isoformat(),
            "indexURL": INDEX_URL,
            "paperCount": len(papers),
            "trackCount": total_tracks,
        },
        "papers": papers,
    }


def main():
    repo_root = Path(__file__).resolve().parents[1]
    out = repo_root / "travel" / "eju_listening_oss.json"
    ctx = ssl._create_unverified_context()
    payload = build_payload(ctx)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {out}")
    print(f"Papers: {payload['meta']['paperCount']}")
    print(f"Tracks: {payload['meta']['trackCount']}")


if __name__ == "__main__":
    main()
