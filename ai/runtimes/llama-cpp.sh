#!/opt/homebrew/bin/bash
# shellcheck shell=bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# llama.cpp — runtime wrapper for profile-based local inference
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}"
MODELS_FILE="${PROFILE_DIR}/models.sh"
RUNTIME_FILE="${SETTINGS_BASE}/ai/runtimes/runtime.sh"
PATHS_FILE="${SETTINGS_BASE}/ai/runtimes/paths.sh"
VALIDATE_PROFILE_FILE="${SETTINGS_BASE}/ai/runtimes/validate-profile.sh"

if [ ! -f "${MODELS_FILE}" ]; then
    log_error "Missing profile models file: ${MODELS_FILE}"
    return 1 2>/dev/null || exit 1
fi
if [ ! -f "${RUNTIME_FILE}" ]; then
    log_error "Missing runtime file: ${RUNTIME_FILE}"
    return 1 2>/dev/null || exit 1
fi
if [ ! -f "${PATHS_FILE}" ]; then
    log_error "Missing paths file: ${PATHS_FILE}"
    return 1 2>/dev/null || exit 1
fi

. "${MODELS_FILE}"
. "${RUNTIME_FILE}"
. "${PATHS_FILE}"

ensure_profile_paths

usage() {
    cat <<'EOF'
Usage:
  ai/runtimes/llama-cpp.sh run <role|alias> [--prompt TEXT] [--ctx N] [--temp F] [--extra ...]
  ai/runtimes/llama-cpp.sh serve <role|alias> [--port N] [--ctx N] [--parallel N] [--extra ...]
  ai/runtimes/llama-cpp.sh bench <role|alias> [--ctx N] [--prompt-tokens N] [--gen-tokens N] [--extra ...]
  ai/runtimes/llama-cpp.sh inspect <role|alias>

Examples:
  ai/runtimes/llama-cpp.sh run coder --prompt "Explain this stack trace"
  ai/runtimes/llama-cpp.sh serve general --port 8012
  ai/runtimes/llama-cpp.sh bench heavy --gen-tokens 256
EOF
}

role_to_local_name() {
    local role="$1"
    case "$role" in
        fast) echo "${LOCAL_MODEL_NAMES[fast]:-}" ;;
        general) echo "${LOCAL_MODEL_NAMES[general]:-}" ;;
        coder) echo "${LOCAL_MODEL_NAMES[coder]:-}" ;;
        heavy) echo "${LOCAL_MODEL_NAMES[heavy]:-}" ;;
        reasoning) echo "${LOCAL_MODEL_NAMES[reasoning]:-${LOCAL_MODEL_NAMES[heavy]:-}}" ;;
        embedding) echo "${LOCAL_MODEL_NAMES[embedding]:-}" ;;
        *) echo "" ;;
    esac
}

sanitize_name() {
    local name="$1"
    name="${name//\//__}"
    name="${name//:/__}"
    echo "$name"
}

resolve_model_alias() {
    local key="$1"
    local resolved
    resolved="$(role_to_local_name "$key")"
    if [ -n "$resolved" ]; then
        echo "$resolved"
        return 0
    fi
    echo "$key"
}

resolve_role_for_key() {
    local key="$1"
    case "$key" in
        fast|general|coder|heavy|reasoning|embedding) echo "$key" ;;
        *)
            local role
            for role in fast general coder heavy reasoning embedding; do
                if [ "${LOCAL_MODEL_NAMES[$role]:-}" = "$key" ]; then
                    echo "$role"
                    return 0
                fi
            done
            echo "general"
            ;;
    esac
}

find_gguf_for_alias() {
    local alias="$1"
    local safe_alias
    safe_alias="$(sanitize_name "$alias")"

    # 1) Prefer explicit GGUF_FILENAMES mapping if present in the profile.
    #    This keeps artifact naming stable and avoids ad-hoc guessing.
    if [ -n "${GGUF_LOCAL_FILENAMES[$alias]:-}" ]; then
        local explicit="${GGUF_LOCAL_FILENAMES[$alias]}"
        if [ -f "${GGUF_DIR}/${explicit}" ]; then
            echo "${GGUF_DIR}/${explicit}"
            return 0
        fi
    fi

    # 2) Fall back to common filename patterns based on sanitized alias.
    local candidates=(
        "${GGUF_DIR}/${safe_alias}.gguf"
        "${GGUF_DIR}/${alias}.gguf"
        "${GGUF_DIR}/${safe_alias}/model.gguf"
        "${GGUF_DIR}/${safe_alias}/${safe_alias}.gguf"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

model_ctx_default() {
    local role="$1"
    echo "${ROLE_CTX_DEFAULTS[$role]:-${LLAMA_CPP_CTX_DEFAULT}}"
}

model_batch_default() {
    local role="$1"
    echo "${ROLE_BATCH_DEFAULTS[$role]:-${LLAMA_CPP_BATCH}}"
}

model_ubatch_default() {
    local role="$1"
    echo "${ROLE_UBATCH_DEFAULTS[$role]:-${LLAMA_CPP_UBATCH}}"
}

model_port_default() {
    local role="$1"
    echo "${ROLE_PORTS[$role]:-${LLAMA_SERVER_PORT_BASE}}"
}

verify_llama_cpp_bins() {
    local missing=0
    if [ ! -x "${LLAMA_CLI_BIN}" ]; then
        log_warning "llama-cli not found or not executable: ${LLAMA_CLI_BIN}"
        missing=1
    fi
    if [ ! -x "${LLAMA_SERVER_BIN}" ]; then
        log_warning "llama-server not found or not executable: ${LLAMA_SERVER_BIN}"
        missing=1
    fi
    return "$missing"
}

run_profile_validation() {
    if [ "${ENABLE_PROFILE_VALIDATION:-0}" != "1" ]; then
        return 0
    fi
    if [ ! -x "${VALIDATE_PROFILE_FILE}" ]; then
        log_warning "Profile validator is not executable: ${VALIDATE_PROFILE_FILE}"
        return 0
    fi

    log_info "Running profile validation before launch..."
    "${VALIDATE_PROFILE_FILE}" --profile "${MACHINE_PROFILE}" || return 1
}

inspect_model() {
    local key="$1"
    local alias role gguf
    alias="$(resolve_model_alias "$key")"
    role="$(resolve_role_for_key "$key")"
    gguf="$(find_gguf_for_alias "$alias" 2>/dev/null || true)"

    cat <<EOF
key: ${key}
role: ${role}
alias: ${alias}
gguf: ${gguf:-MISSING}
ctx: $(model_ctx_default "$role")
batch: $(model_batch_default "$role")
ubatch: $(model_ubatch_default "$role")
port: $(model_port_default "$role")
cli: ${LLAMA_CLI_BIN}
server: ${LLAMA_SERVER_BIN}
EOF
}

run_model() {
    local key="$1"
    shift

    local role alias gguf prompt="" ctx temp extra_args=()
    alias="$(resolve_model_alias "$key")"
    role="$(resolve_role_for_key "$key")"
    gguf="$(find_gguf_for_alias "$alias" 2>/dev/null || true)"
    ctx="$(model_ctx_default "$role")"
    temp="${LLAMA_CPP_TEMP}"

    while [ $# -gt 0 ]; do
        case "$1" in
            --prompt)
                prompt="$2"
                shift 2
                ;;
            --ctx)
                ctx="$2"
                shift 2
                ;;
            --temp)
                temp="$2"
                shift 2
                ;;
            --extra)
                shift
                while [ $# -gt 0 ]; do
                    extra_args+=("$1")
                    shift
                done
                ;;
            *)
                extra_args+=("$1")
                shift
                ;;
        esac
    done

    if [ -z "$gguf" ]; then
        log_error "No GGUF found for alias '${alias}' under ${GGUF_DIR}"
        return 1
    fi

    log_info "Running ${alias} (${role})"
    log_info "GGUF: ${gguf}"

    local cmd=(
        "${LLAMA_CLI_BIN}"
        -m "$gguf"
        -ngl "${LLAMA_CPP_GPU_LAYERS}"
        -t "${LLAMA_CPP_THREADS}"
        -tb "${LLAMA_CPP_THREADS_BATCH}"
        -c "$ctx"
        -b "$(model_batch_default "$role")"
        -ub "$(model_ubatch_default "$role")"
        --temp "$temp"
        --top-p "${LLAMA_CPP_TOP_P}"
        --top-k "${LLAMA_CPP_TOP_K}"
        --min-p "${LLAMA_CPP_MIN_P}"
        --repeat-penalty "${LLAMA_CPP_REPEAT_PENALTY}"
    )

    if [ "${LLAMA_CPP_FLASH_ATTN}" = "1" ]; then
        cmd+=(--flash-attn on)
    fi
    if [ -n "$prompt" ]; then
        cmd+=(-p "$prompt")
    fi
    if [ ${#extra_args[@]} -gt 0 ]; then
        cmd+=("${extra_args[@]}")
    fi

    "${cmd[@]}"
}

serve_model() {
    local key="$1"
    shift

    local role alias gguf port ctx parallel extra_args=()
    alias="$(resolve_model_alias "$key")"
    role="$(resolve_role_for_key "$key")"
    gguf="$(find_gguf_for_alias "$alias" 2>/dev/null || true)"
    port="$(model_port_default "$role")"
    ctx="$(model_ctx_default "$role")"
    parallel="${LLAMA_SERVER_PARALLEL}"

    while [ $# -gt 0 ]; do
        case "$1" in
            --port)
                port="$2"
                shift 2
                ;;
            --ctx)
                ctx="$2"
                shift 2
                ;;
            --parallel)
                parallel="$2"
                shift 2
                ;;
            --extra)
                shift
                while [ $# -gt 0 ]; do
                    extra_args+=("$1")
                    shift
                done
                ;;
            *)
                extra_args+=("$1")
                shift
                ;;
        esac
    done

    if [ -z "$gguf" ]; then
        log_error "No GGUF found for alias '${alias}' under ${GGUF_DIR}"
        return 1
    fi

    log_info "Serving ${alias} (${role}) on ${LLAMA_SERVER_HOST}:${port}"
    log_info "GGUF: ${gguf}"

    local cmd=(
        "${LLAMA_SERVER_BIN}"
        -m "$gguf"
        --alias "$alias"
        --host "${LLAMA_SERVER_HOST}"
        --port "$port"
        -ngl "${LLAMA_CPP_GPU_LAYERS}"
        -t "${LLAMA_CPP_THREADS}"
        -tb "${LLAMA_CPP_THREADS_BATCH}"
        -c "$ctx"
        -b "$(model_batch_default "$role")"
        -ub "$(model_ubatch_default "$role")"
        --parallel "$parallel"
        --timeout "${LLAMA_SERVER_TIMEOUT}"
    )

    if [ "${LLAMA_CPP_FLASH_ATTN}" = "1" ]; then
        cmd+=(--flash-attn on)
    fi
    if [ "${LLAMA_SERVER_METRICS}" = "1" ]; then
        cmd+=(--metrics)
    fi
    if [ ${#extra_args[@]} -gt 0 ]; then
        cmd+=("${extra_args[@]}")
    fi

    "${cmd[@]}"
}

bench_model() {
    local key="$1"
    shift

    local role alias gguf ctx prompt_tokens gen_tokens extra_args=()
    alias="$(resolve_model_alias "$key")"
    role="$(resolve_role_for_key "$key")"
    gguf="$(find_gguf_for_alias "$alias" 2>/dev/null || true)"
    ctx="$(model_ctx_default "$role")"
    prompt_tokens="${BENCHMARK_DEFAULT_PROMPT_TOKENS}"
    gen_tokens="${BENCHMARK_DEFAULT_GEN_TOKENS}"

    while [ $# -gt 0 ]; do
        case "$1" in
            --ctx)
                ctx="$2"
                shift 2
                ;;
            --prompt-tokens)
                prompt_tokens="$2"
                shift 2
                ;;
            --gen-tokens)
                gen_tokens="$2"
                shift 2
                ;;
            --extra)
                shift
                while [ $# -gt 0 ]; do
                    extra_args+=("$1")
                    shift
                done
                ;;
            *)
                extra_args+=("$1")
                shift
                ;;
        esac
    done

    if [ -z "$gguf" ]; then
        log_error "No GGUF found for alias '${alias}' under ${GGUF_DIR}"
        return 1
    fi

    log_info "Benchmarking ${alias} (${role})"
    log_info "GGUF: ${gguf}"

    local cmd=(
        "${LLAMA_CLI_BIN}"
        -m "$gguf"
        -ngl "${LLAMA_CPP_GPU_LAYERS}"
        -t "${LLAMA_CPP_THREADS}"
        -tb "${LLAMA_CPP_THREADS_BATCH}"
        -c "$ctx"
        -b "$(model_batch_default "$role")"
        -ub "$(model_ubatch_default "$role")"
        -n "$gen_tokens"
        -p "Write a concise technical summary of local model runtime benchmarking."
        --no-display-prompt
    )

    if [ "${LLAMA_CPP_FLASH_ATTN}" = "1" ]; then
        cmd+=(--flash-attn on)
    fi
    if [ ${#extra_args[@]} -gt 0 ]; then
        cmd+=("${extra_args[@]}")
    fi

    "${cmd[@]}"
}

main() {
    local subcommand="${1:-}"
    shift || true

    case "$subcommand" in
        run)
            [ $# -ge 1 ] || { usage; return 1; }
            verify_llama_cpp_bins || true
            run_profile_validation
            run_model "$@"
            ;;
        serve)
            [ $# -ge 1 ] || { usage; return 1; }
            verify_llama_cpp_bins || true
            run_profile_validation
            serve_model "$@"
            ;;
        bench)
            [ $# -ge 1 ] || { usage; return 1; }
            verify_llama_cpp_bins || true
            run_profile_validation
            bench_model "$@"
            ;;
        inspect)
            [ $# -ge 1 ] || { usage; return 1; }
            inspect_model "$1"
            ;;
        -h|--help|help|"")
            usage
            ;;
        *)
            log_error "Unknown subcommand: $subcommand"
            usage
            return 1
            ;;
    esac
}

main "$@"
