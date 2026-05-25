#!/usr/bin/env python3
"""
tool-scout.py — Unified catalog and repo manager for AI tools, agents, MCPs,
VS Code extensions, and CLI devtools.

Commands:
  list [--category <cat>]          Show catalog entries not yet in repo
  search <query> [--category <cat>]  Search catalog by name/description
  add <name>                       Generate stub + config + register in setup_ai.sh
  update <name>                    Re-generate stub from catalog (preserves custom edits)
  remove <name>                    Delete stub + config dir + unregister from setup_ai.sh
  sync                             Check existing scripts against catalog for drift
  find-brew <query>                Search Homebrew for AI/dev tools
  find-npm <query>                 Search npm for CLI tools / MCP servers
  find-vscode <query>              Search VS Code marketplace (best-effort)

Catalog covers:
  terminal-agents, vscode-extensions, mcp-servers, cli-devtools, ollama-models
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

# ── Inline catalog ──────────────────────────────────────────────────────────
CATALOG = {
    "terminal-agents": [
        {
            "name": "openclaw",
            "display_name": "OpenClaw",
            "description": "Personal AI assistant with 25+ messaging channels",
            "github": "openclaw/openclaw",
            "install_methods": [
                {"method": "npm", "command": "npm install -g openclaw@latest"},
                {"method": "pnpm", "command": "pnpm add -g openclaw@latest"},
            ],
            "binary": "openclaw",
            "setup_command": "openclaw onboard --install-daemon",
            "config_dir": "~/.openclaw",
            "config_file": "openclaw.json",
            "config_ext": "json",
        },
        {
            "name": "zeroclaw",
            "display_name": "ZeroClaw",
            "description": "Fast Rust AI assistant — OpenClaw successor",
            "github": "zeroclaw-labs/zeroclaw",
            "install_methods": [
                {"method": "curl", "command": "curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | bash"},
            ],
            "binary": "zeroclaw",
            "setup_command": "zeroclaw onboard",
            "config_dir": "~/.zeroclaw",
            "config_file": "config.toml",
            "config_ext": "toml",
        },
        {
            "name": "ironclaw",
            "display_name": "IronClaw",
            "description": "Privacy-first Agent OS with 13 security layers",
            "github": "nearai/ironclaw",
            "install_methods": [
                {"method": "brew", "command": "brew install ironclaw"},
                {"method": "cargo", "command": "cargo install ironclaw"},
            ],
            "binary": "ironclaw",
            "setup_command": "ironclaw onboard",
            "config_dir": "~/.ironclaw",
            "config_file": ".env",
            "config_ext": "env",
        },
        {
            "name": "hermes",
            "display_name": "Hermes",
            "description": "Self-improving AI agent from Nous Research",
            "github": "NousResearch/hermes-agent",
            "install_methods": [
                {"method": "curl", "command": "curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash"},
            ],
            "binary": "hermes",
            "setup_command": "hermes setup",
            "config_dir": "~/.hermes",
            "config_file": "config.yaml",
            "config_ext": "yaml",
        },
        {
            "name": "picoclaw",
            "display_name": "PicoClaw",
            "description": "Tiny AI for embedded/edge devices",
            "github": "picoclaw-labs/picoclaw",
            "install_methods": [
                {"method": "go", "command": "go install github.com/picoclaw-labs/picoclaw@latest"},
            ],
            "binary": "picoclaw",
            "setup_command": None,
            "config_dir": "~/.config/picoclaw",
            "config_file": "config.toml",
            "config_ext": "toml",
        },
        {
            "name": "llm",
            "display_name": "LLM",
            "description": "Simon Willison's swiss-army-knife CLI for LLMs",
            "github": "simonw/llm",
            "install_methods": [{"method": "brew", "command": "brew install llm"}],
            "binary": "llm",
            "setup_command": None,
            "config_dir": "~/.config/io.datasette.llm",
            "config_file": "default_model.txt",
            "config_ext": "txt",
        },
        {
            "name": "fabric",
            "display_name": "Fabric",
            "description": "AI CLI workflow toolkit with 100+ patterns",
            "github": "danielmiessler/fabric",
            "install_methods": [{"method": "brew", "command": "brew install fabric-ai"}],
            "binary": "fabric-ai",
            "setup_command": "fabric --setup",
            "config_dir": "~/.config/fabric",
            "config_file": "",
            "config_ext": "",
        },
        {
            "name": "aichat",
            "display_name": "AIChat",
            "description": "All-in-one LLM CLI with local and remote support",
            "github": "sigoden/aichat",
            "install_methods": [{"method": "brew", "command": "brew install aichat"}],
            "binary": "aichat",
            "setup_command": None,
            "config_dir": "~/.config/aichat",
            "config_file": "config.yaml",
            "config_ext": "yaml",
        },
        {
            "name": "goose",
            "display_name": "Goose",
            "description": "Block's open-source AI coding agent",
            "github": "block/goose",
            "install_methods": [{"method": "brew", "command": "brew install block/tap/goose"}],
            "binary": "goose",
            "setup_command": "goose --setup",
            "config_dir": "~/.config/goose",
            "config_file": "config.yaml",
            "config_ext": "yaml",
        },
        {
            "name": "plandex",
            "display_name": "Plandex",
            "description": "Terminal AI planner for multi-file coding tasks",
            "github": "plandex-ai/plandex",
            "install_methods": [{"method": "curl", "command": "curl -sL https://plandex.ai/install.sh | bash"}],
            "binary": "plandex",
            "setup_command": None,
            "config_dir": "~/.config/plandex",
            "config_file": "config.env",
            "config_ext": "env",
        },
    ],
    "vscode-extensions": [
        {"name": "continue", "display_name": "Continue", "description": "Open-source AI code assistant", "marketplace_id": "Continue.continue", "install_command": "code --install-extension Continue.continue"},
        {"name": "copilot", "display_name": "GitHub Copilot", "description": "GitHub Copilot extension", "marketplace_id": "GitHub.copilot", "install_command": "code --install-extension GitHub.copilot"},
        {"name": "kilocode", "display_name": "Kilo Code", "description": "Fast AI coding assistant", "marketplace_id": "KiloCode.kilocode", "install_command": "code --install-extension KiloCode.kilocode"},
        {"name": "cline", "display_name": "Cline", "description": "Autonomous coding agent for VS Code", "marketplace_id": "saoudrizwan.claude-dev", "install_command": "code --install-extension saoudrizwan.claude-dev"},
        {"name": "zoocode", "display_name": "Zoo Code", "description": "VS Code settings merge for Zoo Code config", "marketplace_id": None, "install_command": None},
    ],
    "mcp-servers": [
        {"name": "mcp-playwright", "display_name": "MCP Playwright", "description": "Browser automation MCP server", "install_command": "npx @anthropic-ai/mcp-playwright"},
        {"name": "mcp-filesystem", "display_name": "MCP Filesystem", "description": "Secure file access MCP server", "install_command": "npx @modelcontextprotocol/server-filesystem"},
    ],
}

# Flatten catalog for lookup
ALL_ENTRIES = []
for cat, items in CATALOG.items():
    for item in items:
        item["category"] = cat
        ALL_ENTRIES.append(item)


def _repo_root() -> Path:
    # When run from repo root or scripts/
    cwd = Path.cwd()
    if (cwd / "setup_ai.sh").exists():
        return cwd
    if (cwd.parent / "setup_ai.sh").exists():
        return cwd.parent
    # Fallback: directory containing this script
    script_dir = Path(__file__).parent
    if (script_dir.parent / "setup_ai.sh").exists():
        return script_dir.parent
    if (script_dir / "setup_ai.sh").exists():
        return script_dir
    return cwd  # best effort


def _existing_names(repo_root: Path) -> set:
    """Collect tool names already present in the repo."""
    names = set()
    ai_dir = repo_root / "2-ai"
    if ai_dir.exists():
        for p in ai_dir.iterdir():
            if p.is_file() and p.suffix == ".sh" and p.name not in {"aider.sh", "claude.sh"}:
                names.add(p.stem)
    # Also check setup_ai.sh references
    setup = repo_root / "setup_ai.sh"
    if setup.exists():
        text = setup.read_text()
        for line in text.splitlines():
            if 'setup:' in line and ')' in line:
                m = re.search(r'setup:([a-z0-9_-]+)\)', line)
                if m:
                    names.add(m.group(1))
    return names


def _generate_bash_stub(entry: dict) -> str:
    """Generate a 2-ai/<name>.sh installation stub from catalog metadata."""
    name = entry["name"]
    display = entry.get("display_name", name)
    binary = entry.get("binary", name)
    cfg_dir = entry.get("config_dir", f"~/.config/{name}").replace("~/", "$HOME/")
    cfg_file = entry.get("config_file", "")
    cfg_ext = entry.get("config_ext", "")
    docs = f"https://github.com/{entry.get('github', '')}"
    name_us = name.replace("-", "_")

    install_methods = entry.get("install_methods", [])
    if not install_methods:
        install_block = '    log_error "No install method defined in catalog"\n    return 1'
    else:
        lines = []
        for im in install_methods:
            method = im["method"]
            cmd = im["command"]
            if method in ("brew", "npm", "pip", "go", "cargo"):
                lines.append(f"""    if {cmd}; then
        log_status "{display} installed via {method}"
        return 0
    else
        log_warning "{method} install failed — trying next method"
    fi""")
            else:
                lines.append(f"""    read -p "  Run the {display} installer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped {display} installer"
        return 1
    fi
    if {cmd}; then
        log_status "{display} installed"
        return 0
    else
        log_warning "Installer failed — trying next method"
    fi""")

        # Chain with fallbacks
        fallback = "\n".join(lines)
        install_block = f"{fallback}\n    log_error \"Failed to install {display}\"\n    return 1"

    # Config deployment block
    config_deploy = ""
    if cfg_file:
        config_deploy = f"""
    # Deploy config (profile-specific → default)
    mkdir -p "${name_us}_cfg_dir"
    local src_cfg
    src_cfg="${{SETTINGS_BASE}}/2-ai/profiles/${{MACHINE_PROFILE}}/{name}/{cfg_file}"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${{SETTINGS_BASE}}/2-ai/profiles/default/{name}/{cfg_file}"
    fi
    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "${name_us}_cfg"
        chmod 600 "${name_us}_cfg"
        log_status "Config deployed to ${name_us}_cfg"
    else
        log_warning "No {display} config found"
    fi"""

    # Setup command hint
    setup_hint = ""
    setup_cmd = entry.get("setup_command")
    if setup_cmd:
        setup_hint = f"""
    # Offer to run setup wizard
    if [ ! -f "${name_us}_cfg" ]; then
        echo ""
        read -p "  Run '{setup_cmd}' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            {setup_cmd} || log_warning "{display} setup may need manual re-run"
        fi
    fi"""

    # Backup / restore
    if cfg_file:
        backup_restore = f"""
backup_{name_us}() {{
    if [ -f "${name_us}_cfg" ]; then
        cp -r "{cfg_dir}" "${{BACKUP_DIR}}/{name}_backup_${{DATE}}"
        cp "${name_us}_cfg" "${{BACKUP_DIR}}/{name}_config_backup_${{DATE}}.{cfg_ext}"
        log_status "Backed up {display} config"
    fi
}}

restore_{name_us}() {{
    local latest_dir latest_file
    latest_dir=$(ls -dt "${{BACKUP_DIR}}"/{name}_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${{BACKUP_DIR}}"/{name}_config_backup_*.{cfg_ext} 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "{cfg_dir}"
        cp -R "$latest_dir/"* "{cfg_dir}/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "{cfg_dir}"
        cp "$latest_file" "{cfg_dir}/{cfg_file}"
        log_status "Restored {display} config from $(basename "$latest_file")"
    else
        log_warning "No {display} backup found in ${{BACKUP_DIR}}"
    fi
}}"""
    else:
        backup_restore = f"""
backup_{name_us}() {{
    if [ -d "{cfg_dir}" ]; then
        cp -r "{cfg_dir}" "${{BACKUP_DIR}}/{name}_backup_${{DATE}}"
        log_status "Backed up {display} config"
    fi
}}

restore_{name_us}() {{
    local latest
    latest=$(ls -dt "${{BACKUP_DIR}}"/{name}_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "{cfg_dir}"
        cp -R "$latest/"* "{cfg_dir}/" 2>/dev/null || true
        log_status "Restored {display} config from $(basename "$latest")"
    else
        log_warning "No {display} backup found in ${{BACKUP_DIR}}"
    fi
}}"""

    stub = f"""if [ -z "${{SETTINGS_BASE:-}}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${{BASH_SOURCE[0]}}")/../" \&\& pwd)"
fi
. "${{SETTINGS_BASE}}/helpers.sh"

# ---------------------------------------------------------------------------
# {display} — {entry.get('description', '')}
# Repo:     {docs}
# ---------------------------------------------------------------------------

{name_us}_cfg_dir="{cfg_dir}"
{name_us}_cfg="${name_us}_cfg_dir/{cfg_file}"

verify_{name_us}() {{
    if ! command -v {binary} > /dev/null 2>\&1; then
        log_warning "{display} not found in PATH"
        return 1
    fi
    log_status "{display} found: $({binary} --version 2>/dev/null || echo installed)"
    return 0
}}

_install_{name_us}() {{
    log_info "Installing {display}..."
{install_block}
}}

setup_{name_us}() {{
    log_info "Setting up {display}..."
    verify_{name_us} || _install_{name_us} || {{ log_error "Failed to install {display}"; return 1; }}
{config_deploy}{setup_hint}
    log_info ""
    log_info "=== {display} ==="
    log_info "Binary:   {binary}"
    log_info "Config:   {cfg_dir}"
    log_info "Docs:     {docs}"
    log_info ""
}}
{backup_restore}

if [[ "${{BASH_SOURCE[0]}}" == "${{0}}" ]]; then
    setup_{name_us}
fi
"""
    return stub


def _patch_setup_ai(repo_root: Path, name: str, mode: str = "add") -> None:
    """Add or remove a tool from setup_ai.sh arrays and source lines."""
    setup_path = repo_root / "setup_ai.sh"
    text = setup_path.read_text()

    source_line = f'. "${{SETTINGS_BASE}}/2-ai/{name}.sh"'
    setup_case = f"  setup:{name}) setup_{name.replace('-', '_')} ;;"
    restore_case = f"  restore:{name}) restore_{name.replace('-', '_')} ;;"
    backup_case = f"  backup:{name}) backup_{name.replace('-', '_')} ;;"

    if mode == "add":
        # Add source line if missing
        if source_line not in text:
            # Insert after the last 2-ai source line
            lines = text.splitlines()
            last_idx = max((i for i, l in enumerate(lines) if "2-ai/" in l and l.strip().startswith(".")), default=-1)
            if last_idx >= 0:
                lines.insert(last_idx + 1, source_line)
                text = "\n".join(lines) + "\n"

        # Add TOOL_GROUPS entry
        group = None
        for cat, items in CATALOG.items():
            if any(i["name"] == name for i in items):
                group = cat
                break

        if group == "terminal-agents":
            # Add to terminal-agents list
            pattern = r'(\["terminal-agents"\]="[^"]+)"'
            if re.search(pattern, text):
                text = re.sub(pattern, rf'\1 {name}"', text)

        # Add setup/restore/backup cases
        for case_line in (setup_case, restore_case, backup_case):
            if case_line not in text:
                # Find the block and append
                block_marker = case_line.split(")[0] + ")"
                text = text.replace(block_marker, f"{block_marker}\n{case_line}", 1)

    elif mode == "remove":
        text = re.sub(rf'^{re.escape(source_line)}\n', '', text, flags=re.MULTILINE)
        text = re.sub(rf'^\s+{re.escape(setup_case)}\n', '', text, flags=re.MULTILINE)
        text = re.sub(rf'^\s+{re.escape(restore_case)}\n', '', text, flags=re.MULTILINE)
        text = re.sub(rf'^\s+{re.escape(backup_case)}\n', '', text, flags=re.MULTILINE)
        # Remove from TOOL_GROUPS
        text = re.sub(rf'\b{name}\b\s*', '', text)

    setup_path.write_text(text)


def cmd_list(args):
    repo = _repo_root()
    existing = _existing_names(repo)
    cat_filter = args.category

    results = []
    for entry in ALL_ENTRIES:
        if entry["name"] in existing:
            continue
        if cat_filter and entry.get("category") != cat_filter:
            continue
        results.append(entry)

    if not results:
        print("No new tools found — your catalog is current.")
        if args.json:
            print("[]")
        return

    if args.json:
        print(json.dumps(results, indent=2))
        return

    max_name = max(len(e["name"]) for e in results)
    max_disp = max(len(e.get("display_name", e["name"])) for e in results)
    for e in results:
        cat = e.get("category", "?")
        disp = e.get("display_name", e["name"])
        print(f"{e['name']:<{max_name}}  [{cat}]  {disp:<{max_disp}}  {e['description']}")


def cmd_search(args):
    query = args.query.lower()
    cat_filter = args.category
    results = []
    for entry in ALL_ENTRIES:
        haystack = f"{entry['name']} {entry.get('display_name','')} {entry['description']}".lower()
        if query not in haystack:
            continue
        if cat_filter and entry.get("category") != cat_filter:
            continue
        results.append(entry)

    if not results:
        print(f"No catalog entries match '{args.query}'")
        return

    for e in results:
        print(f"{e['name']}  [{e.get('category','?')}]  {e.get('display_name', e['name'])} — {e['description']}")


def cmd_add(args):
    entry = next((e for e in ALL_ENTRIES if e["name"] == args.name), None)
    if not entry:
        print(f"Error: '{args.name}' not found in catalog.", file=sys.stderr)
        print(f"Run 'tool-scout search {args.name}' or 'tool-scout list' to find it.", file=sys.stderr)
        sys.exit(1)

    repo = _repo_root()
    dest = repo / "2-ai" / f"{args.name}.sh"
    if dest.exists() and not args.force:
        print(f"Error: {dest} already exists. Use --force to overwrite.", file=sys.stderr)
        sys.exit(1)

    # Write stub
    stub = _generate_bash_stub(entry)
    dest.write_text(stub)
    dest.chmod(0o755)
    print(f"Created {dest}")

    # Create default config dir
    cfg_dir = repo / "2-ai" / "profiles" / "default" / args.name
    cfg_dir.mkdir(parents=True, exist_ok=True)
    (cfg_dir / ".gitkeep").touch()
    print(f"Prepared config dir: {cfg_dir}")

    # Patch setup_ai.sh
    _patch_setup_ai(repo, args.name, mode="add")
    print(f"Registered {args.name} in setup_ai.sh")
    print("\nNext steps:")
    print(f"  1. Review {dest}")
    print(f"  2. Add profile-specific configs under 2-ai/profiles/<machine>/{args.name}/")
    print("  3. Run syntax check: bash -n 2-ai/{}.sh".format(args.name))
    print("  4. Commit the changes")


def cmd_remove(args):
    repo = _repo_root()
    dest = repo / "2-ai" / f"{args.name}.sh"
    if not dest.exists():
        print(f"Error: {dest} does not exist.", file=sys.stderr)
        sys.exit(1)

    if not args.yes:
        ans = input(f"Remove {args.name}? This deletes {dest} and unregisters from setup_ai.sh [y/N]: ")
        if ans.lower() != "y":
            print("Aborted.")
            return

    dest.unlink()
    print(f"Removed {dest}")

    cfg_dir = repo / "2-ai" / "profiles" / "default" / args.name
    if cfg_dir.exists():
        import shutil
        shutil.rmtree(cfg_dir)
        print(f"Removed {cfg_dir}")

    _patch_setup_ai(repo, args.name, mode="remove")
    print(f"Unregistered {args.name} from setup_ai.sh")


def cmd_sync(args):
    repo = _repo_root()
    existing = _existing_names(repo)
    catalog_names = {e["name"] for e in ALL_ENTRIES}

    orphan = existing - catalog_names
    missing = catalog_names - existing

    if orphan:
        print("Scripts with no catalog entry (custom/stale):")
        for n in sorted(orphan):
            print(f"  {n}")
    if missing:
        print("Catalog entries missing repo scripts:")
        for n in sorted(missing):
            print(f"  {n}")
    if not orphan and not missing:
        print("All catalog entries present. No orphan scripts.")


def cmd_find_brew(args):
    print(f"Searching Homebrew for '{args.query}'...")
    try:
        subprocess.run(["brew", "search", args.query], check=False)
    except FileNotFoundError:
        print("brew not found in PATH", file=sys.stderr)


def cmd_find_npm(args):
    print(f"Searching npm for '{args.query}'...")
    try:
        subprocess.run(["npm", "search", args.query, "--limit", "20"], check=False)
    except FileNotFoundError:
        print("npm not found in PATH", file=sys.stderr)


def cmd_find_vscode(args):
    print(f"Searching VS Code marketplace for '{args.query}'...")
    print("(Use 'code --install-extension <id>' after finding the ID)")
    try:
        # Best-effort: list installed extensions that match
        result = subprocess.run(
            ["code", "--list-extensions"],
            capture_output=True, text=True, check=False
        )
        matches = [l for l in result.stdout.splitlines() if args.query.lower() in l.lower()]
        if matches:
            print("Installed extensions matching query:")
            for m in matches:
                print(f"  {m}")
        else:
            print("No installed extensions match. Try web search:")
            print(f"  https://marketplace.visualstudio.com/search?term={args.query}")
    except FileNotFoundError:
        print("code CLI not found in PATH", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description="Unified tool catalog and repo manager")
    sub = parser.add_subparsers(dest="cmd", help="Command")

    p_list = sub.add_parser("list", help="List catalog entries not in repo")
    p_list.add_argument("--category", help="Filter by category")
    p_list.add_argument("--json", action="store_true", help="JSON output")

    p_search = sub.add_parser("search", help="Search catalog")
    p_search.add_argument("query", help="Search term")
    p_search.add_argument("--category", help="Filter by category")

    p_add = sub.add_parser("add", help="Generate stub and register in setup_ai.sh")
    p_add.add_argument("name", help="Tool name from catalog")
    p_add.add_argument("--force", action="store_true", help="Overwrite existing stub")

    p_remove = sub.add_parser("remove", help="Delete stub and unregister")
    p_remove.add_argument("name", help="Tool name")
    p_remove.add_argument("--yes", "-y", action="store_true", help="Skip confirmation")

    p_sync = sub.add_parser("sync", help="Check repo against catalog for drift")

    p_brew = sub.add_parser("find-brew", help="Search Homebrew")
    p_brew.add_argument("query", help="Search term")

    p_npm = sub.add_parser("find-npm", help="Search npm")
    p_npm.add_argument("query", help="Search term")

    p_vscode = sub.add_parser("find-vscode", help="Search VS Code marketplace (best effort)")
    p_vscode.add_argument("query", help="Search term")

    args = parser.parse_args()

    if args.cmd == "list":
        cmd_list(args)
    elif args.cmd == "search":
        cmd_search(args)
    elif args.cmd == "add":
        cmd_add(args)
    elif args.cmd == "remove":
        cmd_remove(args)
    elif args.cmd == "sync":
        cmd_sync(args)
    elif args.cmd == "find-brew":
        cmd_find_brew(args)
    elif args.cmd == "find-npm":
        cmd_find_npm(args)
    elif args.cmd == "find-vscode":
        cmd_find_vscode(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
