#!/opt/homebrew/bin/bash
# setup-skills.sh — Establish ~/.skills/ as the canonical skill hub
#
# ~/.skills/ aggregates all skills into one place, then both
#   ~/.agents/skills  ->  ~/.skills/
#   ~/.claude/skills  ->  ~/.skills/
# are replaced with symlinks so every agent (Claude Code, Pi, Cline,
# OpenCode, etc.) finds all skills regardless of which path it uses.
#
# This means `npx skills add -g -a '*' <package>` installs directly into
# ~/.skills/ from any agent target.
#
# Sources (later wins on name conflict):
#   1. ~/.agents/skills/       — Agent-installed skill packages
#   2. ~/code/isaackehle/skills/ — Isaac's custom skill collection
#
# Run this on any new machine after cloning the settings repo.

set -euo pipefail

SKILL_DIR="$HOME/.skills"

# We read the original directories *before* replacing them with symlinks,
# so there is no circular reference.
SOURCE_DIRS=()

if [ -d "$HOME/.agents/skills" ] && [ ! -L "$HOME/.agents/skills" ]; then
  SOURCE_DIRS+=("$HOME/.agents/skills")
fi

if [ -d "$HOME/code/isaackehle/skills" ]; then
  SOURCE_DIRS+=("$HOME/code/isaackehle/skills")
fi

install_skills() {
  echo "  Building $SKILL_DIR from:"
  for src in "${SOURCE_DIRS[@]}"; do
    echo "    $src"
  done
  echo ""

  mkdir -p "$SKILL_DIR"

  local total=0 linked=0
  for src in "${SOURCE_DIRS[@]}"; do
    for d in "$src"/*/; do
      [ -d "$d" ] || continue
      name=$(basename "$d")
      total=$((total + 1))
      if [ -f "$d/SKILL.md" ]; then
        ln -sfn "$d" "$SKILL_DIR/$name" 2>/dev/null
        linked=$((linked + 1))
        echo "    ✓ $name"
      else
        echo "    - $name (no SKILL.md, skipped)"
      fi
    done
  done

  echo ""
  echo "  $linked skills linked into $SKILL_DIR (from $total candidates)"
}

replace_with_symlink() {
  local target="$1" link_name="$2"
  if [ -L "$link_name" ]; then
    local current
    current=$(readlink "$link_name")
    if [ "$current" = "$target" ]; then
      echo "  $link_name already -> $target"
      return 0
    fi
    echo "  Updating $link_name symlink (was -> $current)"
    ln -sfn "$target" "$link_name"
  elif [ -d "$link_name" ]; then
    echo "  Replacing $link_name directory with symlink to $target"
    rm -rf "$link_name"
    ln -sfn "$target" "$link_name"
  else
    echo "  Creating $link_name -> $target"
    ln -sfn "$target" "$link_name"
  fi
  echo "  $link_name -> $target"
}

verify() {
  echo ""
  echo "=== Verification ==="
  local count
  count=$(ls -1 "$SKILL_DIR" 2>/dev/null | wc -l | tr -d ' ')
  echo "  Skills in $SKILL_DIR: $count"
  echo ""

  local symlinks=("$HOME/.agents/skills" "$HOME/.claude/skills")
  for link in "${symlinks[@]}"; do
    if [ -L "$link" ]; then
      local target
      target=$(readlink "$link")
      echo "  $link -> $target"
    else
      echo "  $link (not a symlink — not managed by this script)"
    fi
  done

  echo ""
  for d in "$SKILL_DIR"/*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    target=$(readlink "$d" 2>/dev/null || echo "(not a symlink)")
    echo "    $name -> $target"
  done
}

main() {
  echo "=== Skills Hub Setup ==="
  echo ""
  echo "  Target: $SKILL_DIR"
  echo ""

  install_skills
  echo "---"
  replace_with_symlink "$SKILL_DIR" "$HOME/.agents/skills"
  echo "---"
  replace_with_symlink "$SKILL_DIR" "$HOME/.claude/skills"
  verify

  echo ""
  echo "  Done. All agent skill paths resolve to $SKILL_DIR."
  echo "  New global skills installed via npx skills will land here."
  echo ""
}

main
