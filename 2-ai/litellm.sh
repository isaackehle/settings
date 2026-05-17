#!/opt/homebrew/bin/bash

# Setup LiteLLM proxy

set -euo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_src_dir="$SETTINGS_BASE/2-ai/litellm"

# Config paths
_local_dir="$HOME/.config/litellm"
_local_cfg="$_local_dir/config.yaml"
_svc_dir="/usr/local/bin"
_svc_cfg="$_svc_dir/litellm.yaml"
_db_url="postgresql://litellm:litellm@localhost:5432/litellm_db"

# Database mode — set LITELLM_USE_DB=true to enable Postgres + Prisma
_use_db="${LITELLM_USE_DB:-false}"



verify_litellm() {
    command -v litellm &> /dev/null || [ -x "$HOME/.local/share/uv/tools/litellm/bin/litellm" ]
}

_install_litellm() {
    print_info "Installing LiteLLM via uv..."
    if ! command -v uv &> /dev/null; then
        print_error "uv not found. Please install uv first."
        return 1
    fi
    uv tool install litellm

    # Install additional dependencies for proxy mode
    print_info "Installing LiteLLM proxy dependencies..."
    local litellm_venv="$HOME/.local/share/uv/tools/litellm"
    uv pip install 'litellm[proxy]' --python "$litellm_venv/bin/python" --reinstall

    # Patch uvloop for Python 3.14 compatibility
    print_info "Patching uvloop for Python 3.14 compatibility..."
    local uvloop_file="$litellm_venv/lib/python3.14/site-packages/uvicorn/loops/uvloop.py"
    if [ -f "$uvloop_file" ]; then
        cat > "$uvloop_file" << 'EOF'
import asyncio

# Python 3.14 compatibility: use standard asyncio instead of uvloop
def uvloop_setup(use_subprocess: bool = False) -> None:
    asyncio.set_event_loop_policy(asyncio.DefaultEventLoopPolicy())
EOF
    fi

    # Install prisma for database schema initialization (only if DB mode enabled)
    if [ "$_use_db" = "true" ]; then
        print_info "Installing prisma..."
        uv tool install prisma

        # Install prisma in litellm venv for LiteLLM proxy
        print_info "Installing prisma in litellm venv..."
        uv pip install prisma --python "$litellm_venv/bin/python"

        # Run prisma generate for LiteLLM
        print_info "Running prisma generate..."
        prisma generate --schema="$litellm_venv/lib/python3.14/site-packages/litellm/proxy/schema.prisma" 2>/dev/null || true
    fi
}

setup_litellm_postgres() {
    print_info "Setting up LiteLLM Postgres database..."

    # Use podman if available, otherwise docker
    local container_cmd="docker"
    if command -v podman &> /dev/null; then
        container_cmd="podman"
    fi

    if ! command -v "$container_cmd" &> /dev/null; then
        print_error "docker/podman not found. Please install a container runtime first."
        return 1
    fi

    if $container_cmd ps -a --format '{{.Names}}' | grep -q "^litellm-postgres$"; then
        print_status "LiteLLM Postgres container already exists. Ensuring it is running..."
        $container_cmd start litellm-postgres
    else
        print_info "Creating LiteLLM Postgres container..."
        $container_cmd run -d \
        --name litellm-postgres \
        -e POSTGRES_USER=litellm \
        -e POSTGRES_PASSWORD=litellm \
        -e POSTGRES_DB=litellm_db \
        -p 5432:5432 \
        -v litellm-db-data:/var/lib/postgresql/data \
        postgres:16-alpine
        print_status "LiteLLM Postgres container started."
    fi
}

_generate_prisma_client() {
    print_info "Initializing LiteLLM database schema..."
    local tools_bin="$HOME/.local/share/uv/tools/litellm/bin"
    local litellm_py="$tools_bin/python3"

    # Check for prisma in PATH (installed globally via pyenv/pip)
    local prisma_bin
    prisma_bin=$(command -v prisma 2>/dev/null) || true

    if [ -z "$prisma_bin" ] || [ ! -x "$litellm_py" ]; then
        print_warning "prisma not found — schema will initialize on first start."
        return 0
    fi

    local schema
    schema=$("$litellm_py" -c \
        "import litellm,os;print(os.path.join(os.path.dirname(litellm.__file__),'proxy','schema.prisma'))" \
    2>/dev/null) || { print_warning "Could not locate LiteLLM schema — will initialize on first start."; return 0; }

    [ -f "$schema" ] || { print_warning "Schema file not found — will initialize on first start."; return 0; }

    DATABASE_URL="$_db_url" \
    "$prisma_bin" db push --schema="$schema" --skip-generate \
    || print_warning "LiteLLM DB schema push failed or already initialized."
}

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."

    verify_litellm || _install_litellm || { print_error "Failed to install litellm"; return 1; }

    if [ "$_use_db" = "true" ]; then
        setup_litellm_postgres
        _generate_prisma_client
    else
        print_info "LiteLLM configured for file-based config (no database)."
        print_info "To enable DB mode, set LITELLM_USE_DB=true."
    fi

    mkdir -p "$_local_dir"

    local src_cfg="" mac_model=""
    if declare -f find_source > /dev/null 2>&1; then
        src_cfg=$(find_source "litellm/litellm.yaml")
    fi
    if [ -z "$src_cfg" ]; then
        mac_model="${MACHINE_PROFILE}"
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/$mac_model/litellm/litellm.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        if [ -f "$_local_cfg" ]; then
            backup_litellm
        fi
        log_info "copying litellm config from $src_cfg to $_local_cfg"
        cp "$src_cfg" "$_local_cfg"
        print_status "Deployed litellm config ($mac_model) to $_local_cfg"

        if [ -f "$_local_dir/litellm.yaml" ]; then
            log_warning "removing old litellm config $_local_dir/litellm.yaml"
            rm "$_local_dir/litellm.yaml"
        fi
    else
        print_warning "No source config found at $src_cfg — skipping config deploy"
    fi

    # Source user environment for API keys (OpenRouter, etc.)
    # LiteLLM will read from ~/.env.local or ~/.env
    if [ -f "$HOME/.env.local" ]; then
        set -a && source "$HOME/.env.local" && set +a
        print_status "Sourced ~/.env.local for API keys"
    elif [ -f "$HOME/.env" ]; then
        set -a && source "$HOME/.env" && set +a
        print_status "Sourced ~/.env for API keys"
    else
        print_warning "No ~/.env.local or ~/.env found — set OPENROUTER_API_KEY there for cloud models"
    fi

    # Create minimal .env for litellm (non-sensitive settings only)
    local env_file="$_local_dir/.env"
    cat > "$env_file" << 'ENVEOF'
LITELLM_MASTER_KEY="sk-local"
LITELLM_SALT_KEY="sk-local-salt"
UI_USERNAME="admin"
UI_PASSWORD="admin"
LITELLM_DROP_PARAMS=True
STORE_MODEL_IN_DB=False
PORT=4000
SKIP_DB_MIGRATIONS=true
ENVEOF
    print_status "Deployed litellm settings to $env_file"
    print_info "Add your API keys to ~/.env.local (or ~/.env):"
    print_info "  OPENROUTER_API_KEY=sk-or-..."
    print_info "  ANTHROPIC_API_KEY=sk-ant-..."
    print_info "  OPENAI_API_KEY=sk-..."

    print_status "Configure litellm to run as a service"

    # Configure litellm to run as a user-level service on port 4000 (optional)
    if command_exists "launchctl"; then
        local src_plist="$_src_dir/ai.litellm.proxy.plist"

        if [ ! -f "$src_plist" ]; then
            print_warning "Plist not found at $src_plist — skipping service setup"
        else
            local plist="$HOME/Library/LaunchAgents/ai.litellm.proxy.plist"
            local gui="gui/$(id -u)"
            {
                mkdir -p "$HOME/Library/LaunchAgents"
                cp "$src_plist" "$plist"
                sudo mkdir -p "$_svc_dir" 2>/dev/null
                [ -f "$src_cfg" ] && sudo cp "$src_cfg" "$_svc_cfg"
                sudo ln -sf "$HOME/.local/share/uv/tools/litellm/bin/litellm" "$_svc_dir/litellm"
                launchctl bootout "$gui" "$plist" 2>/dev/null || true
                launchctl bootstrap "$gui" "$plist"
                print_status "LiteLLM service registered."
            } || print_warning "Service registration failed — run manually: launchctl bootstrap $gui $plist"
        fi

        print_info ""
        print_info "=== LiteLLM usage ==="
        print_info "Start proxy:   launchctl start ai.litellm.proxy"
    else
        print_warning "launchctl not found — skipping service setup (run litellm --config $_local_cfg --port 4000 to start)"

        print_info ""
        print_info "=== LiteLLM usage ==="
        print_info "Start proxy:   litellm --config $_local_cfg --port 4000"
    fi

    print_info "Web UI:        http://localhost:4000"
    print_info "API endpoint:  http://localhost:4000/v1  (OpenAI-compatible)"
    print_info "Master key:    set LITELLM_MASTER_KEY in $_local_dir/.env"
    if [ "$_use_db" = "true" ]; then
        print_info "DB container:  docker start litellm-postgres"
    fi
    print_info ""
}

restore_litellm() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/litellm_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_local_dir"
        cp "$latest_file" "$_local_cfg"
        print_status "Restored litellm config from $(basename "$latest_file")"
    else
        print_warning "No litellm config backup found in $BACKUP_DIR"
    fi
}

backup_litellm() {
    if [ -f "$_local_cfg" ]; then
        cp "$_local_cfg" "$BACKUP_DIR/litellm_config_backup_$DATE.yaml"
        print_status "Backed up litellm config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -z "${SETTINGS_BASE:-}" ]; then
        SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
    fi
    setup_litellm
fi


# TBD:
# docker pull docker.litellm.ai/berriai/litellm:main-latest
# https://docs.litellm.ai/docs/proxy/deploy
