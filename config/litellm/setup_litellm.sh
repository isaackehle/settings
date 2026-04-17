. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up LiteLLM proxy — unified OpenAI-compatible API gateway in front of Ollama (and other providers).
# Reads model_list from a YAML config and exposes a single :4000 endpoint for all tools.
# PostgreSQL runs as a Docker container (Rancher Desktop or Colima).

_install_litellm() {
    if command_exists "uv"; then
        print_info "Installing litellm[proxy] via uv..."
        uv tool install 'litellm[proxy]' && return 0
    fi
    if command_exists "pip3" || command_exists "pip"; then
        print_info "Installing litellm[proxy] via pip..."
        pip3 install 'litellm[proxy]' 2>/dev/null || pip install 'litellm[proxy]' && return 0
    fi
    print_error "Neither uv nor pip found. Install Python 3 or uv first."
    return 1
}

verify_litellm() {
    check_tool_with_version "litellm" "litellm --version"
}

_litellm_cfg_dir="$HOME/.config/litellm"
_litellm_cfg="$_litellm_cfg_dir/config.yaml"

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
    if ! command_exists "python3" && ! command_exists "python"; then
        print_warning "Python not found — skipping Prisma client generation"
        return 1
    fi

    local schema
    schema=$(find "$(uv tool dir litellm 2>/dev/null)" -name "schema.prisma" -path "*/litellm/*" 2>/dev/null | head -1)

    if [ -z "$schema" ]; then
        # Fallback: search site-packages
        schema=$(python3 -c "import litellm, os; print(os.path.join(os.path.dirname(litellm.__file__), 'proxy', 'schema.prisma'))" 2>/dev/null)
    fi

    if [ -z "$schema" ] || [ ! -f "$schema" ]; then
        print_warning "schema.prisma not found — skipping Prisma client generation"
        return 1
    fi

    print_info "Generating Prisma client from $schema..."
    python3 -m prisma generate --schema "$schema" \
        || { print_warning "Prisma generate failed — run: python3 -m prisma generate --schema $schema"; return 1; }
    print_status "Prisma client generated"
}

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."
    verify_litellm || _install_litellm || { print_error "Failed to install litellm"; return 1; }

    setup_litellm_postgres

    _generate_prisma_client

    mkdir -p "$_litellm_cfg_dir"

    local src_cfg="$SCRIPT_DIR/litellm/litellm.yaml"
    if [ -f "$src_cfg" ]; then
        if [ -f "$_litellm_cfg" ]; then
            backup_litellm
        fi
        cp "$src_cfg" "$_litellm_cfg"
        print_status "Deployed litellm config to $_litellm_cfg"
    else
        print_warning "No source config found at $src_cfg — skipping config deploy"
    fi

    # Write .env if it doesn't exist yet
    local env_file="$_litellm_cfg_dir/.env"
    if [ ! -f "$env_file" ]; then
        print_info "Creating default .env at $env_file (edit to add API keys)..."
        cat > "$env_file" <<'EOF'
LITELLM_MASTER_KEY="sk-local"
LITELLM_SALT_KEY="sk-local-salt"
LITELLM_DROP_PARAMS=True
STORE_MODEL_IN_DB=True
PORT=4000
DATABASE_URL=postgresql://litellm:litellm@localhost:5432/litellm_db
# OPENAI_API_KEY=""
# ANTHROPIC_API_KEY=""
# GROQ_API_KEY=""
EOF
        print_status "Created $env_file"
    fi

    print_info ""
    print_info "=== LiteLLM usage ==="
    print_info "Start proxy:   litellm --config $_litellm_cfg --port 4000"
    print_info "Web UI:        http://localhost:4000"
    print_info "API endpoint:  http://localhost:4000/v1  (OpenAI-compatible)"
    print_info "Master key:    set LITELLM_MASTER_KEY in $_litellm_cfg_dir/.env"
    print_info "DB container:  docker start litellm-postgres"
    print_info ""
}

restore_litellm() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/litellm_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_litellm_cfg_dir"
        cp "$latest_file" "$_litellm_cfg"
        print_status "Restored litellm config from $(basename "$latest_file")"
    else
        print_warning "No litellm config backup found in $BACKUP_DIR"
    fi
}

backup_litellm() {
    if [ -f "$_litellm_cfg" ]; then
        cp "$_litellm_cfg" "$BACKUP_DIR/litellm_config_backup_$DATE.yaml"
        print_status "Backed up litellm config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_litellm
fi


# TBD:
# docker pull docker.litellm.ai/berriai/litellm:main-latest
# https://docs.litellm.ai/docs/proxy/deploy
