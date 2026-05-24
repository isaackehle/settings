#!/usr/bin/env python3
"""
Inbox Bot — Saves anything (links, notes, code) to your configured destinations.

Flow:
  1. Forward/send a message to the bot (URL, note, code snippet)
  2. Bot processes the content (fetches URLs, formats code, etc.)
  3. Bot asks "Where should this go?" with inline keyboard buttons
  4. Tap a destination — bot saves the file and confirms

Destinations are configured in config.local.env as a JSON map.
Default: "incoming" — your catch-all inbox.

Run:
  pip install -r requirements.txt
  cp config.env config.local.env  # edit with your values
  source config.local.env && python3 bot.py

As launchd service on Mac mini:
  cp com.user.link-bot.plist ~/Library/LaunchAgents/
  launchctl load ~/Library/LaunchAgents/com.user.link-bot.plist
"""

import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

import httpx
import trafilatura
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application,
    CallbackQueryHandler,
    CommandHandler,
    MessageHandler,
    filters,
)

# ── Config ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    level=logging.INFO,
)
log = logging.getLogger(__name__)

# Auto-load ~/.env.local if present (secrets, not in repo)
_env_local = Path.home() / ".env.local"
if _env_local.exists():
    for line in _env_local.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip())

BOT_TOKEN = os.environ.get("BOT_TOKEN", "")
ALLOWED_USER_ID = int(os.environ.get("ALLOWED_USER_ID", "0"))
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "qwen3:14b")
OR_KEY = os.environ.get("OPENROUTER_API_KEY", "")
OR_MODEL = os.environ.get("OPENROUTER_MODEL", "openai/gpt-4o-mini")

# Destinations: JSON map of short_name -> absolute_path
# Example: {"incoming":"/Users/isaac/inbox","links":"/Users/isaac/code/.../saved-links"}
DESTINATIONS_RAW = os.environ.get("DESTINATIONS", "")
try:
    DESTINATIONS = json.loads(DESTINATIONS_RAW) if DESTINATIONS_RAW else {}
except json.JSONDecodeError as e:
    log.error("DESTINATIONS is not valid JSON: %s", e)
    DESTINATIONS = {}

# Fallback if no destinations configured
BASE = Path.home() / "code" / "isaackehle" / "settings"
if not DESTINATIONS:
    DESTINATIONS = {
        "incoming": str(Path.home() / "vault" / "incoming"),
        "links": str(BASE / "saved-links"),
    }

DEST_KEYS = list(DESTINATIONS.keys())

if not BOT_TOKEN or not ALLOWED_USER_ID:
    log.error("BOT_TOKEN and ALLOWED_USER_ID must be set in environment or config.local.env")
    sys.exit(1)

# ── Helpers ─────────────────────────────────────────────────────────────────

def extract_urls(text: str) -> list[str]:
    return re.findall(r"https?://[^\s]+", text)


def extract_code_blocks(text: str) -> list[tuple[str, str]]:
    """Extract ```code blocks```. Returns list of (language, code)."""
    blocks = re.findall(r"```(\w*)\n(.*?)```", text, re.DOTALL)
    return [(lang.strip() or "text", code.strip()) for lang, code in blocks]


def slugify(title: str) -> str:
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
        meta = trafilatura.bare_extraction(html, include_comments=False)
        extracted = trafilatura.extract(html, include_comments=False, include_tables=False,
                                        include_images=False, output_format="txt",
                                        favor_recall=True)
        if not extracted:
            return None, None
        doc_title = meta.title if meta and meta.title else (extracted.split("\n")[0] if extracted else "Untitled")
    except Exception as e:
        log.warning("extraction failed for %s: %s", url, e)
        return None, None

    return doc_title, extracted


async def summarize_via_ollama(title: str, text: str) -> str:
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
        "options": {"temperature": 0.3, "num_predict": 500},
    }
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            resp = await client.post(f"{OLLAMA_HOST}/api/generate", json=payload)
            resp.raise_for_status()
            return resp.json().get("response", "").strip()
    except Exception as e:
        log.warning("Ollama summarization failed: %s", e)
        return ""


async def summarize_via_openrouter(title: str, text: str) -> str:
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
                headers={"Authorization": f"Bearer {OR_KEY}", "Content-Type": "application/json"},
                json=payload,
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"].strip()
    except Exception as e:
        log.warning("OpenRouter summarization failed: %s", e)
        return ""


def generate_link_markdown(url: str, title: str, summary: str, tldr: str) -> str:
    """Markdown for a saved link/article."""
    date = datetime.now().strftime("%Y-%m-%d")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    domain = urlparse(url).netloc
    tag_keywords = {
        "ai": r"\bai\b|artificial intelligence|llm|language model|transformer",
        "tooling": r"\btool\b|framework|library|cli|terminal|dev tool",
        "coding": r"\bcoding?\b|programming|developer|software|code",
        "reasoning": r"\breasoning?\b|think|chain.of.thought",
        "open-source": r"\bopen.?source\b|github|repository",
        "ml": r"\bmachine learning\b|deep learning|training|fine.?tune",
        "research": r"\bresearch\b|paper|arxiv|publication|study",
    }
    tags = []
    text_lower = (summary + " " + title).lower()
    for tag, pattern in tag_keywords.items():
        if re.search(pattern, text_lower):
            tags.append(tag)
    if not tags:
        tags = ["link"]

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


def generate_note_markdown(text: str) -> str:
    """Markdown for a plain note."""
    date = datetime.now().strftime("%Y-%m-%d")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    # First line as title
    lines = text.strip().split("\n")
    title = lines[0].strip() if lines else "Note"
    if len(title) > 80:
        title = title[:77] + "..."

    return f"""---
date: {date}
tags: [note]
---

# {title}

{text}

---
_Saved via link-bot on {timestamp}_
"""


def generate_code_markdown(code: str, language: str, context: str = "") -> str:
    """Markdown for a code snippet."""
    date = datetime.now().strftime("%Y-%m-%d")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    title = f"Code Snippet ({language})"
    if context:
        title = context.strip().split("\n")[0][:60]

    return f"""---
date: {date}
tags: [code, {language}]
---

# {title}

```{language}
{code}
```

---
_Saved via link-bot on {timestamp}_
"""


def save_file(content: str, title: str, destination: Path) -> Path:
    """Save content to destination directory. Returns the file path."""
    destination.mkdir(parents=True, exist_ok=True)
    date = datetime.now().strftime("%Y-%m-%d")
    slug = slugify(title) or "untitled"
    filename = f"{date}-{slug}.md"
    filepath = destination / filename
    counter = 1
    while filepath.exists():
        filepath = destination / f"{date}-{slug}-{counter}.md"
        counter += 1
    filepath.write_text(content, encoding="utf-8")
    log.info("saved: %s", filepath)
    return filepath


def make_dest_keyboard() -> InlineKeyboardMarkup:
    """Build inline keyboard with destination buttons."""
    buttons = []
    row = []
    for i, key in enumerate(DEST_KEYS):
        label = key.capitalize()
        if key == "incoming":
            label += " \u2b07"  # down arrow = default
        row.append(InlineKeyboardButton(label, callback_data=f"dest|{key}"))
        if len(row) >= 3 or i == len(DEST_KEYS) - 1:
            buttons.append(row)
            row = []
    return InlineKeyboardMarkup(buttons)


# ── Content classification ──────────────────────────────────────────────────

def classify_message(text: str) -> dict:
    """
    Classify message content and build save payload.
    Returns dict with keys: type, title, content, preview
    """
    code_blocks = extract_code_blocks(text)
    urls = extract_urls(text)

    if urls:
        return {"type": "url", "urls": urls, "raw_text": text, "code_blocks": code_blocks}
    elif code_blocks:
        return {"type": "code", "code_blocks": code_blocks, "raw_text": text}
    else:
        return {"type": "note", "raw_text": text}


# ── Bot handlers ────────────────────────────────────────────────────────────

async def start(update: Update, _context):
    if update.effective_user and update.effective_user.id != ALLOWED_USER_ID:
        await update.message.reply_text("Not authorized.")
        return

    dest_list = "\n".join(f"  /{k}  \u2192  {v}" for k, v in DESTINATIONS.items())
    await update.message.reply_text(
        f"Inbox Bot active.\n\n"
        f"Send me anything (link, note, code snippet) and I'll save it.\n"
        f"I'll ask where to put it — or use /<destination> to skip the prompt.\n\n"
        f"**Destinations:**\n{dest_list}",
    )


async def handle_message(update: Update, context):
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id != ALLOWED_USER_ID:
        return

    text = update.message.text or update.message.caption or ""
    if not text:
        await update.message.reply_text("Send me a message with text, a link, or code.")
        return

    msg = await update.message.reply_text("Processing...")

    # Classify and process
    info = classify_message(text)

    if info["type"] == "url":
        # Process first URL, summarize
        url = info["urls"][0]
        await msg.edit_text(f"Fetching {url}...")
        title, article_text = await fetch_article(url)
        if not article_text:
            await msg.edit_text(f"Could not extract content from {url}. Saving raw link.")
            content = generate_link_markdown(url, url, "Content could not be extracted.", url)
            doc_title = url.split("/")[-1].replace("-", " ").title() or "Link"
        else:
            word_count = len(article_text.split())
            await msg.edit_text(f"Extracted ~{word_count} words. Summarizing...")
            summary = await summarize_via_ollama(title or "Untitled", article_text)
            if not summary and OR_KEY:
                summary = await summarize_via_openrouter(title or "Untitled", article_text)
            if not summary:
                summary = "Summary unavailable."
            tldr = (summary.split("\n")[0] if summary else "")[:200]
            doc_title = title or url.split("/")[-1].replace("-", " ").title()
            content = generate_link_markdown(url, doc_title, summary, tldr)
    elif info["type"] == "code":
        lang, code = info["code_blocks"][0]
        content = generate_code_markdown(code, lang, info["raw_text"])
        doc_title = f"Code Snippet ({lang})"
        await msg.edit_text(f"Code snippet ({lang}) ready.")
    else:
        content = generate_note_markdown(info["raw_text"])
        lines = info["raw_text"].strip().split("\n")
        doc_title = lines[0][:80] if lines else "Note"
        await msg.edit_text("Note ready.")

    # Store pending content in user_data for the callback handler
    context.user_data["pending_save"] = {
        "content": content,
        "title": doc_title,
    }

    await msg.edit_text(
        f"**{doc_title}**\n\nWhere should I save this?",
        reply_markup=make_dest_keyboard(),
    )


async def handle_destination(update: Update, context):
    """Callback handler for destination button taps."""
    query = update.callback_query
    await query.answer()

    dest_key = query.data.split("|", 1)[1]
    dest_path = DESTINATIONS.get(dest_key)

    if not dest_path:
        await query.edit_message_text(f"Unknown destination: {dest_key}")
        return

    pending = context.user_data.get("pending_save")
    if not pending:
        await query.edit_message_text("Nothing to save. Send me something first.")
        return

    dest_dir = Path(dest_path).expanduser()
    filepath = save_file(pending["content"], pending["title"], dest_dir)
    relpath = str(filepath.relative_to(Path.home())) if filepath.is_relative_to(Path.home()) else str(filepath)

    await query.edit_message_text(
        f"Saved \u2192 `~/{relpath}`",
        disable_web_page_preview=True,
    )
    context.user_data.pop("pending_save", None)


async def handle_dest_command(update: Update, context):
    """Handle /<destination> commands to skip the prompt."""
    user_id = update.effective_user.id if update.effective_user else 0
    if user_id != ALLOWED_USER_ID:
        return

    dest_key = update.message.text.lstrip("/").strip()
    if dest_key not in DESTINATIONS:
        available = ", ".join(f"/{k}" for k in DEST_KEYS)
        await update.message.reply_text(f"Unknown destination. Available: {available}")
        return

    # Need pending content — if none, ask user to send something first
    if not context.user_data.get("pending_save"):
        await update.message.reply_text("Nothing pending. Send me a message with content first, then use the destination command.")
        return

    # Simulate callback
    query = update.callback_query
    # We don't have a real callback query, so create a synthetic one
    # Actually, let's just handle it directly
    dest_path = DESTINATIONS.get(dest_key)
    pending = context.user_data.get("pending_save")
    dest_dir = Path(dest_path).expanduser()
    filepath = save_file(pending["content"], pending["title"], dest_dir)
    relpath = str(filepath.relative_to(Path.home())) if filepath.is_relative_to(Path.home()) else str(filepath)

    await update.message.reply_text(
        f"Saved to {dest_key} \u2192 `~/{relpath}`",
        disable_web_page_preview=True,
    )
    context.user_data.pop("pending_save", None)


# ── Main ────────────────────────────────────────────────────────────────────

def main():
    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))
    app.add_handler(CallbackQueryHandler(handle_destination, pattern=r"^dest\|"))

    # Add command handlers for each destination
    for key in DEST_KEYS:
        app.add_handler(CommandHandler(key, handle_dest_command))

    log.info("starting inbox bot with destinations: %s", DEST_KEYS)
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
