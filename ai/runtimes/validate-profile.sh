#!/opt/homebrew/bin/bash
# shellcheck shell=bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# validate-profile.sh — validate llama.cpp / GGUF profile metadata
# ---------------------------------------------------------------------------
# Purpose:
# - Verify that the active machine profile has a consistent llama.cpp-first
#   runtime contract before model launch or install steps.
# - Catch mismatches early: missing alias definitions, broken GGUF filename
#   metadata, missing GGUF artifacts, or aliases that are not represented in
#   the broader local model inventory.
#
# Typical usage:
#   ai/runtimes/validate-profile.sh
#   ai/runtimes/validate-profile.sh --strict
#   ai/runtimes/validate-profile.sh --require-files
#   ai/runtimes/validate-profile.sh --profile macbook-m5-64gb
#
# Exit codes:
#   0 = validation passed
#   1 = validation failed

PROFILE_NAME="${MACHINE_PROFILE:-default}"
STRICT_MODE=0
REQUIRE_FILES=0

usage() {
    cat <<'EOF'
Usage:
  ai/runtimes/validate-profile.sh [--profile NAME] [--strict] [--require-files]

Options:
  --profile NAME    Validate a specific profile instead of MACHINE_PROFILE.
  --strict          Treat warnings as failures.
  --require-files   Require GGUF files to exist on disk.
  -h, --help        Show this help.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --profile)
            PROFILE_NAME="$2"
            shift 2
            ;;
        --strict)
            STRICT_MODE=1
            shift
            ;;
        --require-files)
            REQUIRE_FILES=1
            shift
            ;;
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

PROFILE_DIR="${SETTINGS_BASE}/ai/profiles/${PROFILE_NAME}"
MODELS_FILE="${PROFILE_DIR}/models.sh"
PATHS_FILE="${SETTINGS_BASE}/ai/runtimes/paths.sh"

[ -f "${MODELS_FILE}" ] || die "Missing models file: ${MODELS_FILE}"
[ -f "${PATHS_FILE}" ] || die "Missing paths file: ${PATHS_FILE}"

# Promote declare -A to declare -gA so associative arrays survive
# the function scope when models.sh is sourced inside a function.
source <(sed 's/^declare -A /declare -gA /g' "${MODELS_FILE}")
. "${PATHS_FILE}"

ensure_profile_paths

WARNINGS=0
ERRORS=0

record_warning() {
    WARNINGS=$((WARNINGS + 1))
    log_warning "$*"
}

record_error() {
    ERRORS=$((ERRORS + 1))
    log_error "$*"
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [ "$item" = "$needle" ]; then
            return 0
        fi
    done
    return 1
}

validate_alias_mappings() {
    local role alias
    log_info "Validating LOCAL_MODEL_NAMES role mappings..."

    for role in fast general coder heavy reasoning embedding; do
        alias="${LOCAL_MODEL_NAMES[$role]:-}"
        if [ -z "$alias" ]; then
            record_warning "Role '$role' has no local alias defined"
            continue
        fi

        if [ -n "${GGUF_LOCAL_FILENAMES[$alias]:-${GGUF_FILENAMES[$alias]:-}}" ]; then
            log_status "Role '$role' -> '$alias' has GGUF metadata"
        else
            record_warning "Role '$role' -> '$alias' is missing GGUF metadata"
        fi
    done
}

validate_gguf_metadata() {
    local alias source quant filename family ctx template params
    log_info "Validating GGUF metadata coverage..."

    local role
    for role in "${!LOCAL_MODEL_NAMES[@]}"; do
        alias="${LOCAL_MODEL_NAMES[$role]}"
        source="${GGUF_SOURCES[$alias]:-}"
        quant="${GGUF_QUANTS[$alias]:-}"
        filename="${GGUF_LOCAL_FILENAMES[$alias]:-${GGUF_FILENAMES[$alias]:-}}"
        family="${GGUF_FAMILIES[$alias]:-}"
        ctx="${OLLAMA_CONTEXT_WINDOWS[$alias]:-}"
        params="$(modelfile_params_for_alias "$alias")"

        [ -n "$source" ] || record_error "Missing GGUF_SOURCES entry for alias '$alias'"
        [ -n "$quant" ] || record_error "Missing GGUF_QUANTS entry for alias '$alias'"
        [ -n "$filename" ] || record_error "Missing GGUF_LOCAL_FILENAMES entry for alias '$alias'"
        [ -n "$family" ] || record_warning "Missing GGUF_FAMILIES entry for alias '$alias'"

        if [ -n "$filename" ] && [[ "$filename" != *.gguf ]]; then
            record_error "GGUF filename for alias '$alias' does not end with .gguf: $filename"
        fi

        if [ -n "$ctx" ]; then
            local ctx_value
            for ctx_value in $ctx; do
                if [[ ! "$ctx_value" =~ ^[0-9]+$ ]]; then
                    record_error "OLLAMA_CONTEXT_WINDOWS entry for alias '$alias' must be numeric or a space-separated list of numerics: $ctx"
                    break
                fi
            done
        fi

        if [ -n "$params" ]; then
            local effective_params
            effective_params="$(printf '%s\n' "${params//\\n/$'\n'}" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')"
            if [ -n "$effective_params" ] && ! grep -q '^PARAMETER ' <<< "$effective_params"; then
                record_error "MODELFILE_PARAMS entry for alias '$alias' must contain PARAMETER directives: $effective_params"
            fi
        fi
    done
}

modelfile_params_for_alias() {
    local alias="$1"

    if declare -p MODELFILE_PARAMS &>/dev/null && [[ -v "MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s\n' "${MODELFILE_PARAMS[$alias]}"
        return 0
    fi

    # Compatibility for profiles that still use the old Ollama-prefixed map.
    if declare -p OLLAMA_MODELFILE_PARAMS &>/dev/null && [[ -v "OLLAMA_MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s\n' "${OLLAMA_MODELFILE_PARAMS[$alias]}"
        return 0
    fi

    return 0
}

validate_gguf_files() {
    local alias filename path spec quant source
    log_info "Checking GGUF artifacts on disk..."

    while IFS='|' read -r alias quant filename source; do
        [ -n "$filename" ] || continue
        path="${GGUF_DIR}/${filename}"

        if [ -f "$path" ]; then
            log_status "Found GGUF for '$alias' (${quant}): $path"
        else
            if [ "$REQUIRE_FILES" = "1" ]; then
                record_error "Missing GGUF artifact for '$alias' (${quant}): $path"
            else
                record_warning "GGUF artifact not present yet for '$alias' (${quant}): $path"
            fi
        fi
    done < <(
        for role in "${!LOCAL_MODEL_NAMES[@]}"; do
            alias="${LOCAL_MODEL_NAMES[$role]}"
            printf '%s|%s|%s|%s\n' "$alias" "${GGUF_QUANTS[$alias]:-}" "${GGUF_LOCAL_FILENAMES[$alias]:-${GGUF_FILENAMES[$alias]:-}}" "${GGUF_SOURCES[$alias]:-}"
            variants="${GGUF_VARIANTS[$alias]:-}"
            if [ -n "$variants" ]; then
                IFS=',' read -ra _variant_specs <<< "$variants"
                for spec in "${_variant_specs[@]}"; do
                    spec="$(echo "$spec" | sed 's/^ *//;s/ *$//')"
                    [ -n "$spec" ] || continue
                    IFS='|' read -r extra_quant extra_filename extra_source <<< "$spec"
                    printf '%s|%s|%s|%s\n' "$alias" "$extra_quant" "$extra_filename" "$extra_source"
                done
            fi
        done
    )
}

validate_unused_inventory() {
    log_info "Checking for incomplete GGUF and Ollama metadata..."

    local alias
    for alias in "${LOCAL_MODEL_NAMES[@]}"; do
        [ -n "${OLLAMA_CONTEXT_WINDOWS[$alias]:-}" ] || record_warning "Alias '$alias' has no OLLAMA_CONTEXT_WINDOWS entry"
    done
}

print_summary() {
    echo
    log_info "Validation summary for profile '${PROFILE_NAME}'"
    echo "  warnings: ${WARNINGS}"
    echo "  errors:   ${ERRORS}"

    if [ "$STRICT_MODE" = "1" ] && [ "$WARNINGS" -gt 0 ]; then
        log_error "Strict mode enabled: warnings are treated as failures"
        return 1
    fi

    if [ "$ERRORS" -gt 0 ]; then
        return 1
    fi

    return 0
}

validate_alias_mappings
validate_gguf_metadata
validate_gguf_files
validate_unused_inventory

if print_summary; then
    log_success "Profile validation passed"
    exit 0
else
    log_error "Profile validation failed"
    exit 1
fi
