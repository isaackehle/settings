#!/usr/bin/env python3
"""
model-scout — fetch current model recommendations per role.

Sources:
  openrouter  Public model API (available models + metadata)
  groq        Known fast-inference models
  aider       Coding leaderboard (aider.chat, HTML scraped)
  lmarena     Chatbot Arena leaderboard (lmarena.ai, HTML scraped)
  editorial   Curated offline Ollama picks

Output: one line per accepted role → role=model_id
"""

import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from typing import Optional

TIMEOUT = 8

ROLES = ["coding", "reasoning", "research", "writing", "planning"]

ROLE_DESC = {
    "coding":    "Code generation, completion, debugging",
    "reasoning": "Complex reasoning, math, logic",
    "research":  "Long context, knowledge retrieval, synthesis",
    "writing":   "Prose, creative writing, summarization",
    "planning":  "Task planning, tool use, agentic workflows",
}


@dataclass
class Rec:
    model_id: str
    provider: str
    source: str
    note: str = ""
    roles: list = field(default_factory=list)


# ──────────────────────────────────────────────────────────────
# Fetch helpers
# ──────────────────────────────────────────────────────────────

def fetch(url: str) -> Optional[str]:
    try:
        req = urllib.request.Request(
            url, headers={"User-Agent": "model-scout/1.0"}
        )
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception:
        return None


# ──────────────────────────────────────────────────────────────
# Sources
# ──────────────────────────────────────────────────────────────

def from_openrouter() -> list[Rec]:
    data = fetch("https://openrouter.ai/api/v1/models")
    if not data:
        return []
    try:
        available = {m["id"] for m in json.loads(data).get("data", [])}
    except Exception:
        return []

    NOTABLE: dict[str, tuple[list[str], str]] = {
        "anthropic/claude-opus-4":           (["coding", "reasoning", "research", "writing", "planning"], "Anthropic flagship"),
        "anthropic/claude-sonnet-4":         (["coding", "writing", "planning"],                          "Anthropic balanced"),
        "anthropic/claude-haiku-4-5":        (["writing", "planning"],                                    "Anthropic fast"),
        "google/gemini-2.5-pro":             (["coding", "reasoning", "research"],                        "Google flagship — 2M ctx"),
        "google/gemini-2.5-flash":           (["writing", "planning"],                                    "Google fast"),
        "openai/gpt-4.1":                    (["coding", "research", "writing"],                          "OpenAI latest"),
        "openai/o3":                         (["reasoning", "planning"],                                  "OpenAI reasoning"),
        "openai/o4-mini":                    (["reasoning", "coding"],                                    "OpenAI fast reasoning"),
        "deepseek/deepseek-r1":              (["reasoning", "coding"],                                    "DeepSeek reasoning"),
        "deepseek/deepseek-chat-v3-0324":    (["coding", "writing"],                                      "DeepSeek chat v3"),
        "meta-llama/llama-4-maverick":       (["coding", "writing", "planning"],                          "Meta Llama 4 Maverick"),
        "meta-llama/llama-4-scout":          (["research"],                                               "Meta Llama 4 Scout — 10M ctx"),
        "qwen/qwen3-235b-a22b":              (["coding", "reasoning"],                                    "Qwen3 MoE 235B"),
        "qwen/qwen3-30b-a3b":               (["coding", "writing"],                                      "Qwen3 MoE 30B fast"),
        "mistralai/mistral-medium-3":        (["coding", "writing"],                                      "Mistral balanced"),
        "mistralai/devstral-small":          (["coding"],                                                 "Mistral code specialist"),
        "x-ai/grok-3":                       (["reasoning", "research"],                                  "xAI Grok 3"),
        "x-ai/grok-3-mini":                  (["reasoning"],                                              "xAI Grok 3 Mini fast"),
        "cohere/command-r-plus-08-2024":     (["research", "writing"],                                    "Cohere RAG-optimised"),
        "nvidia/llama-3.1-nemotron-ultra":   (["coding", "reasoning"],                                   "NVIDIA Nemotron Ultra"),
    }

    recs = []
    for mid, (roles, note) in NOTABLE.items():
        if mid in available:
            recs.append(Rec(
                model_id=mid,
                provider=mid.split("/")[0],
                source="openrouter",
                note=note,
                roles=roles,
            ))
    return recs


def from_groq() -> list[Rec]:
    MODELS = [
        ("llama-3.3-70b-versatile",           ["coding", "writing", "planning"], "Llama 3.3 70B — versatile"),
        ("llama-3.1-8b-instant",              ["writing", "planning"],           "Llama 3.1 8B — instant"),
        ("deepseek-r1-distill-llama-70b",     ["reasoning"],                     "DeepSeek R1 distill 70B"),
        ("qwen-qwq-32b",                      ["reasoning", "coding"],           "QwQ 32B reasoning"),
        ("mistral-saba-24b",                  ["writing", "research"],           "Mistral Saba 24B"),
        ("meta-llama/llama-4-scout-17b-16e",  ["research"],                      "Llama 4 Scout — long ctx"),
    ]
    return [
        Rec(model_id=mid, provider="groq", source="groq", note=note, roles=roles)
        for mid, roles, note in MODELS
    ]


def from_aider_leaderboard() -> list[Rec]:
    """Scrape the Aider coding leaderboard for top coding models."""
    html = fetch("https://aider.chat/docs/leaderboards/")
    if not html:
        return []
    # Extract model names from the first table (edit leaderboard)
    # Rows look like: <td>claude-opus-4</td><td>...score...</td>
    rows = re.findall(r'<tr[^>]*>.*?</tr>', html, re.DOTALL)
    recs = []
    seen = set()
    for row in rows[:30]:  # top 30 rows
        cells = re.findall(r'<td[^>]*>(.*?)</td>', row, re.DOTALL)
        if len(cells) < 2:
            continue
        name = re.sub(r'<[^>]+>', '', cells[0]).strip()
        if not name or name in seen or len(name) < 4:
            continue
        seen.add(name)
        recs.append(Rec(
            model_id=name,
            provider=name.split("/")[0] if "/" in name else "unknown",
            source="aider",
            note="Aider coding leaderboard",
            roles=["coding"],
        ))
    return recs[:10]


def from_lmarena() -> list[Rec]:
    """Scrape lmarena.ai for general leaderboard standings."""
    html = fetch("https://lmarena.ai/")
    if not html:
        return []
    # Arena leaderboard embeds JSON data in a script tag
    match = re.search(r'"leaderboard"\s*:\s*(\[.*?\])', html, re.DOTALL)
    if not match:
        return []
    try:
        entries = json.loads(match.group(1))
    except Exception:
        return []
    recs = []
    for e in entries[:20]:
        name = e.get("model_name") or e.get("name") or ""
        if not name:
            continue
        recs.append(Rec(
            model_id=name,
            provider=name.split("/")[0] if "/" in name else "arena",
            source="lmarena",
            note=f"Arena ELO {e.get('rating', e.get('elo', '?'))}",
            roles=["reasoning", "writing"],
        ))
    return recs


def editorial_ollama() -> list[Rec]:
    """Curated local Ollama picks."""
    PICKS = [
        ("qwen3-32b:q6_K",           "ollama", ["coding", "reasoning"],   "Strong reasoning + coding"),
        ("qwen3-14b:q8_0",           "ollama", ["coding", "writing"],     "Balanced, fast"),
        ("deepseek-r1:q4_K_M",       "ollama", ["reasoning"],             "Reasoning specialist"),
        ("deepseek-coder-v2:q4_K_M", "ollama", ["coding"],               "Code specialist"),
        ("llama4:scout-q4_K_M",      "ollama", ["research"],              "10M context window"),
        ("gemma3:27b-it-q4_K_M",     "ollama", ["writing", "planning"],   "Google Gemma 3 27B"),
        ("phi4:latest",              "ollama", ["planning", "writing"],   "Microsoft Phi-4 small/fast"),
        ("mistral-nemo:latest",      "ollama", ["writing"],               "Mistral fast"),
    ]
    return [
        Rec(model_id=mid, provider=prov, source="editorial", note=note, roles=roles)
        for mid, prov, roles, note in PICKS
    ]


# ──────────────────────────────────────────────────────────────
# fzf picker
# ──────────────────────────────────────────────────────────────

def fzf_pick(entries: list[tuple[str, str]], header: str) -> Optional[str]:
    """
    entries: list of (model_id, display_string)
    Returns model_id of selected item, or None if skipped.
    Uses tab-delimiter: fzf shows field 2, returns full line.
    """
    lines = [f"{mid}\t{display}" for mid, display in entries]
    try:
        proc = subprocess.run(
            [
                "fzf",
                "--header", header,
                "--layout=reverse",
                "--height=60%",
                "--delimiter=\t",
                "--with-nth=2",
            ],
            input="\n".join(lines),
            capture_output=True,
            text=True,
        )
        line = proc.stdout.strip()
        return line.split("\t")[0] if line else None
    except FileNotFoundError:
        print("Error: fzf not installed. Run: brew install fzf", file=sys.stderr)
        sys.exit(1)


# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────

def main() -> None:
    print("Fetching model recommendations…", file=sys.stderr)

    all_recs: list[Rec] = []
    sources = [
        ("openrouter",  from_openrouter),
        ("groq",        from_groq),
        ("aider",       from_aider_leaderboard),
        ("lmarena",     from_lmarena),
        ("editorial",   editorial_ollama),
    ]
    for label, fn in sources:
        try:
            found = fn()
            print(f"  {label}: {len(found)} models", file=sys.stderr)
            all_recs += found
        except Exception as e:
            print(f"  {label}: failed ({e})", file=sys.stderr)

    # Deduplicate by model_id (keep first occurrence, which is highest-priority source)
    seen: set[str] = set()
    deduped: list[Rec] = []
    for r in all_recs:
        if r.model_id not in seen:
            seen.add(r.model_id)
            deduped.append(r)

    # Build per-role candidate lists
    role_map: dict[str, list[Rec]] = {role: [] for role in ROLES}
    for r in deduped:
        for role in r.roles:
            if role in role_map:
                role_map[role].append(r)

    print("", file=sys.stderr)

    for role in ROLES:
        candidates = role_map[role]
        if not candidates:
            continue

        max_mid  = max(len(r.model_id)  for r in candidates)
        max_src  = max(len(r.source)    for r in candidates)
        max_prov = max(len(r.provider)  for r in candidates)

        entries = [
            (
                r.model_id,
                f"[{r.source:<{max_src}}]  [{r.provider:<{max_prov}}]  "
                f"{r.model_id:<{max_mid}}  {r.note}",
            )
            for r in candidates
        ]

        header = (
            f"Role: {role.upper()} — {ROLE_DESC[role]}\n"
            f"  Enter=accept  q/Esc=skip this role"
        )

        chosen = fzf_pick(entries, header)
        if chosen:
            print(f"{role}={chosen}")


if __name__ == "__main__":
    main()
