#!/usr/bin/env python3
"""
crawl-honcho-docs.py
爬取 Honcho 官方文件並儲存為本地 Markdown 檔案
用法：python crawl-honcho-docs.py [--output ./docs-cache]
"""

import argparse
import re
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse

DOCS_URLS = [
    "https://honcho.dev/docs/v3/documentation/introduction/quickstart",
    "https://honcho.dev/docs/v3/contributing/self-hosting",
    "https://honcho.dev/docs/v3/contributing/troubleshooting",
    "https://honcho.dev/docs/llms.txt",
    "https://honcho.dev/docs/v3/guides/integrations/mcp",
    "https://honcho.dev/docs/v3/guides/integrations/claude-code",
    "https://honcho.dev/docs/v3/guides/integrations/openclaw",
]


def fetch_url(url: str, delay: float = 1.0) -> str | None:
    """取得 URL 內容，回傳文字或 None。"""
    try:
        import urllib.request
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "honcho-memory-lab-crawler/1.0 (educational)"}
        )
        with urllib.request.urlopen(req, timeout=15) as r:
            content = r.read().decode("utf-8", errors="replace")
        time.sleep(delay)
        return content
    except Exception as e:
        print(f"  ✗ 無法取得 {url}: {e}")
        return None


def url_to_filename(url: str) -> str:
    """把 URL 轉成安全的檔名。"""
    parsed = urlparse(url)
    path = parsed.path.strip("/").replace("/", "_")
    if not path:
        path = "index"
    return f"{path}.md"


def html_to_text(html: str) -> str:
    """簡單的 HTML → 純文字轉換（不依賴 BeautifulSoup）。"""
    # 移除 script / style
    html = re.sub(r"<(script|style)[^>]*>.*?</\1>", "", html, flags=re.DOTALL | re.IGNORECASE)
    # 移除 HTML 標籤
    text = re.sub(r"<[^>]+>", "", html)
    # 還原常見 HTML entities
    text = text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    text = text.replace("&nbsp;", " ").replace("&#39;", "'").replace("&quot;", '"')
    # 壓縮多餘空白行
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def crawl(output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"輸出目錄：{output_dir}")
    print(f"共 {len(DOCS_URLS)} 個頁面\n")

    for url in DOCS_URLS:
        print(f"取得：{url}")
        content = fetch_url(url)
        if content is None:
            continue

        filename = url_to_filename(url)
        filepath = output_dir / filename

        # 若是 .txt 直接存
        if url.endswith(".txt"):
            filepath.write_text(content, encoding="utf-8")
        else:
            # HTML 轉文字
            text = html_to_text(content)
            md_content = f"# Source: {url}\n\n{text}"
            filepath.write_text(md_content, encoding="utf-8")

        print(f"  ✓ 儲存至 {filename} ({len(content)} bytes)")

    print(f"\n完成！共儲存 {len(DOCS_URLS)} 個頁面至 {output_dir}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="爬取 Honcho 官方文件")
    parser.add_argument(
        "--output",
        default="./docs-cache",
        help="輸出目錄（預設：./docs-cache）"
    )
    args = parser.parse_args()
    crawl(Path(args.output))
