. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up LiteLLM proxy — unified OpenAI-compatible API gateway in front of Ollama (and other providers).
# Reads model_list from a YAML config and exposes a single :4000 endpoint for all tools.
# PostgreSQL runs as a Docker container (Rancher Desktop or Colima).

_install_litellm() {
    if ! command_exists "uv"; then
        print_error "uv is not found. Install uv first."
        return 1
    fi

    print_info "Installing litellm[proxy] with prisma via uv..."
    uv tool install --python 3.13 --with prisma 'litellm[proxy]'
}

verify_litellm() {
    check_tool_with_version "litellm" "litellm"
}

_local_dir="$HOME/.config/litellm"
_local_cfg="$_local_dir/config.yaml"

_svc_dir="/usr/local/bin"
_svc_cfg="$_svc_dir/litellm.yaml"

# Start PostgreSQL container for LiteLLM (works with Rancher Desktop or Colima)
setup_litellm_postgres() {
    if ! command_exists "docker"; then
        print_warning "Docker not found — skipping PostgreSQL setup (install Rancher Desktop or Colima)"
        return 1
    fi

    if docker ps -a --format '{{.Names}}' | grep -q '^litellm-postgres$'; then
        if docker ps --format '{{.Names}}' | grep -q '^litellm-postgres$'; then
            print_status "litellm-postgres container already running"
        else
            print_info "Starting existing litellm-postgres container..."
            docker start litellm-postgres
            print_status "litellm-postgres started"
        fi
        return 0
    fi

    print_info "Creating litellm-postgres container..."
    docker run -d \
        --name litellm-postgres \
        --restart unless-stopped \
        -e POSTGRES_DB=litellm_db \
        -e POSTGRES_USER=litellm \
        -e POSTGRES_PASSWORD=litellm \
        -p 5432:5432 \
        postgres:16

    print_status "litellm-postgres container created and running"
    print_info "DATABASE_URL=postgresql://litellm:litellm@localhost:5432/litellm_db"
}

# Generate Prisma client (required for web UI / DB features; re-run after litellm upgrades)
_generate_prisma_client() {
    if ! command_exists "uv"; then
        print_warning "uv not found — skipping Prisma client generation"
        return 1
    fi

    # Use the Python inside the litellm uv tool venv so prisma is importable
    local litellm_python
    litellm_python="$(uv tool dir)/litellm/bin/python"
    if [ ! -x "$litellm_python" ]; then
        print_warning "litellm venv Python not found at $litellm_python — skipping Prisma client generation"
        return 1
    fi

    local schema
    schema=$("$litellm_python" -c "import litellm, os; print(os.path.join(os.path.dirname(litellm.__file__), 'proxy', 'schema.prisma'))" 2>/dev/null)

    if [ -z "$schema" ] || [ ! -f "$schema" ]; then
        print_warning "schema.prisma not found — skipping Prisma client generation"
        return 1
    fi

    local litellm_bin
    litellm_bin="$(dirname "$litellm_python")"

    print_info "Generating Prisma client from $schema..."
    # Prepend venv bin so pyenv resolves prisma-client-py from the venv, not the system
    PATH="$litellm_bin:$PATH" "$litellm_bin/prisma" generate --schema "$schema" \
        || { print_warning "Prisma generate failed — run: PATH=$litellm_bin:\$PATH $litellm_bin/prisma generate --schema $schema"; return 1; }
    print_status "Prisma client generated"

    if [ -n "$DATABASE_URL" ]; then
        print_info "Pushing Prisma schema to database..."
        PATH="$litellm_bin:$PATH" "$litellm_bin/prisma" db push --schema "$schema" --skip-generate \
            || print_warning "Prisma db push failed — run manually after setting DATABASE_URL"
        print_status "Database schema synced"
    else
        print_warning "DATABASE_URL not set — skipping prisma db push (run after starting postgres)"
    fi
}

_setup_python_version_for_install() {

    pyenv install 3.13
    pyenv local 3.13

}

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."

    verify_litellm || _install_litellm || { print_error "Failed to install litellm"; return 1; }

    setup_litellm_postgres

    _generate_prisma_client

    mkdir -p "$_local_dir"

    local src_cfg mac_model script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if declare -f find_source > /dev/null 2>&1; then
        src_cfg=$(find_source "litellm/litellm.yaml")
    fi
    if [ -z "$src_cfg" ]; then
        if declare -f detect_mac_model &>/dev/null; then
            mac_model="$(detect_mac_model)"
        else
            mac_model="macbook-m1"
        fi
        src_cfg="$script_dir/$mac_model/litellm/litellm.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        if [ -f "$_local_cfg" ]; then
            backup_litellm
        fi
        cp "$src_cfg" "$_local_cfg"
        print_status "Deployed litellm config ($mac_model) to $_local_cfg"
    else
        print_warning "No source config found at $src_cfg — skipping config deploy"
    fi

    # Deploy .env (always overwrite so repo changes take effect)
    local env_file="$_local_dir/.env"
    local env_src
    env_src="$(find_source "litellm/.env" 2>/dev/null)"
    [ -z "$env_src" ] && env_src="$SCRIPT_DIR/litellm/.env"
    if [ -f "$env_src" ]; then
        cp "$env_src" "$env_file"
        print_status "Deployed .env to $env_file"
    else
        print_warning "No .env source found at $env_src — skipping .env deploy"
    fi

    # Configure litellm to run as a user-level service on port 4000 (optional)
    if command_exists "launchctl"; then
        local src_plist="$SCRIPT_DIR/litellm/ai.litellm.proxy.plist"

        cp $src_plist $HOME/Library/LaunchAgents

        print_info "Creating a directory for litellm service at location $_svc_dir..."
        sudo mkdir -p $_svc_dir 2>/dev/null || true

        print_info "Copying config to service location $_svc_cfg..."
        sudo cp "$src_cfg" "$_svc_cfg"

        print_info "Creating symbolic link for litellm executable..."
        sudo ln -sf $HOME/.local/share/uv/tools/litellm/bin/litellm $_svc_dir/litellm

        # Bootstrap the service (unload first in case it's already registered)
        local plist="$HOME/Library/LaunchAgents/ai.litellm.proxy.plist"
        local gui="gui/$(id -u)"
        launchctl bootout "$gui" "$plist" 2>/dev/null || true
        launchctl bootstrap "$gui" "$plist"

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
    print_info "DB container:  docker start litellm-postgres"
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
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
    setup_litellm
fi


# TBD:
# docker pull docker.litellm.ai/berriai/litellm:main-latest
# https://docs.litellm.ai/docs/proxy/deploy
