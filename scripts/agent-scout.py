#!/usr/bin/env python3
"""
agent-scout.py — Discover terminal-based AI agents not yet in the repo.

Reads a curated catalog, compares against existing 2-ai/*.sh scripts
and setup_ai.sh references, then outputs suggestions in fzf-friendly format.

Usage:
  python3 agent-scout.py [--repo-root PATH] [--json]
  python3 agent-scout.py --generate <name> --repo-root PATH
"""

import argparse
import json
import os
import sys
from pathlib import Path

# Curated catalog of notable terminal-based AI agents.
# Feel free to PR additions as the ecosystem evolves.
CATALOG = [
    {
        "name": "goose",
        "display_name": "Goose",
        "description": "Block's open-source AI coding agent (Rust)",
        "github": "block/goose",
        "install_method": "brew",
        "install_hint": "brew install block/tap/goose",
        "binary": "goose",
        "config_dir": "~/.config/goose",
        "config_file": "config.yaml",
        "config_ext": "yaml",
        "category": "terminal-agents",
    },
    {
        "name": "fabric",
        "display_name": "Fabric",
        "description": "Daniel Miessler's AI CLI workflow toolkit",
        "github": "danielmiessler/fabric",
        "install_method": "pip",
        "install_hint": "pip3 install fabric-ai",
        "binary": "fabric",
        "config_dir": "~/.config/fabric",
        "config_file": "",
        "config_ext": "",
        "category": "terminal-agents",
    },
    {
        "name": "llm",
        "display_name": "LLM",
        "description": "Simon Willison's swiss-army-knife CLI for LLMs",
        "github": "simonw/llm",
        "install_method": "pip",
        "install_hint": "pip3 install llm",
        "binary": "llm",
        "config_dir": "~/.config/io.datasette.llm",
        "config_file": "default_model.txt",
        "config_ext": "txt",
        "category": "terminal-agents",
    },
    {
        "name": "aichat",
        "display_name": "AIChat",
        "description": "All-in-one LLM CLI with local and remote support",
        "github": "sigoden/aichat",
        "install_method": "brew",
        "install_hint": "brew install aichat",
        "binary": "aichat",
        "config_dir": "~/.config/aichat",
        "config_file": "config.yaml",
        "config_ext": "yaml",
        "category": "terminal-agents",
    },
    {
        "name": "plandex",
        "display_name": "Plandex",
        "description": "Terminal-based AI planner for large tasks",
        "github": "plandex-ai/plandex",
        "install_method": "curl",
        "install_hint": "curl -s https://plandex.ai/install.sh | bash",
        "binary": "plandex",
        "config_dir": "~/.plandex",
        "config_file": "config.json",
        "config_ext": "json",
        "category": "terminal-agents",
    },
    {
        "name": "yai",
        "display_name": "Yai",
        "description": "AI-powered terminal assistant with contextual help",
        "github": "ekkinox/yai",
        "install_method": "brew",
        "install_hint": "brew install yai",
        "binary": "yai",
        "config_dir": "~/.config/yai",
        "config_file": "config.yaml",
        "config_ext": "yaml",
        "category": "terminal-agents",
    },
]


def _existing_names(repo_root: str):
    """Collect all tool names already present in the repo."""
    names = set()
    ai_dir = Path(repo_root) / "2-ai"
    if ai_dir.exists():
        for p in ai_dir.iterdir():
            if p.is_file() and p.suffix == ".sh":
                names.add(p.stem)
    setup = Path(repo_root) / "setup_ai.sh"
    if setup.exists():
        text = setup.read_text()
        for line in text.splitlines():
            if '["' in line and '"]=' in line:
                try:
                    key = line.split('["')[1].split('"]')[0]
                    names.add(key)
                except IndexError:
                    pass
    return names


def _generate_stub(entry: dict) -> str:
    """Generate a 2-ai/<name>.sh installation stub from catalog metadata."""
    name = entry["name"]
    display = entry["display_name"]
    binary = entry["binary"]
    cfg_dir = entry["config_dir"].replace("~/", "$HOME/")
    cfg_file = entry["config_file"]
    cfg_ext = entry["config_ext"]
    install_hint = entry["install_hint"]
    docs = f"https://github.com/{entry['github']}"
    name_us = name.replace("-", "_")

    # Build install snippet
    if entry["install_method"] == "brew":
        install_snippet = f"""    if brew install {binary}; then
        log_status "{display} installed via Homebrew"
        return 0
    else
        log_error "Failed to install {display}"
        return 1
    fi"""
    elif entry["install_method"] == "pip":
        install_snippet = f"""    if pip3 install {binary}; then
        log_status "{display} installed via pip3"
        return 0
    else
        log_error "Failed to install {display}"
        return 1
    fi"""
    else:
        install_snippet = f"""    read -p "  Run the {display} installer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped {display} installer"
        return 1
    fi
    if {install_hint}; then
        log_status "{display} installed"
        return 0
    else
        log_error "Failed to install {display}"
        return 1
    fi"""

    # Build config deploy block
    config_deploy = ""
    if cfg_file:
        config_deploy = f"""
    mkdir -p "${name_us}_cfg_dir"
    local src_cfg
    src_cfg="${{{{SETTINGS_BASE}}}}/2-ai/profiles/${{{{MACHINE_PROFILE}}}}/{name}/{cfg_file}"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${{{{SETTINGS_BASE}}}}/2-ai/profiles/default/{name}/{cfg_file}"
    fi
    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "${name_us}_cfg"
        chmod 600 "${name_us}_cfg"
    else
        log_warning "No {display} config found at $src_cfg"
    fi"""

    # Build backup/restore block
    if cfg_file:
        backup_restore = f"""
backup_{name_us}() {{
    if [ -f "${name_us}_cfg" ]; then
        cp -r "$HOME/.{name}" "${{{{BACKUP_DIR}}}}/{name}_backup_${{{{DATE}}}}"
        cp "${name_us}_cfg" "${{{{BACKUP_DIR}}}}/{name}_config_backup_${{{{DATE}}}}.{cfg_ext}"
        log_status "Backed up {display} config"
    fi
}}

restore_{name_us}() {{
    local latest_dir latest_file
    latest_dir=$(ls -dt "${{{{BACKUP_DIR}}}}"/{name}_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${{{{BACKUP_DIR}}}}"/{name}_config_backup_*.{cfg_ext} 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.{name}"
        cp -R "$latest_dir/"* "$HOME/.{name}/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.{name}"
        cp "$latest_file" "$HOME/.{name}/{cfg_file}"
        log_status "Restored {display} config from $(basename "$latest_file")"
    else
        log_warning "No {display} backup found in ${{{{BACKUP_DIR}}}}"
    fi
}}"""
    else:
        backup_restore = f"""
backup_{name_us}() {{
    log_info "No config to backup for {display}"
}}

restore_{name_us}() {{
    log_info "No config to restore for {display}"
}}"""

    stub = f"""if [ -z "${{{{SETTINGS_BASE:-}}}}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${{{{BASH_SOURCE[0]}}}}")/../" && pwd)"
fi
. "${{{{SETTINGS_BASE}}}}/helpers.sh"

# ---------------------------------------------------------------------------
# {display} — {entry['description'].lower()}
# ---------------------------------------------------------------------------

{name_us}_cfg_dir="{cfg_dir}"
{name_us}_cfg="${name_us}_cfg_dir/{cfg_file}"

verify_{name_us}() {{
    if ! command -v {binary} &> /dev/null; then
        log_warning "{display} binary not found in PATH"
        return 1
    fi
    if [ -n "{cfg_file}" ] && [ ! -f "${name_us}_cfg" ]; then
        log_warning "{display} config not found at ${name_us}_cfg"
        return 1
    fi
    log_status "{display} installed and configured"
    return 0
}}

_install_{name_us}() {{
    log_info "Installing {display}..."
{install_snippet}
}}

setup_{name_us}() {{
    log_info "Setting up {display}..."
    verify_{name_us} || _install_{name_us} || {{ log_error "Failed to install {display}"; return 1; }}
{config_deploy}
    log_info ""
    log_info "=== {display} ==="
    log_info "Binary:  {binary}"
    log_info "Config:  ${name_us}_cfg"
    log_info "Docs:    {docs}"
    log_info ""
}}{backup_restore}

if [[ "${{{{BASH_SOURCE[0]}}}}" == "${{{{0}}}}" ]]; then
    setup_{name_us}
fi
"""
    return stub


def _generate_config(entry: dict) -> str:
    """Generate a minimal default config template for the agent."""
    ext = entry.get("config_ext", "")
    if ext == "yaml":
        return "provider: ollama\nbase_url: http://localhost:11434/v1\napi_key: sk-local\nmodel: qwen3.5:4b\n"
    elif ext == "json":
        return json.dumps({"provider": "openrouter", "model": "qwen3.5:4b"}, indent=2) + "\n"
    elif ext == "toml":
        return '[core]\nprovider = "openrouter"\nmodel = "qwen3.5:4b"\n'
    elif ext == "txt":
        return "qwen3.5:4b\n"
    return ""


def main():
    parser = argparse.ArgumentParser(description="Agent scout for terminal AI tools")
    parser.add_argument("--repo-root", default=".", help="Path to the settings repo")
    parser.add_argument("--json", action="store_true", help="Output full candidate list as JSON")
    parser.add_argument("--generate", metavar="NAME", help="Generate stub for agent NAME")
    args = parser.parse_args()

    repo = os.path.abspath(args.repo_root)
    existing = _existing_names(repo)
    candidates = [
        c for c in CATALOG
        if c["name"] not in existing and c["name"].replace("-", "_") not in existing
    ]

    if args.generate:
        entry = next((c for c in CATALOG if c["name"] == args.generate), None)
        if not entry:
            print(f"Unknown agent: {args.generate}", file=sys.stderr)
            sys.exit(1)
        print(_generate_stub(entry))
        return

    if not candidates:
        print("No new agents found — your catalog is current.", file=sys.stderr)
        print("[]" if args.json else "")
        return

    if args.json:
        print(json.dumps(candidates, indent=2))
        return

    max_name = max(len(c["name"]) for c in candidates)
    max_disp = max(len(c["display_name"]) for c in candidates)
    for c in candidates:
        print(
            f"{c['name']}\t[{c['install_method']:>6}]  "
            f"{c['display_name']:<{max_disp}}  {c['description']}"
        )


if __name__ == "__main__":
    main()
