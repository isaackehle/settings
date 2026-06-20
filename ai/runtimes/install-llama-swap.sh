#!/usr/bin/env bash
# ============================================================================
#  install-llama-swap.sh — install llama-swap and migrate from llama-server router
#
#  What it does:
#    1. Detects the current machine's profile
#    2. Installs llama-swap via Homebrew (brew tap + install)
#    3. Copies the profile's llama-swap.yaml to /usr/local/lib/llama-models/
#    4. Unloads the old llama-server router LaunchAgent (if present)
#    5. Installs and loads the new llama-swap LaunchAgent
#
#  Usage:
#    cd ai/runtimes && ./install-llama-swap.sh
#    ./install-llama-swap.sh --profile macbook-m5-64gb   # force specific profile
#    ./install-llama-swap.sh --dry-run                    # preview only
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROFILES_DIR="${REPO_ROOT}/profiles"
ROUTER_DIR="${REPO_ROOT}/router"

MODELS_DIR="/usr/local/lib/llama-models"
LOG_DIR="${HOME}/Library/Logs/llama-swap"
LAUNCHAGENTS_DIR="${HOME}/Library/LaunchAgents"

OLD_PLIST_LABEL="org.kehle.llama-router"
NEW_PLIST_LABEL="com.kehle.llama-swap"
NEW_PLIST_SRC="${ROUTER_DIR}/com.kehle.llama-swap.plist"
NEW_PLIST_DST="${LAUNCHAGENTS_DIR}/${NEW_PLIST_LABEL}.plist"

DRY_RUN=false
PROFILE_OVERRIDE=""

# ── Parse flags ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --profile) PROFILE_OVERRIDE="$2"; shift 2 ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    "$@"
  fi
}

# ── Detect profile ────────────────────────────────────────────────────────────
detect_profile() {
  local hw
  hw=$(sysctl -n hw.model 2>/dev/null || echo "")
  local mem_gb
  mem_gb=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))

  for profile_dir in "${PROFILES_DIR}"/*/; do
    local profile_file="${profile_dir}PROFILE"
    [[ -f "$profile_file" ]] || continue
    local computer_types mem_min mem_max
    computer_types=$(grep '^COMPUTER_TYPES=' "$profile_file" | cut -d= -f2-)
    mem_min=$(grep '^MEMORY_RANGE_MIN=' "$profile_file" | cut -d= -f2-)
    mem_max=$(grep '^MEMORY_RANGE_MAX=' "$profile_file" | cut -d= -f2-)

    # Check memory range
    [[ -z "$mem_min" || -z "$mem_max" ]] && continue
    [[ $mem_gb -ge $mem_min && $mem_gb -lt $mem_max ]] || continue

    # Check computer type glob
    IFS=',' read -ra types <<< "$computer_types"
    for type in "${types[@]}"; do
      if [[ "$hw" == $type ]]; then
        echo "$(basename "$profile_dir")"
        return 0
      fi
    done
  done
  return 1
}

if [[ -n "$PROFILE_OVERRIDE" ]]; then
  PROFILE="$PROFILE_OVERRIDE"
else
  echo "==> Detecting machine profile..."
  if ! PROFILE=$(detect_profile); then
    echo "    ERROR: Could not auto-detect profile."
    echo "    Run with: --profile <profile-name>"
    echo "    Available profiles:"
    ls "${PROFILES_DIR}" | grep -v '\.sh$\|\.md$'
    exit 1
  fi
fi
echo "    Profile: ${PROFILE}"

SWAP_CONFIG_SRC="${PROFILES_DIR}/${PROFILE}/llama-swap.yaml"
if [[ ! -f "$SWAP_CONFIG_SRC" ]]; then
  echo "    ERROR: ${SWAP_CONFIG_SRC} not found."
  echo "    Intel Macs (macbook-intel-2019-16gb) do not have a llama-swap config"
  echo "    (CPU-only inference is too slow for practical use; use openrouter instead)."
  exit 1
fi

# ── Detect Homebrew path ──────────────────────────────────────────────────────
if [[ -x /opt/homebrew/bin/brew ]]; then
  BREW=/opt/homebrew/bin/brew
  BREW_BIN=/opt/homebrew/bin
elif [[ -x /usr/local/bin/brew ]]; then
  BREW=/usr/local/bin/brew
  BREW_BIN=/usr/local/bin
else
  echo "ERROR: Homebrew not found. Install from https://brew.sh"
  exit 1
fi

# ── Install llama-swap ────────────────────────────────────────────────────────
echo ""
echo "==> Installing llama-swap via Homebrew..."
if command -v llama-swap >/dev/null 2>&1; then
  echo "    Already installed: $(llama-swap --version 2>/dev/null || echo 'version unknown')"
else
  run "$BREW" tap mostlygeek/llama-swap
  run "$BREW" install llama-swap
fi

LLAMA_SWAP_BIN="${BREW_BIN}/llama-swap"

# ── Prepare models directory ──────────────────────────────────────────────────
echo ""
echo "==> Preparing models directory: ${MODELS_DIR}"
run mkdir -p "$MODELS_DIR" "$LOG_DIR" "$LAUNCHAGENTS_DIR"

echo "==> Copying llama-swap config..."
echo "    ${SWAP_CONFIG_SRC}"
echo "    -> ${MODELS_DIR}/llama-swap.yaml"
run cp "$SWAP_CONFIG_SRC" "${MODELS_DIR}/llama-swap.yaml"

# ── Unload old llama-server router ────────────────────────────────────────────
echo ""
echo "==> Checking for old llama-server router LaunchAgent..."
OLD_PLIST_DST="${LAUNCHAGENTS_DIR}/${OLD_PLIST_LABEL}.plist"
if launchctl list 2>/dev/null | grep -q "$OLD_PLIST_LABEL"; then
  echo "    Stopping and removing old router (${OLD_PLIST_LABEL})..."
  run launchctl bootout "gui/$(id -u)" "$OLD_PLIST_DST" 2>/dev/null || true
  echo "    Done."
else
  echo "    Not running — skipping."
fi

# ── Install new llama-swap LaunchAgent ───────────────────────────────────────
echo ""
echo "==> Installing llama-swap LaunchAgent..."

# Patch the plist to use the correct Homebrew binary path and username
CURRENT_USER=$(whoami)
run cp "$NEW_PLIST_SRC" "$NEW_PLIST_DST"

# Replace binary path (Apple Silicon vs Intel)
if ! $DRY_RUN; then
  sed -i '' "s|/opt/homebrew/bin/llama-swap|${LLAMA_SWAP_BIN}|g" "$NEW_PLIST_DST"
  # Replace username if not isaac
  if [[ "$CURRENT_USER" != "isaac" ]]; then
    sed -i '' "s|/Users/isaac|/Users/${CURRENT_USER}|g" "$NEW_PLIST_DST"
    echo "    Patched username: isaac -> ${CURRENT_USER}"
  fi
fi

echo "    Loading: ${NEW_PLIST_DST}"
run launchctl bootstrap "gui/$(id -u)" "$NEW_PLIST_DST"

echo ""
echo "==> Waiting for llama-swap to start..."
sleep 3
if curl -sf http://localhost:10000/health >/dev/null 2>&1; then
  echo "    ✓ llama-swap is running at http://localhost:10000"
  echo "    Web UI:    http://localhost:10000/ui"
  echo "    Metrics:   http://localhost:10000/metrics"
  echo "    Models:    http://localhost:10000/running"
else
  echo "    ⚠ llama-swap may not be ready yet (models start on first request)"
  echo "    Check logs: tail -f ~/Library/Logs/llama-swap/llama-swap.out.log"
fi

echo ""
echo "==> Done. Useful commands:"
echo "    Status:   launchctl list | grep llama-swap"
echo "    Stop:     launchctl bootout gui/\$(id -u) ${NEW_PLIST_DST}"
echo "    Restart:  launchctl kickstart -k gui/\$(id -u)/${NEW_PLIST_LABEL}"
echo "    Logs:     tail -f ~/Library/Logs/llama-swap/llama-swap.out.log"
echo "    Running:  curl -s http://localhost:10000/running | jq ."
