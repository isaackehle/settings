#!/usr/bin/env bash
# ============================================================================
#  homelab-migrate.sh — one-time migration: extract homelab repo from settings
#
#  Run this ONCE from your terminal on discovery (or any machine with gh + git).
#  After it completes, delete this script from the settings repo.
#
#  Prerequisites:
#    gh auth login        (if not already authenticated)
#    brew install gh      (if gh not installed)
# ============================================================================
set -euo pipefail

SETTINGS_DIR="$(cd "$(dirname "$0")" && pwd)"
HOMELAB_DIR="${HOME}/code/isaackehle/homelab"

echo "==> Settings repo: ${SETTINGS_DIR}"
echo "==> Homelab dest:  ${HOMELAB_DIR}"
echo ""

# Bail if homelab already exists
if [[ -d "$HOMELAB_DIR" ]]; then
  echo "ERROR: ${HOMELAB_DIR} already exists. Remove it first if you want to re-run."
  exit 1
fi

# ── 1. Extract ai/ history into homelab-split branch ─────────────────────────
echo "==> Splitting ai/ history (may take 30-60s)..."
cd "$SETTINGS_DIR"
git branch -D homelab-split 2>/dev/null || true
git subtree split --prefix=ai -b homelab-split

# ── 2. Init homelab repo from split ──────────────────────────────────────────
echo ""
echo "==> Creating ${HOMELAB_DIR}..."
mkdir -p "$HOMELAB_DIR"
git -C "$HOMELAB_DIR" init -b main
git -C "$HOMELAB_DIR" pull "$SETTINGS_DIR" homelab-split

echo ""
echo "==> homelab contents:"
ls "$HOMELAB_DIR"
echo "    $(git -C "$HOMELAB_DIR" log --oneline | wc -l | tr -d ' ') commits"

# ── 3. Create private GitHub repo and push ────────────────────────────────────
echo ""
echo "==> Creating private GitHub repo isaackehle/homelab..."
gh repo create isaackehle/homelab \
  --private \
  --description "Local network and AI inference configuration" \
  --source "$HOMELAB_DIR" \
  --remote origin \
  --push

echo ""
echo "==> Pushed to github.com/isaackehle/homelab"

# ── 4. Remove ai/ from settings repo ─────────────────────────────────────────
echo ""
echo "==> Removing ai/ from settings repo..."
cd "$SETTINGS_DIR"
git rm -r ai/
git -c user.name="$(git config user.name)" \
    -c user.email="$(git config user.email)" \
    commit -m "chore: move ai/ to isaackehle/homelab repo

AI and local network config extracted to a dedicated private repo.
See: https://github.com/isaackehle/homelab"

# ── 5. Clean up ───────────────────────────────────────────────────────────────
git branch -D homelab-split
git rm homelab-migrate.sh 2>/dev/null || rm "$0"
git -c user.name="$(git config user.name)" \
    -c user.email="$(git config user.email)" \
    commit -m "chore: remove homelab migration script"

echo ""
echo "==> Push settings to GitHub:"
echo "    git -C ${SETTINGS_DIR} push"
echo ""
echo "==> Clone homelab on other machines:"
echo "    git clone git@github.com:isaackehle/homelab.git ~/code/isaackehle/homelab"
echo ""
echo "Done."
