#!/usr/bin/env python3
"""
Link Bot — Telegram bot for article summarization via local LLM.

Flow:
  1. User forwards a message with a URL to the bot
  2. Bot fetches and extracts article content
  3. Bot sends content to local Ollama model for summarization
  4. Bot saves summary as markdown to the settings repo
  5. Bot replies with a preview

Run:
  pip install -r requirements.txt
  cp config.env config.local.env  # edit with your values
  source config.local.env && python3 bot.py

As launchd service on Mac mini:
  cp com.user.link-bot.plist ~/Library/LaunchAgents/
  launchctl load ~/Library/LaunchAgents/com.user.link-bot.plist
"""

import asyncio
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

import httpx
import trafilatura
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters

# ── Config ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    level=logging.INFO,
)
log = logging.getLogger(__name__)

BOT_TOKEN = os.environ.get("BOT_TOKEN", "")
ALLOWED_USER_ID = int(os.environ.get("ALLOWED_USER_ID", "0"))
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen3:14b")
OR_KEY = os.environ.get("OPENROUTER_API_KEY", "")
OR_MODEL = os.environ.get("OPENROUTER_MODEL", "openai/gpt-4o-mini")
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", str(Path.home() / "code" / "isaackehle" / "settings" / "saved-links")))

if not BOT_TOKEN or not ALLOWED_USER_ID:
    log.error("BOT_TOKEN and ALLOWED_USER_ID must be set in environment or config.local.env")
    sys.exit(1)

# ── Helpers ─────────────────────────────────────────────────────────────────

def extract_urls(text: str) -> list[str]:
    """Extract all URLs from a message."""
    return re.findall(r"https?://[^\s]+", text)


def slugify(title: str) -> str:
    """Create a safe filesystem slug from a title."""
    slug = re.sub(r"[^\w\s-]", "", title.lower())
    slug = re.sub(r"[-\s]+", "-", slug).strip("-")
    return slug[:80]


async def fetch_article(url: str) -> tuple[str | None, str | None]:
    """Fetch and extract article content. Returns (title, text) or (None, None)."""
    try:
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            resp = await client.get(url, headers={
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                              "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            })
            resp.raise_for_status()
            html = resp.text
    except Exception as e:
        log.warning("fetch failed for %s: %s", url, e)
        return None, None

    try:
        extracted = trafilatura.extract(html, include_comments=False, include_tables=False,
                                         include_images=False, output_format="txt",
                                         favor_recall=True)
        title = trafilatura.extract(html, output_format="txt", favor_recall=True)
        if not extracted:
            return None, None
        # Get title from metadata or first line
        meta = trafilatura.bare_extraction(html, include_comments=False)
        doc_title = meta.title if meta and meta.title else (extracted.split("\n")[0] if extracted else "Untitled")
    except Exception as e:
        log.warning("extraction failed for %s: %s", url, e)
        return None, None

    return doc_title, extracted


async def summarize_via_ollama(title: str, text: str) -> str:
    """Send article text to local Ollama model for summarization."""
    prompt = f"""You are a research assistant. Summarize the following article concisely.

Article title: {title}

Focus on:
1. What is this about?
2. Why is it interesting for a developer / AI engineer?
3. What key tools, models, or techniques does it mention?
4. Any actionable takeaways?

Keep the summary under 200 words. Write in plain English.

Article:
{text[:8000]}
"""

    payload = {
        "model": OLLAMA_MODEL,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.3,
            "num_predict": 500,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(f"{OLLAMA_HOST}/api/generate", json=payload)
            resp.raise_for_status()
            data = resp.json()
            return data.get("response", "").strip()
    except Exception as e:
        log.warning("Ollama summarization failed: %s", e)
        return ""


async def summarize_via_openrouter(title: str, text: str) -> str:
    """Fallback: summarize via OpenRouter API."""
    if not OR_KEY:
        return ""

    prompt = f"""Summarize the following article concisely. Focus on: what it's about, why it matters for developers, key tools/models mentioned, and actionable takeaways. Keep it under 200 words.

Title: {title}

Article:
{text[:8000]}"""

    payload = {
        "model": OR_MODEL,
        "messages": [
            {"role": "system", "content": "You are a helpful research assistant."},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.3,
        "max_tokens": 500,
    }

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            resp = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {OR_KEY}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"].strip()
    except Exception as e:
        log.warning("OpenRouter summarization failed: %s", e)
        return ""


def one_liner(summary: str) -> str:
    """Extract the first sentence for a TL;DR."""
    lines = summary.strip().split("\n")
    if lines:
        first = lines[0].strip()
        if len(first) > 200:
            first = first[:197] + "..."
        return first
    return summary


def generate_markdown(url: str, title: str, summary: str, tldr: str) -> str:
    """Generate a markdown file for the saved link."""
    date = datetime.now().strftime("%Y-%m-%d")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    domain = urlparse(url).netloc

    # Extract tags from summary
    tag_keywords = {
        "ai": r"\bai\b|artificial intelligence|llm|language model|transformer",
        "tooling": r"\btool\b|framework|library|cli|terminal|dev tool",
        "coding": r"\bcoding?\b|programming|developer|software|code",
        "reasoning": r"\breasoning?\b|think|chain.of.thought",
        "open-source": r"\bopen.?source\b|github|repository",
        "ml": r"\bmachine learning\b|deep learning|training|fine.?tune",
        "web": r"\bweb\b|browser|frontend|css|html|javascript",
        "security": r"\bsecurity\b|privacy|encryption|auth",
        "devops": r"\bdevops\b|deploy|infrastructure|docker|kubernetes",
        "research": r"\bresearch\b|paper|arxiv|publication|study",
    }
    tags = []
    text_lower = (summary + " " + title).lower()
    for tag, pattern in tag_keywords.items():
        if re.search(pattern, text_lower):
            tags.append(tag)
    if not tags:
        tags = ["link"]

    tag_line = ", ".join(f"#{t}" for t in sorted(tags))

    return f"""---
date: {date}
source: {url}
domain: {domain}
tags: [{', '.join(sorted(tags))}]
---

# {title}

**TL;DR:** {tldr}

**Summary:**

{summary}

---
_Saved via link-bot on {timestamp}_
"""


def save_file(content: str, title: str, url: str) -> Path:
    """Save markdown to disk. Returns the file path."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    date = datetime.now().strftime("%Y-%m-%d")
    slug = slugify(title) or slugify(url.split("/")[-1]) or "untitled"
    filename = f"{date}-{slug}.md"
    filepath = OUTPUT_DIR / filename

    # Avoid overwrites by appending a counter if duplicate
    counter = 1
    while filepath.exists():
        filepath = OUTPUT_DIR / f"{date}-{slug}-{counter}.md"
        counter += 1

    filepath.write_text(content, encoding="utf-8")
    log.info("saved: %s", filepath)
    return filepath


# ── Bot handlers ────────────────────────────────────────────────────────────

async def start(update: Update, _context):
    if update.effective_user and update.effective_user.id != ALLOWED_USER_ID:
        await update.message.reply_text("Not authorized.")
        return
    await update.message.reply_text(
        "Link Bot active. Forward me a message with a URL and I'll "
        "fetch, summarize, and save it."
    )


async def handle_message(update: Update, _context):
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id != ALLOWED_USER_ID:
        return  # silently ignore

    text = update.message.text or update.message.caption or ""
    if not text:
        await update.message.reply_text("Send me a message with a URL.")
        return

    urls = extract_urls(text)
    if not urls:
        await update.message.reply_text("No URLs found in that message.")
        return

    await update.message.reply_text(f"Found {len(urls)} URL{'s' if len(urls) > 1 else ''}. Processing...")

    for url in urls:
        try:
            await process_url(update, url)
        except Exception as e:
            log.exception("error processing %s", url)
            await update.message.reply_text(f"Failed to process {url}: {e}")


async def process_url(update: Update, url: str):
    """Fetch, summarize, save, and reply for a single URL."""
    msg = await update.message.reply_text(f"Fetching {url}...")

    # 1. Fetch article
    title, text = await fetch_article(url)
    if not text:
        await msg.edit_text(f"Could not extract content from {url}")
        return

    word_count = len(text.split())
    await msg.edit_text(f"Extracted ~{word_count} words. Summarizing...")

    # 2. Summarize via Ollama (fallback to OpenRouter)
    summary = await summarize_via_ollama(title or "Untitled", text)
    if not summary and OR_KEY:
        summary = await summarize_via_openrouter(title or "Untitled", text)
    if not summary:
        summary = "Summary unavailable."

    tldr = one_liner(summary)

    # 3. Generate markdown
    doc_title = title or url.split("/")[-1].replace("-", " ").title()
    content = generate_markdown(url, doc_title, summary, tldr)

    # 4. Save
    filepath = save_file(content, doc_title, url)
    relpath = filepath.relative_to(filepath.anchor).as_posix()

    # 5. Reply
    preview = f"**{doc_title}**\n\nTL;DR: {tldr}\n\nSaved: `{relpath}`"
    await msg.edit_text(preview, disable_web_page_preview=True)


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    log.info("starting link-bot polling...")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
