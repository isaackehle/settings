if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Pi — interactive coding agent CLI (npm)
# Repo:     https://github.com/earendil-works/pi
# Install:  npm i -g @earendil-works/pi-coding-agent
# Docs:     https://pi.dev/docs/latest
# ---------------------------------------------------------------------------

_pi_cfg_dir="$HOME/.pi/agent"

verify_pi() {
    if command -v pi >/dev/null 2>&1; then
        local ver
        ver=$(pi --version 2>/dev/null | head -1 || echo "installed")
        log_status "Pi found: $ver"
        return 0
    fi
    log_warning "Pi not found"
    return 1
}

_install_pi() {
    log_info "Installing Pi via npm..."

    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is required to install Pi"
        log_info "Install Node.js first: brew install node"
        return 1
    fi

    if npm install -g @earendil-works/pi-coding-agent; then
        log_status "Pi installed via npm"
        return 0
    fi
    log_error "Failed to install Pi"
    return 1
}

_setup_pi_auth() {
    # Pi reads standard environment variables at runtime (OPENAI_API_KEY,
    # ANTHROPIC_API_KEY, GEMINI_API_KEY, etc.).  Source ~/.env.local so
    # you can use keys already configured there — no separate login needed.
    local env_file="$HOME/.env.local"
    [ -f "$env_file" ] && source "$env_file"

    # Map GOOGLE_API_KEY → GEMINI_API_KEY if only the former is set
    if [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
        export GEMINI_API_KEY="$GOOGLE_API_KEY"
    fi

    echo ""
    echo "  Pi reads API keys from environment variables — no login required."
    echo "  Keys from ~/.env.local:"
    local found=0
    for var in ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY DEEPSEEK_API_KEY \
               GROQ_API_KEY OPENROUTER_API_KEY XAI_API_KEY MISTRAL_API_KEY; do
        if [ -n "${!var:-}" ]; then
            echo "    ✓ $var set"
            found=1
        fi
    done
    [ "$found" = 0 ] && echo "    (none detected)"
    echo ""

    # Merge recommended settings into pi's settings.json
    local settings_file="$_pi_cfg_dir/settings.json"
    python3 -c "
import json, os

path = '$settings_file'
defaults = {
    'defaultProvider': 'openrouter',
    'defaultModel': 'openrouter/moonshot/kimi-k2.6',
    'enableSkillCommands': True,
    'skills': ['~/.skills'],
}

if os.path.exists(path):
    with open(path) as f:
        s = json.load(f)
else:
    s = {}

for k, v in defaults.items():
    if k not in s:
        s[k] = v

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w') as f:
    json.dump(s, f, indent=2)
" && log_status "Configured Pi settings (provider, skills path, skill commands)"

    log_info "Pi will use these keys when you run it in any shell that sources ~/.env.local."
    log_info "Default provider: openrouter (moonshot/kimi-k2.6)"
    log_info "Override:  pi --provider anthropic     (use Claude)"
    log_info "           pi --provider groq          (use Groq)"
    log_info "           pi --model <pattern>        (override model)"
    echo ""
}

setup_pi() {
    log_info "Setting up Pi..."
    verify_pi || _install_pi || { log_error "Failed to install Pi"; return 1; }

    mkdir -p "$_pi_cfg_dir"
    _setup_pi_auth

    log_info ""
    log_info "=== Pi ==="
    log_info "Binary:   pi"
    log_info "Config:   $_pi_cfg_dir"
    log_info "Auth:     Uses env vars from ~/.env.local (sourced in .zprofile)"
    log_info "Usage:    pi                           (interactive, OpenRouter/kimi-k2.6)"
    log_info "          pi --provider anthropic      (use Claude)"
    log_info "          pi --provider groq           (use Groq)"
    log_info "          pi --mode rpc                (RPC mode for Pi Studio)"
    log_info "          pi /install                  (install shell integration)"
    log_info "Update:   npm update -g @earendil-works/pi-coding-agent"
    log_info "Docs:     https://pi.dev/docs/latest"
    log_info "          https://github.com/earendil-works/pi"
    log_info "GUI:      Pi Studio (see pi-studio setup)"
    log_info ""
}

backup_pi() {
    if [ -d "$_pi_cfg_dir" ]; then
        cp -r "$_pi_cfg_dir" "${BACKUP_DIR}/pi_backup_${DATE}"
        log_status "Backed up Pi config"
    fi
}

restore_pi() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/pi_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_pi_cfg_dir"
        cp -R "$latest/"* "$_pi_cfg_dir/" 2>/dev/null || true
        log_status "Restored Pi config from $(basename "$latest")"
    else
        log_warning "No Pi backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pi
fi
