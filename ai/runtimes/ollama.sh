if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Ollama runtime (macOS / Apple Silicon)
#
# We deliberately do NOT use `brew install ollama` / `brew services ollama`.
# The Homebrew bottle (0.30.7/0.30.8 era) ships only the Go `ollama` binary +
# an MLX/Metal stub and OMITS `llama-server`. ollama routes GGUF models (our
# whole ~/.ollama store) through `llama-server`, so the brew build cannot load
# any model — generation fails with "llama-server binary not found" and it
# falls back to a CPU path that also won't start. The official standalone
# release tarball bundles `ollama` + the full lib/ollama/ backend (llama-server
# + Metal libs), which is what actually works, GPU-accelerated, no GUI.
#
# Install layout (user-owned, no sudo):
#   ~/.local/ollama/bin/ollama
#   ~/.local/ollama/lib/ollama/   (llama-server + ggml/metal backend)
#   ~/.local/bin/ollama -> ../ollama/bin/ollama   (on PATH)
# Service: ~/Library/LaunchAgents/com.kehle.ollama.plist  (label com.kehle.ollama)
# ---------------------------------------------------------------------------

OLLAMA_PREFIX="${OLLAMA_PREFIX:-$HOME/.local/ollama}"
OLLAMA_RELEASE_URL="${OLLAMA_RELEASE_URL:-https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.tgz}"
OLLAMA_PLIST_LABEL="com.kehle.ollama"
OLLAMA_PLIST_SRC="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/ollama/${OLLAMA_PLIST_LABEL}.plist"
if [ ! -f "$OLLAMA_PLIST_SRC" ]; then
    OLLAMA_PLIST_SRC="${SETTINGS_BASE}/ai/profiles/macbook-m5-64gb/ollama/${OLLAMA_PLIST_LABEL}.plist"
fi
OLLAMA_PLIST_DST="$HOME/Library/LaunchAgents/${OLLAMA_PLIST_LABEL}.plist"

_install_ollama() {
    log_info "Installing official Ollama runtime to ${OLLAMA_PREFIX} (no sudo, no GUI)..."
    local tgz; tgz="$(mktemp -t ollama-darwin).tgz"
    curl -fL --retry 3 -o "$tgz" "$OLLAMA_RELEASE_URL" || { log_error "download failed"; return 1; }

    local stage; stage="$(mktemp -d)"
    tar xzf "$tgz" -C "$stage" || { log_error "extract failed"; return 1; }

    rm -rf "$OLLAMA_PREFIX"
    mkdir -p "$OLLAMA_PREFIX/bin" "$OLLAMA_PREFIX/lib/ollama"
    mv "$stage/ollama" "$OLLAMA_PREFIX/bin/ollama"
    mv "$stage"/* "$OLLAMA_PREFIX/lib/ollama/"
    chmod +x "$OLLAMA_PREFIX/bin/ollama" "$OLLAMA_PREFIX/lib/ollama/llama-server" 2>/dev/null || true
    rm -rf "$tgz" "$stage"

    mkdir -p "$HOME/.local/bin"
    ln -sf "$OLLAMA_PREFIX/bin/ollama" "$HOME/.local/bin/ollama"

    if [ ! -x "$OLLAMA_PREFIX/lib/ollama/llama-server" ]; then
        log_error "llama-server missing after install — backend incomplete"
        return 1
    fi
    log_info "Installed $("$OLLAMA_PREFIX/bin/ollama" --version 2>/dev/null | tail -1)"
}

_install_ollama_service() {
    [ -f "$OLLAMA_PLIST_SRC" ] || { log_error "plist source not found: $OLLAMA_PLIST_SRC"; return 1; }
    cp "$OLLAMA_PLIST_SRC" "$OLLAMA_PLIST_DST"
    plutil -lint "$OLLAMA_PLIST_DST" >/dev/null || { log_error "invalid plist"; return 1; }

    # Retire the old env-only agent if present (env now baked into this service).
    launchctl bootout "gui/$(id -u)/com.kehle.ollama-env" 2>/dev/null || true

    launchctl bootout "gui/$(id -u)/${OLLAMA_PLIST_LABEL}" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$OLLAMA_PLIST_DST" || { log_error "bootstrap failed"; return 1; }
    launchctl enable "gui/$(id -u)/${OLLAMA_PLIST_LABEL}" 2>/dev/null || true
}

verify_ollama() {
    command_exists "ollama" || return 1
    [ -x "$OLLAMA_PREFIX/lib/ollama/llama-server" ] || return 1
}

# Install Ollama and start the server. Model installation is handled
# separately by install_coding_assistants in install-models.sh.
setup_ollama() {
    log_info "Setting up Ollama..."

    verify_ollama || _install_ollama || { log_error "Failed to install Ollama"; return 1; }

    _install_ollama_service || { log_error "Failed to install Ollama service"; return 1; }

    log_info "Waiting for Ollama server..."
    local i
    for i in $(seq 1 15); do
        if curl -s http://localhost:11434/api/version >/dev/null 2>&1; then
            log_info "Ollama server is up: $(curl -s http://localhost:11434/api/version)"
            break
        fi
        sleep 1
    done

    log_info "Verifying Ollama installation..."
    ollama --version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ollama
fi
