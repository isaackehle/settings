#!/opt/homebrew/bin/bash
# shellcheck shell=bash
# ============================================================================
# validate-tool-configs.sh — Validate AI tool configs against models.sh + Ollama
# ============================================================================
# Purpose:
#   Check that every model referenced in tool config files is defined in
#   models.sh (the source of truth) and actually installed in Ollama.
#   Catch ProviderModelNotFoundError and similar failures before they happen.
#
#   The validation has three layers:
#     1. Source-of-truth: models.sh defines what SHOULD exist
#     2. Tool configs: kilo.jsonc, opencode.jsonc, etc. reference models
#     3. Runtime: Ollama must have the models installed
#
#   The script checks:
#     - Every model in a tool config exists in models.sh (LOCAL_MODEL_NAMES,
#       GGUF_SOURCES, OLLAMA_CLOUD_MODELS, or MODEL_REMOTES)
#     - Every model in models.sh that's referenced by a tool is installed in Ollama
#     - Every model in a tool config's provider list is either in models.sh,
#       an Ollama cloud model, or a cloud provider (OpenRouter)
#     - Agent model references resolve through provider model lists (Kilo Code)
#     - Ollama is running and responsive
#     - llama.cpp servers are reachable for llamacpp-* providers
#     - Deployed configs match source configs (optional, --deployed)
#
# Usage:
#   ai/runtimes/validate-tool-configs.sh                    # auto-detect profile
#   ai/runtimes/validate-tool-configs.sh --profile macbook-m5-64gb
#   ai/runtimes/validate-tool-configs.sh --strict           # warnings = failures
#   ai/runtimes/validate-tool-configs.sh --deployed         # check deployed configs
#   ai/runtimes/validate-tool-configs.sh --verbose          # show passing checks too
#
# Exit codes:
#   0 = all checks passed
#   1 = validation failed (errors found)
# ============================================================================

set -uo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
# shellcheck source=helpers.sh
. "${SETTINGS_BASE}/helpers.sh"

# ── Defaults ────────────────────────────────────────────────────────────────
PROFILE_NAME="${MACHINE_PROFILE:-default}"
STRICT_MODE=0
CHECK_DEPLOYED=0
VERBOSE=0
WARNINGS=0
ERRORS=0

# ── Argument parsing ───────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
Usage:
  ai/runtimes/validate-tool-configs.sh [options]

Options:
  --profile NAME    Validate a specific profile (default: auto-detect)
  --strict          Treat warnings as failures
  --deployed        Also check deployed configs match source configs
  --verbose         Show passing checks too
  -h, --help        Show this help
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile)   PROFILE_NAME="$2"; shift 2 ;;
        --strict)    STRICT_MODE=1; shift ;;
        --deployed)  CHECK_DEPLOYED=1; shift ;;
        --verbose)   VERBOSE=1; shift ;;
        -h|--help|help) usage; exit 0 ;;
        *)           log_error "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

PROFILE_DIR="${SETTINGS_BASE}/ai/profiles/${PROFILE_NAME}"
MODELS_FILE="${PROFILE_DIR}/models.sh"

if [ ! -d "$PROFILE_DIR" ]; then
    die "Profile directory not found: ${PROFILE_DIR}"
fi

if [ ! -f "$MODELS_FILE" ]; then
    die "models.sh not found: ${MODELS_FILE}"
fi

log_info "Validating tool configs for profile: ${PROFILE_NAME}"
log_info "Profile directory: ${PROFILE_DIR}"
log_info "Source of truth: ${MODELS_FILE}"

# ============================================================================
# SOURCE models.sh — the canonical model inventory
# ============================================================================
# Promote declare -A to declare -gA so variables survive the source
eval "$(sed 's/^declare -A /declare -gA /g' "$MODELS_FILE")" || {
    die "Failed to source models.sh: ${MODELS_FILE}"
}

# Build the set of all canonical model names from models.sh
declare -A CANONICAL_MODELS=()

# From LOCAL_MODEL_NAMES (role → alias)
for role in "${!LOCAL_MODEL_NAMES[@]}"; do
    CANONICAL_MODELS["${LOCAL_MODEL_NAMES[$role]}"]=1
done

# From GGUF_SOURCES (alias → HF repo)
for alias in "${!GGUF_SOURCES[@]}"; do
    CANONICAL_MODELS["$alias"]=1
done

# From OLLAMA_CONTEXT_WINDOWS (alias → context sizes)
if declare -p OLLAMA_CONTEXT_WINDOWS &>/dev/null; then
    for alias in "${!OLLAMA_CONTEXT_WINDOWS[@]}"; do
        CANONICAL_MODELS["$alias"]=1
        # Also add context variants
        for ctx in ${OLLAMA_CONTEXT_WINDOWS[$alias]}; do
            if (( ctx % 1024 == 0 )); then
                CANONICAL_MODELS["${alias}-$((ctx/1024))k"]=1
            else
                CANONICAL_MODELS["${alias}-${ctx}"]=1
            fi
        done
    done
fi

# From OLLAMA_CLOUD_MODELS
if declare -p OLLAMA_CLOUD_MODELS &>/dev/null; then
    for entry in "${OLLAMA_CLOUD_MODELS[@]}"; do
        # Strip comment
        entry="${entry%%#*}"
        entry="$(echo "$entry" | xargs)"
        [ -n "$entry" ] && CANONICAL_MODELS["$entry"]=1
    done
fi

# From MODEL_REMOTES (local alias → remote pull name)
if declare -p MODEL_REMOTES &>/dev/null; then
    for local_name in "${!MODEL_REMOTES[@]}"; do
        CANONICAL_MODELS["$local_name"]=1
    done
fi

# From tool assignment maps
for arr_name in OPENCODE_AGENTS CONTINUE_ROLES CLAUDE_CODE AIDER_MODELS CLINE_MODELS CURSOR_MODELS KILOCODE_MODELS ZED_MODELS ZOOCODE_MODELS; do
    if declare -p "$arr_name" &>/dev/null 2>&1; then
        while IFS='=' read -r role model; do
            [ -z "$model" ] && continue
            CANONICAL_MODELS["$model"]=1
        done < <(declare -p "$arr_name" 2>/dev/null | sed -n 's/.*\[\([^]]*\)\]="\([^"]*\)".*/\1=\2/p')
    fi
done

# Also add context-variant patterns for models that use them
# (e.g., qwen3-coder-30b-a3b:q6-128k from context windows)
if declare -p OLLAMA_CONTEXT_WINDOWS &>/dev/null; then
    for base in "${!OLLAMA_CONTEXT_WINDOWS[@]}"; do
        for ctx in ${OLLAMA_CONTEXT_WINDOWS[$base]}; do
            if (( ctx % 1024 == 0 )); then
                CANONICAL_MODELS["${base}-$((ctx/1024))k"]=1
            fi
        done
    done
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

record_warning() {
    WARNINGS=$((WARNINGS + 1))
    log_warning "$*"
}

record_error() {
    ERRORS=$((ERRORS + 1))
    log_error "$*"
}

record_pass() {
    if [ "$VERBOSE" = "1" ]; then
        log_success "$*"
    fi
}

# Strip JSONC comments (// ...) from stdin
strip_jsonc() {
    sed '/^[[:space:]]*\/\//d' | sed 's|//[^"]*$||'
}

# Check if a model is defined in models.sh (canonical)
is_canonical() {
    local model="$1"
    # Direct match
    [ -n "${CANONICAL_MODELS[$model]:-}" ] && return 0
    # Base name match (without context suffix like -128k)
    local base="${model%%-*}"
    # Try stripping context suffixes: -8k, -16k, -32k, -40k, -64k, -128k, -256k
    local stripped="${model%-8k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-16k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-32k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-40k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-64k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-128k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    stripped="${model%-256k}"
    [ "$stripped" != "$model" ] && [ -n "${CANONICAL_MODELS[$stripped]:-}" ] && return 0
    return 1
}

# Check if a model is a cloud model (OpenRouter or Ollama cloud)
is_cloud() {
    local model="$1"
    # OpenRouter models have /
    [[ "$model" == */* ]] && return 0
    # Ollama cloud models end with -cloud
    [[ "$model" == *-cloud ]] && return 0
    # Check OLLAMA_CLOUD_MODELS
    if declare -p OLLAMA_CLOUD_MODELS &>/dev/null; then
        for entry in "${OLLAMA_CLOUD_MODELS[@]}"; do
            entry="${entry%%#*}"
            entry="$(echo "$entry" | xargs)"
            [ "$entry" = "$model" ] && return 0
        done
    fi
    return 1
}

# ============================================================================
# 1. CHECK OLLAMA IS RUNNING
# ============================================================================

OLLAMA_JSON=""

check_ollama_running() {
    log_info "Checking Ollama connectivity..."

    OLLAMA_JSON=$(curl -sf http://localhost:11434/api/tags 2>/dev/null) || {
        record_error "Ollama is not running or not reachable on :11434"
        return 1
    }

    local model_count
    model_count=$(echo "$OLLAMA_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "0")
    record_pass "Ollama is running with ${model_count} models"
    return 0
}

# ============================================================================
# 2. COLLECT INSTALLED OLLAMA MODELS
# ============================================================================

declare -a OLLAMA_MODELS=()

collect_ollama_models() {
    log_info "Collecting installed Ollama models..."

    OLLAMA_MODEMS=()
    while IFS= read -r name; do
        OLLAMA_MODELS+=("$name")
    done < <(echo "$OLLAMA_JSON" | python3 -c "import sys,json; [print(m['name']) for m in json.load(sys.stdin).get('models',[])]" 2>/dev/null)

    record_pass "Found ${#OLLAMA_MODELS[@]} Ollama models"
}

# Check if a model name exists in Ollama (exact match or base match)
ollama_has_model() {
    local query="$1"
    local model
    for model in "${OLLAMA_MODELS[@]}"; do
        [ "$model" = "$query" ] && return 0
    done
    # Also check base name (without tag)
    local query_base="${query%%:*}"
    for model in "${OLLAMA_MODELS[@]}"; do
        local model_base="${model%%:*}"
        [ "$model_base" = "$query_base" ] && return 0
    done
    return 1
}

# ============================================================================
# 3. CHECK LLAMA.CPP SERVERS
# ============================================================================

declare -A LLAMACPP_PORTS=(
    [llamacpp-coder]=8013
    [llamacpp-embedding]=8016
    [llamacpp-fast]=8011
    [llamacpp-general]=8012
    [llamacpp-heavy]=8014
    [llamacpp-reasoning]=8015
    [llamacpp-summary]=8017
)

check_llamacpp_servers() {
    log_info "Checking llama.cpp server connectivity..."

    for provider in "${!LLAMACPP_PORTS[@]}"; do
        local port="${LLAMACPP_PORTS[$provider]}"
        local http_code
        http_code=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${port}/v1/models" 2>/dev/null) || http_code="000"

        if [ "$http_code" = "200" ]; then
            record_pass "llama.cpp ${provider} on :${port} — reachable"
        else
            record_warning "llama.cpp ${provider} on :${port} — not reachable (HTTP ${http_code})"
        fi
    done
}

# ============================================================================
# 4. VALIDATE TOOL CONFIGS AGAINST models.sh + Ollama
# ============================================================================
# For each tool config, extract model references and check:
#   1. Is the model defined in models.sh? (canonical)
#   2. Is the model installed in Ollama? (runtime)
#   3. Is the model a cloud model? (skip Ollama check)

# ── Kilo Code ──────────────────────────────────────────────────────────────

validate_kilocode() {
    local config_file="$1"
    local config_label="$2"

    [ ! -f "$config_file" ] && { record_warning "Kilo Code config not found: ${config_file}"; return; }

    log_info "Validating Kilo Code config: ${config_label}"

    local content
    content=$(strip_jsonc < "$config_file")

    # Extract provider → model mapping
    declare -A KC_PROVIDER_MODELS=()
    declare -A KC_PROVIDER_TYPE=()

    local provider_data
    provider_data=$(echo "$content" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for pname, pdata in data.get('provider', {}).items():
    base_url = pdata.get('options', {}).get('baseURL', '')
    ptype = 'openrouter' if 'openrouter' in base_url else 'local'
    models = list(pdata.get('models', {}).keys())
    print(f'{pname}|{ptype}|{chr(31).join(models)}')
" 2>/dev/null) || { record_error "Failed to parse Kilo Code config"; return; }

    while IFS='|' read -r provider ptype models_str; do
        KC_PROVIDER_TYPE["$provider"]="$ptype"
        IFS=$'\037' read -ra model_arr <<< "$models_str"
        for mid in "${model_arr[@]}"; do
            [ -z "$mid" ] && continue
            if [ -z "${KC_PROVIDER_MODELS[$mid]:-}" ]; then
                KC_PROVIDER_MODELS["$mid"]="$provider"
            else
                KC_PROVIDER_MODELS["$mid"]="${KC_PROVIDER_MODELS[$mid]},${provider}"
            fi
        done
    done <<< "$provider_data"

    # Extract agent model references
    declare -A KC_AGENT_MODELS=()
    local agent_data
    agent_data=$(echo "$content" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for name, agent in data.get('agent', {}).items():
    model = agent.get('model', '')
    if model: print(f'{name}|{model}')
" 2>/dev/null)

    while IFS='|' read -r agent model; do
        [ -z "$agent" ] && continue
        KC_AGENT_MODELS["$agent"]="$model"
    done <<< "$agent_data"

    # Top-level models
    local top_model top_small
    top_model=$(echo "$content" | python3 -c "import sys,json; data=json.loads(sys.stdin.read()); print(data.get('model',''))" 2>/dev/null)
    top_small=$(echo "$content" | python3 -c "import sys,json; data=json.loads(sys.stdin.read()); print(data.get('small_model',''))" 2>/dev/null)

    # ── Check: every agent model must exist in a provider ──────────────────
    log_info "  Checking agent → provider model resolution..."
    for agent in "${!KC_AGENT_MODELS[@]}"; do
        local model="${KC_AGENT_MODELS[$agent]}"
        if [ -z "${KC_PROVIDER_MODELS[$model]:-}" ]; then
            record_error "  Kilo Code agent '${agent}' uses model '${model}' which is NOT in any provider model list"
        else
            record_pass "  agent '${agent}' → '${model}' → provider ${KC_PROVIDER_MODELS[$model]}"
        fi
    done

    # ── Check: top-level model must exist in a provider ──────────────────
    for top_var in "$top_model" "$top_small"; do
        [ -z "$top_var" ] && continue
        if [ -z "${KC_PROVIDER_MODELS[$top_var]:-}" ]; then
            record_error "  Kilo Code model '${top_var}' is NOT in any provider model list"
        else
            record_pass "  model '${top_var}' → provider ${KC_PROVIDER_MODELS[$top_var]}"
        fi
    done

    # ── Check: provider models — canonical? installed? ─────────────────────
    log_info "  Checking provider models against models.sh + Ollama..."
    for mid in "${!KC_PROVIDER_MODELS[@]}"; do
        local providers="${KC_PROVIDER_MODELS[$mid]}"
        local found=0

        IFS=',' read -ra prov_arr <<< "$providers"
        for prov in "${prov_arr[@]}"; do
            local ptype="${KC_PROVIDER_TYPE[$prov]:-unknown}"
            case "$ptype" in
                local)
                    if [[ "$prov" == llamacpp-* ]]; then
                        local port="${LLAMACPP_PORTS[$prov]:-}"
                        if [ -n "$port" ]; then
                            local http_code
                            http_code=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${port}/v1/models" 2>/dev/null) || http_code="000"
                            [ "$http_code" = "200" ] && found=1
                        fi
                    else
                        # Ollama provider — check canonical + installed
                        if is_canonical "$mid"; then
                            if ollama_has_model "$mid"; then
                                record_pass "  '${mid}' — canonical ✓, installed ✓"
                                found=1
                            else
                                record_error "  '${mid}' — canonical ✓, NOT installed in Ollama (run: setup_ai.sh models)"
                                found=1
                            fi
                        elif is_cloud "$mid"; then
                            record_pass "  '${mid}' — cloud model"
                            found=1
                        else
                            record_warning "  '${mid}' — NOT in models.sh (phantom or distillation model)"
                            found=1
                        fi
                    fi
                    ;;
                openrouter)
                    record_pass "  '${mid}' — OpenRouter cloud model"
                    found=1
                    ;;
            esac
        done

        if [ "$found" = "0" ]; then
            if [[ "$providers" == *llamacpp* ]]; then
                record_warning "  '${mid}' — llama.cpp server(s) not reachable"
            fi
        fi
    done
}

# ── OpenCode ────────────────────────────────────────────────────────────────

validate_opencode() {
    local config_file="$1"
    local config_label="$2"

    [ ! -f "$config_file" ] && { record_warning "OpenCode config not found: ${config_file}"; return; }

    log_info "Validating OpenCode config: ${config_label}"

    local content
    content=$(strip_jsonc < "$config_file")

    local agent_data
    agent_data=$(echo "$content" | python3 -c "
import sys, json
data = json.loads(sys.stdin.read())
for name, agent in data.get('agent', {}).items():
    model = agent.get('model', '')
    if model: print(f'{name}|{model}')
" 2>/dev/null)

    while IFS='|' read -r agent full_model; do
        [ -z "$agent" ] && continue
        local model_name="${full_model#*/}"

        case "$full_model" in
            ollama/*)
                if is_canonical "$model_name"; then
                    if ollama_has_model "$model_name"; then
                        record_pass "  OpenCode '${agent}' → '${model_name}' — canonical ✓, installed ✓"
                    else
                        record_error "  OpenCode '${agent}' → '${model_name}' — canonical ✓, NOT installed (run: setup_ai.sh models)"
                    fi
                else
                    record_error "  OpenCode '${agent}' → '${model_name}' — NOT in models.sh"
                fi
                ;;
            openrouter/*)
                record_pass "  OpenCode '${agent}' → '${full_model}' — cloud model"
                ;;
            *)
                record_warning "  OpenCode '${agent}' → '${full_model}' — unknown provider prefix"
                ;;
        esac
    done <<< "$agent_data"
}

# ── Continue ────────────────────────────────────────────────────────────────

validate_continue() {
    local config_file="$1"
    local config_label="$2"

    [ ! -f "$config_file" ] && { record_warning "Continue config not found: ${config_file}"; return; }

    log_info "Validating Continue config: ${config_label}"

    local model_entries
    model_entries=$(python3 -c "
import yaml, sys
with open('${config_file}') as f:
    data = yaml.safe_load(f)
for m in data.get('models', []):
    provider = m.get('provider', '')
    api_base = m.get('apiBase', '')
    model = m.get('model', '')
    name = m.get('name', '')
    if 'localhost:11434' in api_base or provider == 'ollama':
        print(f'OLLAMA|{model}|{name}')
    elif 'openrouter' in api_base:
        print(f'OPENROUTER|{model}|{name}')
    elif 'localhost' in api_base:
        port = api_base.split(':')[-1].split('/')[0] if ':' in api_base else ''
        print(f'LLAMACPP|{model}|{name}|{port}')
    else:
        print(f'UNKNOWN|{model}|{name}')
" 2>/dev/null) || { record_warning "  Could not parse Continue YAML (install pyyaml)"; return; }

    while IFS='|' read -r provider model name port; do
        [ -z "$model" ] && continue
        case "$provider" in
            OLLAMA)
                if is_canonical "$model"; then
                    if ollama_has_model "$model"; then
                        record_pass "  Continue '${name}' → '${model}' — canonical ✓, installed ✓"
                    else
                        record_error "  Continue '${name}' → '${model}' — canonical ✓, NOT installed (run: setup_ai.sh models)"
                    fi
                else
                    record_error "  Continue '${name}' → '${model}' — NOT in models.sh"
                fi
                ;;
            OPENROUTER)
                record_pass "  Continue '${name}' → '${model}' — cloud model"
                ;;
            LLAMACPP)
                local http_code
                http_code=$(curl -sf -o /dev/null -w "%{http_code}" "http://localhost:${port}/v1/models" 2>/dev/null) || http_code="000"
                if [ "$http_code" = "200" ]; then
                    record_pass "  Continue '${name}' → '${model}' on llama.cpp :${port} — server up"
                else
                    record_warning "  Continue '${name}' → '${model}' on llama.cpp :${port} — server not reachable"
                fi
                ;;
            *)
                record_warning "  Continue '${name}' → '${model}' — unknown provider"
                ;;
        esac
    done <<< "$model_entries"
}

# ── Claude Code ─────────────────────────────────────────────────────────────

validate_claude() {
    local config_file="$1"
    local config_label="$2"

    [ ! -f "$config_file" ] && { record_warning "Claude Code config not found: ${config_file}"; return; }

    log_info "Validating Claude Code config: ${config_label}"

    local models
    models=$(python3 -c "
import sys, json
with open('${config_file}') as f:
    data = json.load(f)
env = data.get('env', {})
for key in ['ANTHROPIC_DEFAULT_SONNET_MODEL', 'ANTHROPIC_DEFAULT_HAIKU_MODEL', 'ANTHROPIC_DEFAULT_OPUS_MODEL']:
    if key in env: print(env[key])
model = data.get('model', '')
if model: print(model)
" 2>/dev/null)

    while IFS= read -r model; do
        [ -z "$model" ] && continue
        if is_canonical "$model"; then
            if ollama_has_model "$model"; then
                record_pass "  Claude Code '${model}' — canonical ✓, installed ✓"
            else
                record_error "  Claude Code '${model}' — canonical ✓, NOT installed (run: setup_ai.sh models)"
            fi
        else
            record_error "  Claude Code '${model}' — NOT in models.sh"
        fi
    done <<< "$models"
}

# ── Aider ────────────────────────────────────────────────────────────────────

validate_aider() {
    local config_file="$1"
    local config_label="$2"

    [ ! -f "$config_file" ] && { record_warning "Aider config not found: ${config_file}"; return; }

    log_info "Validating Aider config: ${config_label}"

    # YAML: "model: qwen3-coder-30b-a3b:q6" — split on first ": " only
    local models
    models=$(grep -E '^\s*(model|weak-model|editor-model):' "$config_file" 2>/dev/null | sed 's/^[^:]*:[[:space:]]*//' | sort -u)

    while IFS= read -r model; do
        [ -z "$model" ] && continue
        local stripped="${model#ollama_chat/}"
        stripped="${stripped#ollama/}"

        case "$model" in
            ollama_chat/*|ollama/*)
                if is_canonical "$stripped"; then
                    if ollama_has_model "$stripped"; then
                        record_pass "  Aider '${model}' → '${stripped}' — canonical ✓, installed ✓"
                    else
                        record_error "  Aider '${model}' → '${stripped}' — canonical ✓, NOT installed"
                    fi
                else
                    record_error "  Aider '${model}' → '${stripped}' — NOT in models.sh"
                fi
                ;;
            openrouter/*)
                record_pass "  Aider '${model}' — cloud model"
                ;;
            *)
                if is_canonical "$model"; then
                    if ollama_has_model "$model"; then
                        record_pass "  Aider '${model}' — canonical ✓, installed ✓"
                    else
                        record_error "  Aider '${model}' — canonical ✓, NOT installed"
                    fi
                else
                    record_error "  Aider '${model}' — NOT in models.sh"
                fi
                ;;
        esac
    done <<< "$models"
}

# ── Generic JSON provider parser (Gemini, Grok, Crush) ──────────────────────

validate_json_provider_config() {
    local config_file="$1"
    local config_label="$2"
    local provider_key="${3:-provider}"  # "provider" for Gemini/Grok, "providers" for Crush

    [ ! -f "$config_file" ] && { record_warning "${config_label} config not found: ${config_file}"; return; }

    log_info "Validating ${config_label} config: ${config_label}"

    local model_entries
    model_entries=$(python3 -c "
import sys, json
with open('${config_file}') as f:
    data = json.load(f)

providers = data.get('${provider_key}', {})
# Handle both dict (Gemini/Grok) and nested dict
if isinstance(providers, dict):
    for pname, pdata in providers.items():
        base_url = ''
        if isinstance(pdata, dict):
            base_url = pdata.get('options', {}).get('baseURL', pdata.get('base_url', ''))
            ptype = 'openrouter' if 'openrouter' in base_url else 'local'
            models = pdata.get('models', {})
            if isinstance(models, dict):
                for mid in models:
                    print(f'{ptype}|{mid}')
            elif isinstance(models, list):
                for m in models:
                    mid = m.get('id', '') if isinstance(m, dict) else str(m)
                    if mid: print(f'{ptype}|{mid}')
" 2>/dev/null)

    while IFS='|' read -r ptype mid; do
        [ -z "$mid" ] && continue
        case "$ptype" in
            local)
                if is_canonical "$mid"; then
                    if ollama_has_model "$mid"; then
                        record_pass "  ${config_label} '${mid}' — canonical ✓, installed ✓"
                    else
                        record_error "  ${config_label} '${mid}' — canonical ✓, NOT installed (run: setup_ai.sh models)"
                    fi
                else
                    record_error "  ${config_label} '${mid}' — NOT in models.sh"
                fi
                ;;
            openrouter)
                record_pass "  ${config_label} '${mid}' — cloud model"
                ;;
            *)
                record_warning "  ${config_label} '${mid}' — unknown provider type '${ptype}'"
                ;;
        esac
    done <<< "$model_entries"
}

# ============================================================================
# 5. CHECK DEPLOYED CONFIGS MATCH SOURCE
# ============================================================================

check_deployed_configs() {
    log_info "Checking deployed configs match source configs..."

    declare -A DEPLOY_MAP=(
        [kilocode]="$HOME/.kilo/kilo.jsonc"
        [opencode]="$HOME/.config/opencode/opencode.jsonc"
        [continue]="$HOME/.continue/config.yaml"
        [claude]="$HOME/.claude/settings.json"
        [aider]="$HOME/.aider.conf.yml"
    )

    declare -A SOURCE_MAP=(
        [kilocode]="${PROFILE_DIR}/kilocode/kilo.jsonc"
        [opencode]="${PROFILE_DIR}/opencode/opencode.jsonc"
        [continue]="${PROFILE_DIR}/continue/config.yaml"
        [claude]="${PROFILE_DIR}/claude/settings.json"
        [aider]="${PROFILE_DIR}/aider/aider.conf.yml"
    )

    for tool in "${!DEPLOY_MAP[@]}"; do
        local deployed="${DEPLOY_MAP[$tool]}"
        local source="${SOURCE_MAP[$tool]}"

        [ ! -f "$deployed" ] && { record_warning "  ${tool}: deployed config not found at ${deployed}"; continue; }
        [ ! -f "$source" ] && { record_warning "  ${tool}: source config not found at ${source}"; continue; }

        case "$tool" in
            kilocode|opencode|claude|grok|crush|gemini)
                local deployed_norm source_norm
                deployed_norm=$(strip_jsonc < "$deployed" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), sort_keys=True))" 2>/dev/null || echo "")
                source_norm=$(strip_jsonc < "$source" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), sort_keys=True))" 2>/dev/null || echo "")
                if [ -z "$deployed_norm" ] || [ -z "$source_norm" ]; then
                    record_warning "  ${tool}: could not normalize JSON for comparison"
                elif [ "$deployed_norm" = "$source_norm" ]; then
                    record_pass "  ${tool}: deployed matches source"
                else
                    record_warning "  ${tool}: deployed config DIFFERS from source"
                fi
                ;;
            *)
                if diff -q "$source" "$deployed" >/dev/null 2>&1; then
                    record_pass "  ${tool}: deployed matches source"
                else
                    record_warning "  ${tool}: deployed config DIFFERS from source"
                fi
                ;;
        esac
    done
}

# ============================================================================
# 6. CROSS-CHECK: models.sh vs TOOL CONFIGS
# ============================================================================

cross_check_models_sh() {
    log_info "Cross-checking models.sh tool assignments against canonical inventory..."

    # Check each tool assignment map
    for arr_name in OPENCODE_AGENTS CONTINUE_ROLES CLAUDE_CODE AIDER_MODELS; do
        if ! declare -p "$arr_name" &>/dev/null 2>&1; then continue; fi
        while IFS='=' read -r role model; do
            [ -z "$model" ] && continue
            if is_cloud "$model"; then
                record_pass "  [${arr_name}] ${role} = ${model} — cloud model"
            elif is_canonical "$model"; then
                if ollama_has_model "$model"; then
                    record_pass "  [${arr_name}] ${role} = ${model} — canonical ✓, installed ✓"
                else
                    record_error "  [${arr_name}] ${role} = ${model} — canonical ✓, NOT installed (run: setup_ai.sh models)"
                fi
            else
                record_error "  [${arr_name}] ${role} = ${model} — NOT in models.sh"
            fi
        done < <(declare -p "$arr_name" 2>/dev/null | sed -n 's/.*\[\([^]]*\)\]="\([^"]*\)".*/\1=\2/p')
    done

    # Check LOCAL_MODEL_NAMES — every role should be installed
    for role in "${!LOCAL_MODEL_NAMES[@]}"; do
        local model="${LOCAL_MODEL_NAMES[$role]}"
        if ollama_has_model "$model"; then
            record_pass "  [LOCAL_MODEL_NAMES] ${role} = ${model} — installed ✓"
        else
            record_error "  [LOCAL_MODEL_NAMES] ${role} = ${model} — NOT installed (run: setup_ai.sh models)"
        fi
    done

    # Check GGUF_SOURCES — every alias should have a GGUF file or be in Ollama
    local gguf_dir="${GGUF_DIR:-/usr/local/lib/llama-models}"
    for alias in "${!GGUF_SOURCES[@]}"; do
        local filename="${GGUF_LOCAL_FILENAMES[$alias]:-}"
        local gguf_path="${gguf_dir}/${filename}"
        if [ -n "$filename" ] && [ -f "$gguf_path" ]; then
            record_pass "  [GGUF] ${alias} — file exists: ${filename}"
        elif [ -n "$filename" ]; then
            record_warning "  [GGUF] ${alias} — file missing: ${gguf_path}"
        fi
    done
}

# ============================================================================
# MAIN
# ============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          validate-tool-configs.sh — AI Config Audit             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check Ollama is running
if ! check_ollama_running; then
    record_error "Cannot proceed without Ollama. Start it with: brew services start ollama"
    echo ""
    log_error "Validation failed — Ollama not running"
    exit 1
fi

# Step 2: Collect installed models
collect_ollama_models

# Step 3: Check llama.cpp servers
check_llamacpp_servers

echo ""
echo "── Kilo Code ──────────────────────────────────────────────────────"
validate_kilocode "${PROFILE_DIR}/kilocode/kilo.jsonc" "source"

echo ""
echo "── OpenCode ───────────────────────────────────────────────────────"
validate_opencode "${PROFILE_DIR}/opencode/opencode.jsonc" "source"

echo ""
echo "── Continue ───────────────────────────────────────────────────────"
validate_continue "${PROFILE_DIR}/continue/config.yaml" "source"

echo ""
echo "── Claude Code ────────────────────────────────────────────────────"
validate_claude "${PROFILE_DIR}/claude/settings.json" "source"

echo ""
echo "── Aider ──────────────────────────────────────────────────────────"
validate_aider "${PROFILE_DIR}/aider/aider.conf.yml" "source"

echo ""
echo "── Gemini ─────────────────────────────────────────────────────────"
validate_json_provider_config "${PROFILE_DIR}/gemini/settings.json" "Gemini" "provider"

echo ""
echo "── Grok ───────────────────────────────────────────────────────────"
validate_json_provider_config "${PROFILE_DIR}/grok/grok.json" "Grok" "provider"

echo ""
echo "── Crush ──────────────────────────────────────────────────────────"
validate_json_provider_config "${PROFILE_DIR}/crush/crush.json" "Crush" "providers"

echo ""
echo "── models.sh cross-check ──────────────────────────────────────────"
cross_check_models_sh

if [ "$CHECK_DEPLOYED" = "1" ]; then
    echo ""
    echo "── Deployed Configs ──────────────────────────────────────────────"
    check_deployed_configs
fi

# ── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════════════"
echo "  Validation summary for profile '${PROFILE_NAME}'"
echo "  warnings: ${WARNINGS}"
echo "  errors:   ${ERRORS}"
echo ""
echo "  Legend:"
echo "    canonical ✓  = model is defined in models.sh"
echo "    installed ✓  = model is present in Ollama"
echo "    NOT installed = model is in models.sh but not in Ollama (run: setup_ai.sh models)"
echo "    NOT in models.sh = model is in a tool config but not in models.sh (add or remove)"
echo "══════════════════════════════════════════════════════════════════════"

if [ "$STRICT_MODE" = "1" ] && [ "$WARNINGS" -gt 0 ]; then
    log_error "Strict mode: warnings treated as failures"
    exit 1
fi

if [ "$ERRORS" -gt 0 ]; then
    log_error "Validation failed — ${ERRORS} error(s) found"
    exit 1
fi

log_success "All checks passed"
exit 0