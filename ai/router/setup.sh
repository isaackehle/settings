#!/usr/bin/env bash
# ============================================================================
#  setup.sh — install & wire up llama-server router mode on macOS
#
#  What it does:
#    1. Verifies llama-server is installed and supports router-mode flags.
#    2. Auto-detects the real GGUF filenames in /usr/local/lib/llama-models
#       and rewrites the "model =" paths in models.ini for you.
#    3. Installs the launchd LaunchAgent so the router starts at login.
#
#  Usage:
#    ./setup.sh
# ============================================================================
set -euo pipefail

MODELS_DIR="/usr/local/lib/llama-models"
INI="${MODELS_DIR}/models.ini"
PLIST_SRC="$(cd "$(dirname "$0")" && pwd)/org.kehle.llama-router.plist"
PLIST_DST="${HOME}/Library/LaunchAgents/org.kehle.llama-router.plist"
LOG_DIR="${HOME}/Library/Logs/llama-router"

echo "==> Checking llama-server..."
if ! command -v llama-server >/dev/null 2>&1; then
  echo "    llama-server not found."
  echo "    Run ./build.sh first, or install with:  brew install llama.cpp"
  echo "    Then re-run this script."
  exit 1
fi

echo "==> Verifying router-mode support..."
if llama-server --help 2>&1 | grep -q -- "--models-preset"; then
  echo "    OK: --models-preset is supported."
else
  echo "    WARNING: this build does not advertise --models-preset."
  echo "    Build from source with:  ./build.sh"
  echo "    Continuing anyway — the --models-dir fallback may still work."
fi

mkdir -p "$MODELS_DIR" "$LOG_DIR" "${HOME}/Library/LaunchAgents"

# --- Copy the INI into the models dir if not already there -----------------
if [[ ! -f "$INI" ]]; then
  cp "$(dirname "$0")/models.ini" "$INI"
  echo "==> Copied models.ini -> $INI"
fi

# --- Best-effort auto-detect of real filenames -----------------------------
echo "==> Detecting GGUF files in $MODELS_DIR ..."
shopt -s nullglob
match_one() { # $1 = grep pattern; prints first matching gguf path
  for f in "$MODELS_DIR"/*.gguf; do
    if echo "$(basename "$f")" | grep -qiE "$1"; then echo "$f"; return 0; fi
  done
  return 1
}

patch() { # $1=section-id  $2=detected-path
  [[ -z "${2:-}" ]] && { echo "    (skip $1 — no file matched)"; return; }
  /usr/bin/sed -i '' -E "/^\[$1\]/,/^\[/ s|^model[[:space:]]*=.*|model      = $2|" "$INI"
  echo "    $1  ->  $(basename "$2")"
}

DS=$(match_one 'deepseek.*r1.*32b'        || true)
Q4=$(match_one 'qwen3.*4b.*(it|instruct)' || true)
QC=$(match_one 'qwen3.*coder.*30b'        || true)

patch deepseek-r1-32b "$DS"
patch qwen3-4b-it     "$Q4"
patch qwen3-coder-30b "$QC"

echo "==> Final model paths in $INI:"
grep -E '^\[|^model' "$INI" | sed 's/^/    /'

# --- Install the LaunchAgent ----------------------------------------------
echo "==> Installing LaunchAgent..."
cp "$PLIST_SRC" "$PLIST_DST"

# Reload cleanly (bootout may fail if not loaded — that's fine)
launchctl bootout "gui/$(id -u)/org.kehle.llama-router" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DST"
launchctl enable "gui/$(id -u)/org.kehle.llama-router"

echo ""
echo "==> Done. The router is running and will auto-start at login."
echo "    Test:   curl -s http://127.0.0.1:10000/v1/models"
echo "    Logs:   tail -f $LOG_DIR/llama-router.out.log"
echo "    Stop:   launchctl bootout gui/$(id -u)/org.kehle.llama-router"
echo "    Start:  launchctl bootstrap gui/$(id -u) $PLIST_DST"
