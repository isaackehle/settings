#!/usr/bin/env bash
# ============================================================================
#  build.sh — pull latest llama.cpp, rebuild llama-server, deploy
#
#  Usage:
#    ./build.sh               # full cycle: pull → build → deploy
#    ./build.sh --build-only  # skip git pull, just rebuild
#    ./build.sh --deploy-only # skip build, just copy existing binary
#    ./build.sh --check       # just verify the installed binary supports router
# ============================================================================
set -euo pipefail

LLAMA_SRC="${LLAMA_SRC:-$HOME/code/llama.cpp}"
BUILD_DIR="$LLAMA_SRC/build"
DEPLOY_TARGET="/usr/local/bin/llama-server"
MODELS_DIR="/usr/local/lib/llama-models"
PLIST_LABEL="org.kehle.llama-router"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

# ── helpers ──────────────────────────────────────────────────────────────────
info()  { printf "==> %s\n" "$*"; }
ok()    { printf "    OK: %s\n" "$*"; }
warn()  { printf "    WARNING: %s\n" "$*"; }

# ── check mode ───────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--check" ]]; then
  if ! command -v llama-server >/dev/null 2>&1; then
    warn "llama-server not found at $DEPLOY_TARGET"
    exit 1
  fi
  echo "    Installed at: $(which llama-server)"
  echo "    Version:      $(llama-server --version 2>&1 || true)"
  if llama-server --help 2>&1 | grep -q -- "--models-preset"; then
    ok "--models-preset is supported."
    exit 0
  else
    warn "--models-preset NOT supported. Rebuild with build.sh"
    exit 1
  fi
fi

# ── git pull ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" != "--build-only" ]] && [[ "${1:-}" != "--deploy-only" ]]; then
  if [[ -d "$LLAMA_SRC/.git" ]]; then
    info "Pulling latest llama.cpp from GitHub..."
    cd "$LLAMA_SRC"
    git pull --rebase
  else
    info "Cloning llama.cpp..."
    git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_SRC"
  fi
else
  info "Skipping git pull ($1)"
fi

# ── build ────────────────────────────────────────────────────────────────────
if [[ "${1:-}" != "--deploy-only" ]]; then
  info "Configuring build (Metal, Release)..."
  cmake -S "$LLAMA_SRC" -B "$BUILD_DIR" \
    -DGGML_METAL=ON \
    -DGGML_METAL_EMBED_LIBRARY=ON \
    -DCMAKE_BUILD_TYPE=Release

  info "Building llama-server ($(sysctl -n hw.ncpu) cores)..."
  cmake --build "$BUILD_DIR" --target llama-server -j "$(sysctl -n hw.ncpu)"
else
  info "Skipping build ($1)"
fi

# ── deploy ───────────────────────────────────────────────────────────────────
info "Deploying to $DEPLOY_TARGET..."
if [[ -w "$(dirname "$DEPLOY_TARGET")" ]]; then
  cp "$BUILD_DIR/bin/llama-server" "$DEPLOY_TARGET"
else
  sudo cp "$BUILD_DIR/bin/llama-server" "$DEPLOY_TARGET"
fi
ok "llama-server deployed."

# ── verify router support ────────────────────────────────────────────────────
info "Verifying router CLI flags..."
if "$DEPLOY_TARGET" --help 2>&1 | grep -q -- "--models-preset"; then
  ok "--models-preset is supported."
else
  warn "--models-preset NOT found in this build."
  warn "You may need a newer llama.cpp commit or a different build config."
fi

# ── ensure models directory exists ───────────────────────────────────────────
if [[ ! -d "$MODELS_DIR" ]]; then
  info "Creating $MODELS_DIR..."
  sudo mkdir -p "$MODELS_DIR"
  sudo chown "$(whoami):staff" "$MODELS_DIR"
  ok "Models directory ready at $MODELS_DIR"
fi

# ── restart hint ─────────────────────────────────────────────────────────────
if [[ -f "$PLIST_DST" ]]; then
  echo ""
  echo "==> Restart the LaunchAgent to pick up the new binary:"
  echo "    launchctl bootout gui/$(id -u)/$PLIST_LABEL 2>/dev/null || true"
  echo "    launchctl bootstrap gui/$(id -u) \"$PLIST_DST\""
  echo ""
  echo "    Test: curl -s http://127.0.0.1:10000/v1/models"
fi

echo "==> Done."
