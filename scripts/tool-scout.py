#!/usr/bin/env python3
"""
tool-scout.py — Unified catalog and repo manager for AI tools, agents, MCPs,
VS Code extensions, and CLI devtools.

Reads catalog from scripts/tool-catalog.json (human-editable, PR-friendly).

Commands:
  list [--category <cat>]        Show catalog entries not yet in repo
  search <query> [--category]     Search catalog by name/description
  add <name>                      Generate stub + config dir (manual register)
  remove <name>                   Delete stub + config dir
  sync                            Check repo against catalog for drift
  catalog-show                    Print full catalog (JSON)
  find-brew <query>               Search Homebrew for AI/dev tools
  find-npm <query>                Search npm for CLI tools
  find-vscode <query>             Search VS Code marketplace (best effort)
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

CATALOG_PATH = Path(__file__).parent / "tool-catalog.json"


def _load_catalog() -> dict:
    if not CATALOG_PATH.exists():
        print(f"Catalog not found: {CATALOG_PATH}", file=sys.stderr)
        sys.exit(1)
    with open(CATALOG_PATH) as f:
        return json.load(f)


def _repo_root() -> Path:
    cwd = Path.cwd()
    if (cwd / "setup_ai.sh").exists():
        return cwd
    if (cwd.parent / "setup_ai.sh").exists():
        return cwd.parent
    script_dir = Path(__file__).parent
    if (script_dir.parent / "setup_ai.sh").exists():
        return script_dir.parent
    if (script_dir / "setup_ai.sh").exists():
        return script_dir
    return cwd


def _existing_names(repo_root: Path) -> set:
    names = set()
    ai_dir = repo_root / "2-ai"
    if ai_dir.exists():
        for p in ai_dir.iterdir():
            if p.is_file() and p.suffix == ".sh":
                names.add(p.stem)
    return names


def _flatten(catalog: dict) -> list:
    return catalog.get("tools", [])


# ── Stub generation ─────────────────────────────────────────────────────────

STUB_HEADER = r'''if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# __DISPLAY__ — __DESCRIPTION__
# Repo:     https://github.com/__GITHUB__
# ---------------------------------------------------------------------------

__NAME_US___cfg_dir="__CFG_DIR__"
__NAME_US___cfg="$__NAME_US___cfg_dir/__CFG_FILE__"

verify___NAME_US__() {
    if ! command -v __BINARY__ >/dev/null 2>&1; then
        log_warning "__DISPLAY__ not found in PATH"
        return 1
    fi
    log_status "__DISPLAY__ found: $(__BINARY__ --version 2>/dev/null || echo installed)"
    return 0
}

_install___NAME_US__() {
    log_info "Installing __DISPLAY__..."
__INSTALL_BLOCK__
}

setup___NAME_US__() {
    log_info "Setting up __DISPLAY__..."
    verify___NAME_US__ || _install___NAME_US__ || { log_error "Failed to install __DISPLAY__"; return 1; }
__CONFIG_DEPLOY____SETUP_HINT__
    log_info ""
    log_info "=== __DISPLAY__ ==="
    log_info "Binary:   __BINARY__"
    log_info "Config:   __CFG_DIR__"
    log_info "Docs:     https://github.com/__GITHUB__"
    log_info ""
}
__BACKUP_RESTORE__

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup___NAME_US__
fi
'''


def _build_install_block(entry: dict) -> str:
    methods = entry.get("install_methods", [])
    if not methods:
        return '    log_error "No install method defined in catalog"\n    return 1'

    display = entry.get("display_name", entry["name"])
    lines = []
    for im in methods:
        method = im.get("method", "")
        cmd = im.get("command", "")
        if method in ("brew", "npm", "pip", "go", "cargo", "uv"):
            lines.append(
                f'''    if {cmd}; then\n        log_status "{display} installed via {method}"\n        return 0\n    else\n        log_warning "{method} install failed — trying next method"\n    fi'''
            )
        elif method == "docker":
            lines.append(
                f'''    if {cmd}; then\n        log_status "{display} image pulled via Docker"\n        return 0\n    else\n        log_warning "Docker pull failed"\n    fi'''
            )
        else:
            lines.append(
                f'''    read -p "  Run the {display} installer? (y/N) " -n 1 -r\n    echo\n    if [[ ! $REPLY =~ ^[Yy]$ ]]; then\n        log_warning "Skipped {display} installer"\n        return 1\n    fi\n    if {cmd}; then\n        log_status "{display} installed"\n        return 0\n    else\n        log_warning "Installer failed — trying next method"\n    fi'''
            )
    return "\n".join(lines) + f'\n    log_error "Failed to install {display}"\n    return 1'


def _build_config_deploy(entry: dict) -> str:
    cfg_file = entry.get("config_file", "")
    if not cfg_file:
        return ""
    return f'''    # Deploy config (profile-specific → default)
    mkdir -p "{entry['name']}_cfg_dir"
    local src_cfg
    src_cfg="${{SETTINGS_BASE}}/2-ai/profiles/${{MACHINE_PROFILE}}/{entry['name']}/{cfg_file}"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${{SETTINGS_BASE}}/2-ai/profiles/default/{entry['name']}/{cfg_file}"
    fi
    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "{entry['name']}_cfg"
        chmod 600 "{entry['name']}_cfg"
        log_status "Config deployed to {entry['name']}_cfg"
    else
        log_warning "No {entry.get('display_name', entry['name'])} config found"
    fi'''


def _build_setup_hint(entry: dict) -> str:
    cmd = entry.get("setup_command")
    if not cmd:
        return ""
    return f'''\n    # Offer to run setup wizard
    if [ ! -f "{entry['name']}_cfg" ]; then
        echo ""
        read -p "  Run '{cmd}' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            {cmd} || log_warning "{entry.get('display_name', entry['name'])} setup may need manual re-run"
        fi
    fi'''


def _build_backup_restore(entry: dict) -> str:
    name = entry["name"]
    display = entry.get("display_name", name)
    cfg_dir = entry.get("config_dir", f"~/.config/{name}").replace("~/", "$HOME/")
    cfg_file = entry.get("config_file", "")
    cfg_ext = entry.get("config_ext", "")
    name_us = name.replace("-", "_")

    if cfg_file:
        return f'''\nbackup_{name_us}() {{
    if [ -f "{name_us}_cfg" ]; then
        cp -r "{cfg_dir}" "${{BACKUP_DIR}}/{name}_backup_${{DATE}}"
        cp "{name_us}_cfg" "${{BACKUP_DIR}}/{name}_config_backup_${{DATE}}.{cfg_ext}"
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
}}'''
    return f'''\nbackup_{name_us}() {{
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
}}'''


def _generate_stub(entry: dict) -> str:
    name = entry["name"]
    display = entry.get("display_name", name)
    binary = entry.get("binary", name) or name
    cfg_dir = entry.get("config_dir", f"~/.config/{name}").replace("~/", "$HOME/")
    cfg_file = entry.get("config_file", "")
    github = entry.get("github", "")
    name_us = name.replace("-", "_")

    stub = STUB_HEADER
    stub = stub.replace("__NAME__", name)
    stub = stub.replace("__NAME_US__", name_us)
    stub = stub.replace("__DISPLAY__", display)
    stub = stub.replace("__BINARY__", binary)
    stub = stub.replace("__CFG_DIR__", cfg_dir)
    stub = stub.replace("__CFG_FILE__", cfg_file)
    stub = stub.replace("__GITHUB__", github)
    stub = stub.replace("__DESCRIPTION__", entry.get("description", ""))
    stub = stub.replace("__INSTALL_BLOCK__", _build_install_block(entry))
    stub = stub.replace("__CONFIG_DEPLOY__", _build_config_deploy(entry))
    stub = stub.replace("__SETUP_HINT__", _build_setup_hint(entry))
    stub = stub.replace("__BACKUP_RESTORE__", _build_backup_restore(entry))
    return stub


# ── Commands ──────────────────────────────────────────────────────────────

def cmd_list(args):
    catalog = _load_catalog()
    repo = _repo_root()
    existing = _existing_names(repo)
    cat_filter = args.category

    results = [
        e for e in _flatten(catalog)
        if e["name"] not in existing and (not cat_filter or e.get("category") == cat_filter)
    ]

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
        print(f"{e['name']:<{max_name}}  [{e.get('category','?')}]  {e.get('display_name', e['name']):<{max_disp}}  {e['description']}")


def cmd_search(args):
    catalog = _load_catalog()
    query = args.query.lower()
    cat_filter = args.category
    results = [
        e for e in _flatten(catalog)
        if query in f"{e['name']} {e.get('display_name','')} {e['description']}" .lower()
        and (not cat_filter or e.get("category") == cat_filter)
    ]

    if not results:
        print(f"No catalog entries match '{args.query}'")
        return
    for e in results:
        print(f"{e['name']}  [{e.get('category','?')}]  {e.get('display_name', e['name'])} — {e['description']}")


def cmd_add(args):
    catalog = _load_catalog()
    entry = next((e for e in _flatten(catalog) if e["name"] == args.name), None)
    if not entry:
        print(f"Error: '{args.name}' not found in catalog.", file=sys.stderr)
        sys.exit(1)

    repo = _repo_root()
    dest = repo / "2-ai" / f"{args.name}.sh"
    if dest.exists() and not args.force:
        print(f"Error: {dest} already exists. Use --force to overwrite.", file=sys.stderr)
        sys.exit(1)

    stub = _generate_stub(entry)
    dest.write_text(stub)
    dest.chmod(0o755)
    print(f"Created {dest}")

    cfg_dir = repo / "2-ai" / "profiles" / "default" / args.name
    cfg_dir.mkdir(parents=True, exist_ok=True)
    (cfg_dir / ".gitkeep").touch()
    print(f"Prepared config dir: {cfg_dir}")

    print(f"\nRegistered {args.name}")
    print("Next steps:")
    print(f"  1. Source the script in setup_ai.sh:")
    print(f'     . "${{SETTINGS_BASE}}/2-ai/{args.name}.sh"')
    print(f"  2. Add to TOOL_GROUPS in setup_ai.sh")
    print(f"  3. Add setup/restore/backup case entries in setup_ai.sh")
    print(f"  4. Run syntax check: bash -n 2-ai/{args.name}.sh")
    print("  5. Commit the changes")


def cmd_remove(args):
    repo = _repo_root()
    dest = repo / "2-ai" / f"{args.name}.sh"
    if not dest.exists():
        print(f"Error: {dest} does not exist.", file=sys.stderr)
        sys.exit(1)

    if not args.yes:
        ans = input(f"Remove {args.name}? This deletes {dest} [y/N]: ")
        if ans.lower() != "y":
            print("Aborted.")
            return

    dest.unlink()
    print(f"Removed {dest}")

    cfg_dir = repo / "2-ai" / "profiles" / "default" / args.name
    if cfg_dir.exists():
        shutil.rmtree(cfg_dir)
        print(f"Removed {cfg_dir}")


def cmd_sync(args):
    catalog = _load_catalog()
    repo = _repo_root()
    existing = _existing_names(repo)
    catalog_names = {e["name"] for e in _flatten(catalog)}

    orphan = existing - catalog_names
    missing = catalog_names - existing

    if not orphan and not missing:
        print("All catalog entries present. No orphan scripts.")
        return
    if orphan:
        print("Scripts with no catalog entry (custom/stale):")
        for n in sorted(orphan):
            print(f"  {n}")
    if missing:
        print("Catalog entries missing repo scripts:")
        for n in sorted(missing):
            print(f"  {n}")


def cmd_catalog_show(args):
    catalog = _load_catalog()
    if args.category:
        tools = [e for e in _flatten(catalog) if e.get("category") == args.category]
        print(json.dumps({"tools": tools}, indent=2))
    else:
        print(json.dumps(catalog, indent=2))


def _subcommand(cmd_list, args):
    try:
        subprocess.run(cmd_list, check=False)
    except FileNotFoundError:
        print(f"{cmd_list[0]} not found in PATH", file=sys.stderr)


def cmd_find_brew(args):
    _subcommand(["brew", "search", args.query])


def cmd_find_npm(args):
    _subcommand(["npm", "search", args.query, "--limit", "20"])


def cmd_find_vscode(args):
    print(f"Searching VS Code marketplace for '{args.query}'...")
    print("(Use 'code --install-extension <id>' after finding the ID)")
    try:
        result = subprocess.run(["code", "--list-extensions"], capture_output=True, text=True, check=False)
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

    p = sub.add_parser("list", help="List catalog entries not yet in repo")
    p.add_argument("--category", help="Filter by category")
    p.add_argument("--json", action="store_true", help="JSON output")

    p = sub.add_parser("search", help="Search catalog")
    p.add_argument("query", help="Search term")
    p.add_argument("--category", help="Filter by category")

    p = sub.add_parser("add", help="Generate stub (manual register in setup_ai.sh)")
    p.add_argument("name", help="Tool name from catalog")
    p.add_argument("--force", action="store_true", help="Overwrite existing stub")

    p = sub.add_parser("remove", help="Delete stub and config dir")
    p.add_argument("name", help="Tool name")
    p.add_argument("--yes", "-y", action="store_true", help="Skip confirmation")

    p = sub.add_parser("sync", help="Check repo against catalog for drift")

    p = sub.add_parser("catalog-show", help="Print full catalog JSON")
    p.add_argument("--category", help="Filter by category")

    p = sub.add_parser("find-brew", help="Search Homebrew")
    p.add_argument("query", help="Search term")

    p = sub.add_parser("find-npm", help="Search npm")
    p.add_argument("query", help="Search term")

    p = sub.add_parser("find-vscode", help="Search VS Code marketplace")
    p.add_argument("query", help="Search term")

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
    elif args.cmd == "catalog-show":
        cmd_catalog_show(args)
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
