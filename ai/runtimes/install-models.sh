#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/ai/other/exo.sh"
. "${SETTINGS_BASE}/ai/runtimes/runtime.sh"
. "${SETTINGS_BASE}/ai/runtimes/paths.sh"

ensure_profile_paths

# ==============================================
# PROFILE CONFIGURATION
# ==============================================

load_profile_models() {
    local profile="$1"
    local profile_file="${SETTINGS_BASE}/ai/profiles/${profile}/models.sh"
    if [[ ! -f "$profile_file" ]]; then
        return 1
    fi
    # When a file is sourced inside a function, bash makes `declare -A` variables
    # local to that function — they vanish on return. Promote them to global scope
    # by rewriting `declare -A` → `declare -gA` before sourcing.
    # shellcheck disable=SC1090
    source <(sed 's/^declare -A /declare -gA /g' "$profile_file")
}

ensure_profile_models_loaded() {
    local profile="$1"

    if [[ -z "$profile" ]]; then
        log_warning "⚠ No profile specified for model metadata load"
        return 1
    fi

    load_profile_models "$profile" || {
        log_warning "⚠ Could not load models for profile $profile"
        return 1
    }

    local missing_maps=()
    declare -p LOCAL_MODEL_NAMES &>/dev/null || missing_maps+=("LOCAL_MODEL_NAMES")
    declare -p GGUF_SOURCES      &>/dev/null || missing_maps+=("GGUF_SOURCES")
    declare -p GGUF_QUANTS       &>/dev/null || missing_maps+=("GGUF_QUANTS")
    declare -p GGUF_LOCAL_FILENAMES    &>/dev/null || missing_maps+=("GGUF_LOCAL_FILENAMES")
    if [[ ${#missing_maps[@]} -gt 0 ]]; then
        log_warning "⚠ Profile $profile is missing required GGUF metadata maps:"
        local m
        for m in "${missing_maps[@]}"; do echo "    • $m"; done
        return 1
    fi

    return 0
}

# ==============================================
# CONTEXT WINDOW / REMOTE ALIAS RECONCILIATION
# Uses OLLAMA_CONTEXT_WINDOWS as the canonical per-alias num_ctx source and
# MODEL_REMOTES for community namespace pulls that need local aliases.
# ==============================================

reconcile_ollama_aliases() {
    local has_contexts=0
    local has_remotes=0
    declare -p OLLAMA_CONTEXT_WINDOWS &>/dev/null && [[ ${#OLLAMA_CONTEXT_WINDOWS[@]} -gt 0 ]] && has_contexts=1
    declare -p MODEL_REMOTES &>/dev/null && [[ ${#MODEL_REMOTES[@]} -gt 0 ]] && has_remotes=1

    if [[ $has_contexts -eq 0 && $has_remotes -eq 0 ]]; then
        echo "No OLLAMA_CONTEXT_WINDOWS or MODEL_REMOTES defined — skipping alias reconciliation."
        return 0
    fi

    echo "Reconciling Ollama aliases..."
    echo "=============================="
    echo ""

    if [[ $has_contexts -eq 0 ]]; then
        echo "No OLLAMA_CONTEXT_WINDOWS defined — skipping context alias checks."
    fi

    if [[ $has_remotes -eq 0 ]]; then
        echo "No MODEL_REMOTES defined — skipping remote alias checks."
    fi

    local created=0 skipped=0 optional_missing=0

    if [[ $has_contexts -eq 1 ]]; then
    for base_model in "${!OLLAMA_CONTEXT_WINDOWS[@]}"; do
        # Check that the base model weights exist locally.
        # If the exact tag isn't installed, try to create it from a context variant.
        local from_model
        from_model=$(ollama_find_model "$base_model")
        if [[ -z "$from_model" ]]; then
            if gguf_alias_selected_for_install "$base_model"; then
                log_warning "Base model not installed yet: $base_model — skipping context alias reconciliation"
            else
                ((optional_missing++)) || true
            fi
            continue
        fi

        # If we found a context variant but not the exact tag, create the base alias first
        if [[ "$from_model" != "$base_model" ]]; then
            echo "  ↔ Creating base alias $base_model → $from_model"
            local tmp_mf
            tmp_mf=$(mktemp /tmp/ollama_base_XXXXXX)
            printf 'FROM %s\n' "$from_model" > "$tmp_mf"
            if ollama create "$base_model" -f "$tmp_mf"; then
                echo "  ✅ Created base alias: $base_model"
                _ollama_list_invalidate
            else
                log_warning "Failed to create base alias: $base_model — skipping context alias reconciliation"
                rm -f "$tmp_mf"
                continue
            fi
            rm -f "$tmp_mf"
            # Now from_model = base_model for the context variant creation
            from_model="$base_model"
        fi

        local contexts="${OLLAMA_CONTEXT_WINDOWS[$base_model]}"
        local num_ctx alias suffix ctx_value
        for ctx_value in $contexts; do
            num_ctx="$ctx_value"
            if (( num_ctx % 1024 == 0 )); then
                suffix="$((num_ctx / 1024))k"
            else
                suffix="$num_ctx"
            fi
            alias="${base_model}-${suffix}"

            if ollama_model_exists "$alias"; then
                log_success "✅ Context configured alias present: $alias (num_ctx=$num_ctx)"
                ((skipped++)) || true
                continue
            fi

            log_info "▶ Creating $alias (context=$num_ctx)"
            local tmp_mf
            tmp_mf=$(mktemp /tmp/ollama_ctx_XXXXXX)
            # Build the variant Modelfile from the base model's full modelfile so
            # the TEMPLATE is preserved — Ollama uses it to detect tool support.
            # Strip any existing num_ctx, then set the new one.
            ollama show --modelfile "$from_model" 2>/dev/null \
                | grep -v '^PARAMETER num_ctx' \
                > "$tmp_mf"
            printf 'PARAMETER num_ctx %s\n' "$num_ctx" >> "$tmp_mf"
            if ollama create "$alias" -f "$tmp_mf"; then
                ((created++)) || true
                _ollama_list_invalidate
            else
                log_warning "Failed to create $alias"
            fi
            rm -f "$tmp_mf"
        done
    done
fi

    if [[ $has_remotes -eq 1 ]]; then
        local local_name remote_name
        for local_name in "${!MODEL_REMOTES[@]}"; do
            remote_name="${MODEL_REMOTES[$local_name]}"
            if ollama_model_exists "$local_name"; then
                log_success "✅ Already installed: $local_name"
                ((skipped++)) || true
                continue
            fi

            log_info "▶ Pulling remote model: $remote_name"
            if ollama pull "$remote_name" 2>&1; then
                _ollama_list_invalidate
                if [[ "$local_name" != "$remote_name" ]]; then
                    local tmp_mf
                    tmp_mf=$(mktemp /tmp/ollama_remote_XXXXXX)
                    printf 'FROM %s\n' "$remote_name" > "$tmp_mf"
                    if ollama create "$local_name" -f "$tmp_mf"; then
                        log_success "✅ Created local alias: $local_name → $remote_name"
                        ((created++)) || true
                        _ollama_list_invalidate
                    else
                        log_warning "Failed to alias remote model: $local_name → $remote_name"
                    fi
                    rm -f "$tmp_mf"
                else
                    log_success "✅ Installed remote model: $remote_name"
                    ((created++)) || true
                fi
            else
                log_warning "Failed to pull remote model: $remote_name"
            fi
            echo ""
        done
    fi

    echo ""
    if [[ $optional_missing -gt 0 ]]; then
        log_info "Skipped $optional_missing optional context aliases that are not selected by LOCAL_MODEL_NAMES."
    fi
    echo "Alias reconciliation: $created created, $skipped already present, $optional_missing optional not installed"
    echo ""
}

gguf_alias_selected_for_install() {
    local wanted_alias="$1"
    local alias quant filename source remote_filename

    while IFS='|' read -r alias quant filename source remote_filename; do
        [[ -z "$alias" ]] && continue
        if [[ "$alias" == "$wanted_alias" ]]; then
            return 0
        fi
    done < <(iter_desired_gguf_specs)

    return 1
}

# ==============================================
# OLLAMA CLOUD MODELS
# Zero-disk manifests that route inference to remote servers.
# Each pull downloads only a tiny JSON manifest (~400 bytes).
# ==============================================

install_cloud_models() {
    if ! declare -p OLLAMA_CLOUD_MODELS &>/dev/null || [[ ${#OLLAMA_CLOUD_MODELS[@]} -eq 0 ]]; then
        echo "No OLLAMA_CLOUD_MODELS defined — skipping cloud models."
        return 0
    fi

    echo "Installing Ollama cloud model manifests..."
    echo "============================================"
    echo ""

    local -a passed=()
    local -a failed=()

    for entry in "${OLLAMA_CLOUD_MODELS[@]}"; do
        if ollama_model_exists "$entry"; then
            log_success "✅ Already installed: $entry"
            passed+=("$entry")
        else
            log_info "▶ Pulling cloud manifest: $entry"
            if ollama pull "$entry" 2>&1; then
                log_success "✅ Cloud manifest installed: $entry"
                _ollama_list_invalidate
                passed+=("$entry")
            else
                log_error "⚠ Failed to pull cloud manifest: $entry"
                failed+=("$entry")
            fi
        fi
        echo ""
    done

    echo "============================================"
    echo "Cloud models: ${#passed[@]} installed, ${#failed[@]} failed"
    echo "============================================"
    echo ""
}

# ==============================================
# REMOTE MODEL ALIASING
# Some models are not in the official Ollama library and must be
# pulled from a community namespace (e.g., MFDoom/). After pulling,
# a local alias is created so all tool configs use the short name.
# ==============================================


# ==============================================
# HELPER: Check whether a model:tag exists in the local Ollama list.
# Uses exact match: model:tag followed by whitespace only.
# This prevents "gemma4:31b" from matching "gemma4:31b-128k".
# Caches the list for the duration of the script to avoid repeated calls.
# ==============================================
_OLLAMA_LIST_CACHE=""
_ollama_list() {
    if [[ -z "$_OLLAMA_LIST_CACHE" ]]; then
        _OLLAMA_LIST_CACHE=$(ollama list 2>/dev/null)
    fi
    echo "$_OLLAMA_LIST_CACHE"
}

# Invalidate the model list cache (call after pull/create/rm operations)
_ollama_list_invalidate() {
    _OLLAMA_LIST_CACHE=""
}

ollama_model_exists() {
    local model_tag="$1"
    local listed_model
    while read -r listed_model; do
        [[ -z "$listed_model" ]] && continue
        if [[ "$listed_model" == "$model_tag" || "$listed_model" == "${model_tag}:latest" ]]; then
            return 0
        fi
    done < <(_ollama_list | awk 'NR>1 {print $1}')

    return 1
}

# ==============================================
# HELPER: Check whether model weights exist locally.
# Matches exact tag OR any context variant (model:tag-NNNk).
# Returns the first matching model name (exact or variant), or empty.
# ==============================================
ollama_find_model() {
    local model_tag="$1"
    local listed_model

    # Try exact match first. Ollama displays tagless models as :latest, so
    # consider model and model:latest equivalent for profile aliases without
    # an explicit tag.
    while read -r listed_model; do
        [[ -z "$listed_model" ]] && continue
        if [[ "$listed_model" == "$model_tag" || "$listed_model" == "${model_tag}:latest" ]]; then
            echo "$model_tag"
            return 0
        fi
    done < <(_ollama_list | awk 'NR>1 {print $1}')

    # Fall back to context variant match (model:tag-NNNk).
    while read -r listed_model; do
        [[ -z "$listed_model" ]] && continue
        if [[ "$listed_model" == "$model_tag"-[0-9]* ]]; then
            echo "$listed_model"
            return 0
        fi
    done < <(_ollama_list | awk 'NR>1 {print $1}')

    return 1
}

# ==============================================
# HELPER: Try to create a base model alias from an existing context variant.
# When ollama pull fails (e.g., "qwen3-coder-next-80b:q4" tag doesn't exist
# in the registry), we look for any installed context variant (e.g.,
# "qwen3-coder-next-80b:q4-16k") and create the base tag as an alias.
# ==============================================
create_base_from_context_variant() {
    local base_model="$1"

    # Check if base model already exists (exact match)
    if ollama_model_exists "$base_model"; then
        return 0
    fi

    # Find any installed model or context variant
    local variant
    variant=$(ollama_find_model "$base_model")
    if [[ -z "$variant" ]]; then
        return 1
    fi

    # If we found the exact model, nothing to do
    if [[ "$variant" == "$base_model" ]]; then
        return 0
    fi

    # Create the base model alias from the found variant
    echo "  ↳ Found variant: $variant — creating alias $base_model"
    local tmp_mf
    tmp_mf=$(mktemp /tmp/ollama_alias_XXXXXX)
    printf 'FROM %s\n' "$variant" > "$tmp_mf"
    if ollama create "$base_model" -f "$tmp_mf"; then
        log_success "✅ Created alias: $base_model → $variant"
        rm -f "$tmp_mf"
        _ollama_list_invalidate
        return 0
    else
        log_error "⚠ Failed to create alias $base_model from $variant"
        rm -f "$tmp_mf"
        return 1
    fi
}

preflight_validate_local_model_rebuild() {
    local runtime_selection="${1:-all}"

    echo "Running local model install/update pre-flight validation..."
    echo "=================================================="

    local errors=0

    local _missing=()
    declare -p LOCAL_MODEL_NAMES &>/dev/null || _missing+=("LOCAL_MODEL_NAMES")
    declare -p GGUF_SOURCES      &>/dev/null || _missing+=("GGUF_SOURCES")
    declare -p GGUF_QUANTS       &>/dev/null || _missing+=("GGUF_QUANTS")
    declare -p GGUF_LOCAL_FILENAMES    &>/dev/null || _missing+=("GGUF_LOCAL_FILENAMES")
    if [[ ${#_missing[@]} -gt 0 ]]; then
        log_warning "⚠ Missing GGUF metadata maps required for rebuild: ${_missing[*]}"
        return 1
    fi

    if [[ "$runtime_selection" != "hosted-only" && "$runtime_selection" != "exo" ]]; then
        if ! command -v huggingface-cli >/dev/null 2>&1; then
            log_warning "⚠ huggingface-cli not found in PATH"
            ((errors++)) || true
        fi
    fi

    if [[ "$runtime_selection" == all || "$runtime_selection" == ollama || "$runtime_selection" == ollama+llama.cpp || "$runtime_selection" == ollama+omlx || "$runtime_selection" == custom ]]; then
        if ! command -v ollama >/dev/null 2>&1; then
            log_warning "⚠ ollama not found in PATH"
            ((errors++)) || true
        fi
    fi

    local spec alias quant filename source remote_filename ctx params template model_name
    while IFS='|' read -r alias quant filename source remote_filename; do
        [[ -z "$alias" || -z "$quant" || -z "$filename" || -z "$source" ]] && continue
        model_name="$(canonical_ollama_model_name_for_alias_quant "$alias" "$quant")"
        ctx="${OLLAMA_CONTEXT_WINDOWS[$alias]:-}"
        params="$(modelfile_params_for_alias "$alias")"
        if declare -p OLLAMA_MODELFILE_TEMPLATES &>/dev/null; then
            template="${OLLAMA_MODELFILE_TEMPLATES[$alias]:-}"
        else
            template=""
        fi

        [[ "$filename" == *.gguf ]] || {
            log_warning "⚠ Invalid GGUF local filename for $model_name: $filename"
            ((errors++)) || true
        }
        [[ "$source" == hf.co/* ]] || {
            log_warning "⚠ Unsupported GGUF source for $model_name: $source"
            ((errors++)) || true
        }
        if [[ -n "$ctx" ]]; then
            local ctx_value
            for ctx_value in $ctx; do
                if [[ ! "$ctx_value" =~ ^[0-9]+$ ]]; then
                    log_warning "⚠ Invalid OLLAMA_CONTEXT_WINDOWS entry for $alias: $ctx"
                    ((errors++)) || true
                    break
                fi
            done
        fi
        if [[ -n "$template" && ! -f "$template" ]]; then
            log_warning "⚠ Missing Modelfile template for $alias: $template"
            ((errors++)) || true
        fi
        if [[ -n "$params" ]]; then
            # Strip comment and blank lines before checking for actual PARAMETER directives.
            # Profile metadata often stores multi-line Modelfile params in Bash
            # strings with literal "\n" separators; normalize those before
            # validation so we check the same content that will be written.
            local effective_params
            effective_params="$(normalize_ollama_modelfile_params "$params" | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')"
            if [[ -n "$effective_params" ]] && ! grep -q '^PARAMETER ' <<< "$effective_params"; then
                log_warning "MODELFILE_PARAMS for $alias must contain PARAMETER directives (got: $effective_params)"
                ((errors++)) || true
            fi
        fi
    done < <(iter_desired_gguf_specs)

    if [[ "$errors" -gt 0 ]]; then
        echo
        echo "Pre-flight validation failed with $errors error(s)."
        echo
        return 1
    fi

    log_success "✅ Pre-flight validation passed"
    echo
    return 0
}

install_or_update_local_ollama_from_gguf() {
    local profile="$1"
    local runtime_selection="${2:-all}"

    ensure_profile_models_loaded "$profile" || return 1
    preflight_validate_local_model_rebuild "$runtime_selection" || return 1

    materialize_profile_ggufs || {
        log_warning "Aborting local model install/update — GGUF materialization failed"
        return 1
    }

    register_ollama_models_from_gguf || {
        log_warning "Local Ollama model registration failed"
        return 1
    }

    return 0
}

transactional_rebuild_local_ollama_from_gguf() {
    local profile="$1"
    local runtime_selection="${2:-all}"

    ensure_profile_models_loaded "$profile" || return 1
    preflight_validate_local_model_rebuild "$runtime_selection" || return 1

    local snapshot_dir
    snapshot_dir="$(mktemp -d /tmp/ollama_rebuild_snapshot_XXXXXX)"
    local installed_before="${snapshot_dir}/installed-before.txt"
    ollama list 2>/dev/null | awk 'NR>1 {print $1}' > "$installed_before"

    materialize_profile_ggufs || {
        log_error "⚠ Aborting transactional rebuild — GGUF materialization failed"
        rm -rf "$snapshot_dir"
        return 1
    }

    remove_non_cloud_ollama_models || {
        log_error "⚠ Aborting transactional rebuild — failed to clear existing non-cloud Ollama models"
        rm -rf "$snapshot_dir"
        return 1
    }

    register_ollama_models_from_gguf || {
        log_error "⚠ Ollama re-registration failed after cleanup"
        echo "  Previous installed model snapshot: $installed_before"
        rm -rf "$snapshot_dir"
        return 1
    }

    rm -rf "$snapshot_dir"
    return 0
}

materialize_profile_ggufs() {
    local _missing=()
    declare -p LOCAL_MODEL_NAMES &>/dev/null || _missing+=("LOCAL_MODEL_NAMES")
    declare -p GGUF_SOURCES      &>/dev/null || _missing+=("GGUF_SOURCES")
    declare -p GGUF_QUANTS       &>/dev/null || _missing+=("GGUF_QUANTS")
    declare -p GGUF_LOCAL_FILENAMES    &>/dev/null || _missing+=("GGUF_LOCAL_FILENAMES")
    if [[ ${#_missing[@]} -gt 0 ]]; then
        echo "Skipping GGUF materialization — missing metadata maps: ${_missing[*]}"
        return 0
    fi

    echo "Materializing GGUF artifacts from Hugging Face..."
    echo "==============================================="

    # Resolve the HF CLI binary — prefer HF_CLI_BIN from paths.sh, fall back to PATH lookup.
    local hf_cli="${HF_CLI_BIN:-hf}"
    if ! command -v "$hf_cli" >/dev/null 2>&1; then
        log_warning "⚠ HF CLI not found (tried: $hf_cli)"
        echo "  Install with: uv tool install 'huggingface_hub[hf_xet,cli]'"
        echo "  Or: pip install 'huggingface_hub[hf_xet,cli]'"
        echo
        return 0
    fi

    mkdir -p "${GGUF_DIR}"

    local -a passed=()
    local -a failed=()
    local alias quant filename source remote_filename target repo model_name

    while IFS='|' read -r alias quant filename source remote_filename; do
        [[ -z "$alias" || -z "$quant" || -z "$filename" || -z "$source" ]] && continue

        target="${GGUF_DIR}/${filename}"
        model_name="$(canonical_ollama_model_name_for_alias_quant "$alias" "$quant")"

        if [[ -f "$target" ]]; then
            log_success "✅ Already present: $filename"
            passed+=("$model_name")
            continue
        fi

        repo="${source#hf.co/}"

        # remote_filename comes from GGUF_REMOTE_FILENAMES (or falls back to filename)
        # via iter_desired_gguf_specs — no guessing here.
        if [[ -z "$remote_filename" ]]; then
            # Shouldn't happen given iter_desired_gguf_specs always fills this,
            # but guard defensively.
            echo "  ⚠ No remote filename for $alias — skipping (add to GGUF_REMOTE_FILENAMES)"
            failed+=("$model_name")
            continue
        fi

        log_info "▶ Downloading GGUF for $model_name"
        echo "  alias:    $alias"
        echo "  repo:     $repo"
        echo "  remote:   $remote_filename"
        echo "  quant:    $quant"
        echo "  target:   $target"

        if "$hf_cli" download "$repo" "$remote_filename" \
                --local-dir "${GGUF_DIR}"; then

            # Rename if the remote filename differs from the desired local filename.
            if [[ -f "${GGUF_DIR}/${remote_filename}" && "$remote_filename" != "$filename" ]]; then
                mv -f "${GGUF_DIR}/${remote_filename}" "$target"
            fi

            if [[ -f "$target" ]]; then
                log_success "✅ Installed: $target"
                passed+=("$model_name")
            else
                log_error "⚠ Download succeeded but target file is missing: $target"
                echo "  (Expected it at ${GGUF_DIR}/${remote_filename} before rename)"
                failed+=("$model_name")
            fi
        else
            log_error "⚠ Download failed for $model_name"
            echo "  Repo:   $repo"
            echo "  File:   $remote_filename"
            echo "  Hint:   'Repository not found' usually means you need to authenticate."
            echo "          Run: $hf_cli auth login"
            echo "          Token: https://huggingface.co/settings/tokens (read-only is enough)"
            echo "          Then check auth: $hf_cli auth whoami"
            failed+=("$model_name")
        fi
        echo
    done < <(iter_desired_gguf_specs)

    echo "============================================"
    echo "GGUF artifacts: ${#passed[@]} installed, ${#failed[@]} failed"
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "Failed models:"
        local m
        for m in "${failed[@]}"; do echo "  • $m"; done
        echo "  Run: $hf_cli auth whoami   (check auth)"
        echo "============================================"
        echo
        return 1
    fi
    echo "============================================"
    echo
}

list_desired_cloud_models() {
    if ! declare -p OLLAMA_CLOUD_MODELS &>/dev/null || [[ ${#OLLAMA_CLOUD_MODELS[@]} -eq 0 ]]; then
        return 0
    fi

    printf '%s\n' "${OLLAMA_CLOUD_MODELS[@]}"
}

remove_non_cloud_ollama_models() {
    echo "Removing existing non-cloud Ollama models..."
    echo "==========================================="
    echo ""

    local installed
    installed="$(ollama list 2>/dev/null | awk 'NR>1 {print $1}')"
    if [[ -z "$installed" ]]; then
        echo "No Ollama models installed."
        echo
        return 0
    fi

    local -A keep=()
    local model
    while IFS= read -r model; do
        [[ -n "$model" ]] && keep["$model"]=1
    done < <(list_desired_cloud_models)

    local removed=0 kept=0 failed=0
    while IFS= read -r model; do
        [[ -z "$model" ]] && continue
        if [[ -n "${keep[$model]:-}" ]]; then
            log_info "☁ Keeping cloud model: $model"
            ((kept++)) || true
            continue
        fi

        log_warning "🗑 Removing Ollama model: $model"
        if ollama rm "$model" >/dev/null 2>&1; then
            ((removed++)) || true
            _ollama_list_invalidate
        else
            log_error "⚠ Failed to remove: $model"
            ((failed++)) || true
        fi
    done <<< "$installed"

    echo ""
    echo "Removed: $removed | Kept cloud: $kept | Failed: $failed"
    echo ""
}

iter_desired_gguf_specs() {
    declare -p LOCAL_MODEL_NAMES &>/dev/null || return 0
    declare -p GGUF_SOURCES      &>/dev/null || return 0
    declare -p GGUF_QUANTS       &>/dev/null || return 0
    declare -p GGUF_LOCAL_FILENAMES    &>/dev/null || return 0

    # Output format: alias|quant|local_filename|source|remote_filename
    # remote_filename is the verbatim filename on the HF repo.
    # local_filename is the simplified name stored under GGUF_DIR.
    # When GGUF_REMOTE_FILENAMES is not defined for an alias, falls back to local_filename.
    #
    # GGUF_VARIANTS format: "quant|local_filename|source[|remote_filename]"
    # remote_filename in variants is also optional; falls back to local_filename.

    local alias source quant filename remote_filename variants spec
    local extra_quant extra_filename extra_source extra_remote_filename
    for alias in "${LOCAL_MODEL_NAMES[@]}"; do
        source="${GGUF_SOURCES[$alias]:-}"
        quant="${GGUF_QUANTS[$alias]:-}"
        filename="${GGUF_LOCAL_FILENAMES[$alias]:-}"
        # GGUF_REMOTE_FILENAMES is optional — fall back to local filename if absent.
        if declare -p GGUF_REMOTE_FILENAMES &>/dev/null; then
            remote_filename="${GGUF_REMOTE_FILENAMES[$alias]:-$filename}"
        else
            remote_filename="$filename"
        fi
        if [[ -n "$source" && -n "$quant" && -n "$filename" ]]; then
            printf '%s|%s|%s|%s|%s\n' "$alias" "$quant" "$filename" "$source" "$remote_filename"
        fi

        variants="${GGUF_VARIANTS[$alias]:-}"
        if [[ -z "$variants" ]]; then
            continue
        fi

        IFS=',' read -ra _variant_specs <<< "$variants"
        for spec in "${_variant_specs[@]}"; do
            spec="$(echo "$spec" | sed 's/^ *//;s/ *$//')"
            [[ -z "$spec" ]] && continue
            # Parse optional 4th field: quant|local_filename|source|remote_filename
            IFS='|' read -r extra_quant extra_filename extra_source extra_remote_filename <<< "$spec"
            extra_remote_filename="${extra_remote_filename:-$extra_filename}"
            if [[ -n "$extra_quant" && -n "$extra_filename" && -n "$extra_source" ]]; then
                printf '%s|%s|%s|%s|%s\n' "$alias" "$extra_quant" "$extra_filename" "$extra_source" "$extra_remote_filename"
            fi
        done
    done
}

canonical_ollama_model_name_for_alias_quant() {
    local alias="$1"
    local quant="$2"
    if [[ "$quant" == "${GGUF_QUANTS[$alias]:-}" ]]; then
        printf '%s\n' "$alias"
    else
        local safe_quant
        safe_quant="$(echo "$quant" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')"
        printf '%s-%s\n' "$alias" "$safe_quant"
    fi
}

normalize_ollama_modelfile_params() {
    local params="$1"

    # Convert profile-friendly escaped newlines into real Modelfile lines.
    # printf '%b' interprets \n (and only \n, the only escape used in our params)
    # as actual newlines. We avoid ${var//\\n/$'\n'} here because some shell
    # environments do not correctly handle ANSI-C quoting inside expansions.
    printf '%b\n' "$params"
}

modelfile_params_for_alias() {
    local alias="$1"

    if declare -p MODELFILE_PARAMS &>/dev/null && [[ -v "MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s\n' "${MODELFILE_PARAMS[$alias]}"
        return 0
    fi

    # Backward-compatible fallback for profiles that have not yet been renamed.
    if declare -p OLLAMA_MODELFILE_PARAMS &>/dev/null && [[ -v "OLLAMA_MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s\n' "${OLLAMA_MODELFILE_PARAMS[$alias]}"
        return 0
    fi

    return 0
}

print_profile_gguf_breakdown() {
    local _missing=()
    declare -p LOCAL_MODEL_NAMES &>/dev/null || _missing+=("LOCAL_MODEL_NAMES")
    declare -p GGUF_SOURCES      &>/dev/null || _missing+=("GGUF_SOURCES")
    declare -p GGUF_QUANTS       &>/dev/null || _missing+=("GGUF_QUANTS")
    declare -p GGUF_LOCAL_FILENAMES &>/dev/null || _missing+=("GGUF_LOCAL_FILENAMES")
    if [[ ${#_missing[@]} -gt 0 ]]; then
        log_warning "Cannot describe GGUF profile — missing metadata maps: ${_missing[*]}"
        return 0
    fi

    echo "GGUF / Ollama model plan"
    echo "========================"
    echo "GGUF directory: ${GGUF_DIR}"
    echo

    local alias quant filename source remote_filename repo model_name family ctx params rename_note
    while IFS='|' read -r alias quant filename source remote_filename; do
        [[ -z "$alias" || -z "$quant" || -z "$filename" || -z "$source" ]] && continue

        repo="${source#hf.co/}"
        model_name="$(canonical_ollama_model_name_for_alias_quant "$alias" "$quant")"
        family="${GGUF_FAMILIES[$alias]:-generic}"
        ctx="${OLLAMA_CONTEXT_WINDOWS[$alias]:-}"
        params="$(modelfile_params_for_alias "$alias")"

        if [[ "$remote_filename" != "$filename" ]]; then
            rename_note="${remote_filename} → ${filename}"
        else
            rename_note="none"
        fi

        echo "• ${model_name}"
        echo "  alias:        ${alias}"
        echo "  family:       ${family}"
        echo "  Hugging Face: ${repo}"
        echo "  remote GGUF:  ${remote_filename}"
        echo "  local GGUF:   ${GGUF_DIR}/${filename}"
        echo "  rename:       ${rename_note}"
        echo "  quant:        ${quant}"
        echo "  num_ctx:      ${ctx:-default}"
        if [[ -n "$params" ]]; then
            echo "  Modelfile params:"
            normalize_ollama_modelfile_params "$params" | sed 's/^/    /'
        else
            echo "  Modelfile params: default"
        fi
        echo
    done < <(iter_desired_gguf_specs)
}

build_ollama_modelfile_from_gguf() {
    local alias="$1"
    local gguf_path="$2"
    local modelfile_path="$3"
    local quant_override="${4:-}"
    local filename_override="${5:-}"

    local quant="${quant_override:-${GGUF_QUANTS[$alias]:-}}"
    local filename="${filename_override:-${GGUF_LOCAL_FILENAMES[$alias]:-}}"
    local family="${GGUF_FAMILIES[$alias]:-generic}"
    local template=""
    if declare -p OLLAMA_MODELFILE_TEMPLATES &>/dev/null 2>&1; then
        template="${OLLAMA_MODELFILE_TEMPLATES[$alias]:-}"
    fi
    local ctx="${OLLAMA_CONTEXT_WINDOWS[$alias]:-}"
    local extra_params
    extra_params="$(modelfile_params_for_alias "$alias")"

    printf 'FROM %s\n' "$gguf_path" > "$modelfile_path"
    printf '# GGUF family: %s\n' "$family" >> "$modelfile_path"

    if [[ -n "$quant" ]]; then
        printf '# GGUF quant: %s\n' "$quant" >> "$modelfile_path"
    fi

    if [[ -n "$filename" ]]; then
        printf '# GGUF filename: %s\n' "$filename" >> "$modelfile_path"
    fi

    if [[ -n "$ctx" ]]; then
        local base_ctx="${ctx%% *}"
        printf 'PARAMETER num_ctx %s\n' "$base_ctx" >> "$modelfile_path"
    fi

    if [[ -n "$extra_params" ]]; then
        normalize_ollama_modelfile_params "$extra_params" >> "$modelfile_path"
    fi

    if [[ -n "$template" && -f "$template" ]]; then
        # Explicit template file — use it directly.
        sed '/^[[:space:]]*FROM[[:space:]]\+/d' "$template" >> "$modelfile_path"
    else
        # No explicit template file. Pull the TEMPLATE block from a reference
        # Ollama model (pulled via registry, so it has the correct Go template).
        # This preserves tool-calling support that local GGUF import loses.
        local ref_model
        ref_model="$(_gguf_template_ref_model "$alias" "$family")"
        if [[ -n "$ref_model" ]] && ollama_model_exists "$ref_model"; then
            local tmpl_block
            tmpl_block=$(ollama show --modelfile "$ref_model" 2>/dev/null \
                | awk '/^TEMPLATE/,/^[A-Z][A-Z_]*[[:space:]]|^$/' \
                | head -n -1)
            if [[ -n "$tmpl_block" && "$tmpl_block" != *'{{ .Prompt }}'* ]]; then
                printf '%s\n' "$tmpl_block" >> "$modelfile_path"
            fi
        fi
    fi
}

# (Archived: template overrides were removed in May 2026.
#  GGUFs now use their embedded Jinja2 templates directly.)

# ==============================================
# TEMPLATE HASH TRACKING
# Hash files stored alongside GGUFs so that template changes trigger
# automatic re-registration on the next install run.
# ==============================================

_template_hash_file() {
    local model_name="$1"
    local safe="${model_name//[:\/]/_}"
    printf '%s/.tmpl_%s' "${GGUF_DIR}" "$safe"
}

_current_template_hash() {
    local alias="$1"
    local template=""
    if declare -p OLLAMA_MODELFILE_TEMPLATES &>/dev/null 2>&1; then
        template="${OLLAMA_MODELFILE_TEMPLATES[$alias]:-}"
    fi
    if [[ -z "$template" || ! -f "$template" ]]; then
        echo "none"
    else
        shasum -a 256 "$template" 2>/dev/null | cut -d' ' -f1
    fi
}

_stored_template_hash() {
    local model_name="$1"
    local hf
    hf="$(_template_hash_file "$model_name")"
    [[ -f "$hf" ]] && cat "$hf" || echo ""
}

_save_template_hash() {
    local model_name="$1"
    local hash="$2"
    printf '%s\n' "$hash" > "$(_template_hash_file "$model_name")"
}

_template_changed() {
    local alias="$1"
    local model_name="$2"
    local current stored
    current="$(_current_template_hash "$alias")"
    stored="$(_stored_template_hash "$model_name")"
    # No template → never triggers a re-register
    [[ "$current" == "none" ]] && return 1
    # Hash differs or no stored hash → template changed
    [[ "$current" != "$stored" ]]
}

print_command_output_with_colored_errors() {
    local line
    while IFS= read -r line; do
        if [[ "$line" == Error:* || "$line" == *" error:"* || "$line" == *" failed"* || "$line" == *"Failed"* ]]; then
            log_error "$line"
        else
            printf '%s\n' "$line"
        fi
    done
}

register_ollama_models_from_gguf() {
    local _missing=()
    declare -p LOCAL_MODEL_NAMES &>/dev/null || _missing+=("LOCAL_MODEL_NAMES")
    declare -p GGUF_LOCAL_FILENAMES    &>/dev/null || _missing+=("GGUF_LOCAL_FILENAMES")
    if [[ ${#_missing[@]} -gt 0 ]]; then
        log_warning "Skipping Ollama GGUF registration — missing metadata maps: ${_missing[*]}"
        return 0
    fi

    echo "Registering Ollama models from local GGUF artifacts..."
    echo "====================================================="

    local -a passed=()
    local -a failed=()
    local spec alias quant filename source remote_filename gguf_path modelfile model_name family

    while IFS='|' read -r alias quant filename source remote_filename; do
        [[ -z "$alias" || -z "$filename" ]] && continue
        gguf_path="${GGUF_DIR}/${filename}"
        family="${GGUF_FAMILIES[$alias]:-generic}"
        model_name="$(canonical_ollama_model_name_for_alias_quant "$alias" "$quant")"

        if [[ ! -f "$gguf_path" ]]; then
            log_warning "Skipping $model_name — GGUF missing: $gguf_path"
            continue
        fi

        if ollama_model_exists "$model_name"; then
            if _template_changed "$alias" "$model_name"; then
                log_info "Template changed for $model_name — re-registering"
                # Delete the base model and all its context variants so reconcile
                # rebuilds them from the freshly-registered base.
                ollama rm "$model_name" 2>/dev/null || true
                _ollama_list_invalidate
                # Remove context variants (they inherit template from the base)
                local variant
                while IFS= read -r variant; do
                    [[ "$variant" == "${model_name}-"* ]] && \
                        { ollama rm "$variant" 2>/dev/null || true; _ollama_list_invalidate; }
                done < <(_ollama_list | awk '{print $1}')
            else
                log_success "Already registered in Ollama: $model_name"
                passed+=("$model_name")
                continue
            fi
        fi

        # Build the HF reference for the FROM line.
        # Using hf.co/<repo>:<remote_filename> lets Ollama read the model's
        # metadata directly from HF — template, capabilities, and tool call
        # extraction are all set correctly. Fall back to local path if no source.
        local hf_source="${GGUF_SOURCES[$alias]:-}"
        local model_ref
        if [[ -n "$hf_source" && -n "$remote_filename" ]]; then
            local repo="${hf_source#hf.co/}"
            model_ref="hf.co/${repo}:${remote_filename}"
        else
            model_ref="$gguf_path"
        fi

        log_info "▶ Registering Ollama model: $model_name"
        echo "  alias:  $alias"
        echo "  family: $family"
        echo "  quant:  $quant"
        echo "  source: $model_ref"

        modelfile=$(mktemp /tmp/ollama_gguf_XXXXXX)
        build_ollama_modelfile_from_gguf "$alias" "$model_ref" "$modelfile" "$quant" "$filename"

        local create_output
        if create_output="$(ollama create "$model_name" -f "$modelfile" 2>&1)"; then
            printf '%s\n' "$create_output"
            _ollama_list_invalidate
            _save_template_hash "$model_name" "$(_current_template_hash "$alias")"
            log_success "Registered Ollama model: $model_name"
            passed+=("$model_name")
        else
            print_command_output_with_colored_errors <<< "$create_output"
            log_error "Failed to register Ollama model: $model_name"
            log_error "Generated Modelfile was left at: $modelfile"
            modelfile=""
            failed+=("$model_name")
        fi
        [[ -z "$modelfile" ]] || rm -f "$modelfile"
        echo
    done < <(iter_desired_gguf_specs)


    echo "========================================================"
    echo "Ollama GGUF models: ${#passed[@]} registered, ${#failed[@]} failed"
    echo "========================================================"
    echo
}

# ==============================================
# GGUF INSTALLATION
# Materializes named GGUF artifacts from profile metadata.
# This first pass wires the fast role alias so llama-cpp.sh can resolve
# qwen3__4b.gguf deterministically from GGUF_LOCAL_FILENAMES.
# ==============================================

install_gguf_role_models() {
    if ! declare -p LOCAL_MODEL_NAMES &>/dev/null; then
        echo "No LOCAL_MODEL_NAMES defined — skipping GGUF role installs."
        return 0
    fi

    local role="fast"
    local alias="${LOCAL_MODEL_NAMES[$role]:-}"
    local source="${GGUF_SOURCES[$alias]:-}"
    local quant="${GGUF_QUANTS[$alias]:-}"
    local filename="${GGUF_LOCAL_FILENAMES[$alias]:-}"

    echo "Installing GGUF role models..."
    echo "=============================="

    if [[ -z "$alias" || -z "$source" || -z "$quant" || -z "$filename" ]]; then
        log_warning "⚠ Incomplete GGUF metadata for role '$role' — skipping"
        echo
        return 0
    fi

    local target="${GGUF_DIR}/${filename}"
    if [[ -f "$target" ]]; then
        log_success "✅ GGUF already present: $target"
        echo
        return 0
    fi

    local expected_repo="hf.co/Qwen/Qwen3-4B-Instruct-GGUF"
    local expected_quant="Q4_K_M"
    local expected_source_file="Qwen3-4B-Instruct-${expected_quant}.gguf"

    if [[ "$alias" != "qwen3:4b" || "$source" != "$expected_repo" || "$quant" != "$expected_quant" ]]; then
        log_warning "⚠ Fast-role GGUF wiring currently expects qwen3:4b from ${expected_repo} (${expected_quant})"
        echo "  Alias/source/quant changed in profile; skipping automatic materialization for safety."
        echo
        return 0
    fi

    log_info "▶ Downloading GGUF for $alias"
    echo "  source:   $source"
    echo "  quant:    $quant"
    echo "  target:   $target"

    mkdir -p "${GGUF_DIR}"
    local hf_cli="${HF_CLI_BIN:-hf}"
    if command -v "$hf_cli" >/dev/null 2>&1; then
        if "$hf_cli" download Qwen/Qwen3-4B-Instruct-GGUF "$expected_source_file" --local-dir "${GGUF_DIR}"; then
            if [[ -f "${GGUF_DIR}/${expected_source_file}" && "$expected_source_file" != "$filename" ]]; then
                mv -f "${GGUF_DIR}/${expected_source_file}" "$target"
            fi
            log_success "✅ Installed GGUF: $target"
        else
            log_error "⚠ Failed to download GGUF for $alias"
        fi
    else
        log_warning "⚠ HF CLI ($hf_cli) not found — cannot materialize $filename yet"
    fi
    echo
}

# ==============================================
# LEGACY OLLAMA PULL INSTALLATION
# Removed in favor of GGUF-first transactional rebuilds.
# ==============================================

# ==============================================
# MAIN INSTALLER MENU
# ==============================================

install_local_models_for_profile() {
    local profile="$1"
    local profile_name="$2"
    local runtime_selection="${3:-all}"

    print_step "Installing local model stack for $profile_name"
    log_info "Runtime selection: ${runtime_selection}"

    case "$runtime_selection" in
        all|llama.cpp|ollama|ollama+llama.cpp|omlx|ollama+omlx|custom)
            install_or_update_local_ollama_from_gguf "$profile" "$runtime_selection" || return 1
            ;;
        exo|hosted-only)
            log_info "Skipping GGUF materialization for runtime selection: ${runtime_selection}"
            ;;
        *)
            log_warning "Unknown runtime selection '$runtime_selection' — installing/updating local model set by default"
            install_or_update_local_ollama_from_gguf "$profile" "$runtime_selection" || return 1
            ;;
    esac

    case "$runtime_selection" in
        all|llama.cpp|ollama+llama.cpp|custom)
            install_gguf_role_models
            ;;
        ollama|omlx|ollama+omlx|exo|hosted-only)
            log_info "Skipping llama.cpp GGUF role setup for runtime selection: ${runtime_selection}"
            ;;
        *)
            install_gguf_role_models
            ;;
    esac

    case "$runtime_selection" in
        all|ollama|ollama+llama.cpp|ollama+omlx|custom)
            install_cloud_models
            reconcile_ollama_aliases
            ;;
        hosted-only)
            log_info "Skipping local Ollama registration for hosted-only selection"
            install_cloud_models
            reconcile_ollama_aliases
            ;;
        llama.cpp|omlx|exo)
            log_info "Skipping Ollama registration for runtime selection: ${runtime_selection}"
            ;;
        *)
            install_cloud_models
            reconcile_ollama_aliases
            ;;
    esac
}

review_local_model_plan_for_profile() {
    local profile="$1"
    local profile_name="$2"
    local runtime_selection="${3:-all}"

    print_step "Reviewing local model plan for $profile_name"
    log_info "Runtime selection: ${runtime_selection}"

    case "$runtime_selection" in
        exo|hosted-only)
            log_info "Runtime selection '${runtime_selection}' does not require local GGUF materialization."
            ;;
    esac

    ensure_profile_models_loaded "$profile" || return 1
    print_profile_gguf_breakdown
}

prune_local_models_for_profile() {
    local profile="$1"
    local profile_name="$2"

    print_step "Pruning unused local models for $profile_name"
    bash "${SETTINGS_BASE}/ai/profiles/prune_models.sh" "$profile"
}

manage_local_models() {
    print_step "Detecting hardware profile"
    local detected="${MACHINE_PROFILE}"

    echo ""
    echo "Local Model Stack Manager"
    echo "========================="
    echo ""
    print_profile_menu "$detected"
    echo ""

    local num_profiles
    num_profiles=$(ls -d "${SETTINGS_BASE}/ai/profiles"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local total_options=$((num_profiles + 2))

    read -p "Enter selection [1-$total_options] (Enter = $detected): " choice
    choice="${choice:-$detected}"

    print_step "Resolving profile for choice: $choice"

    local exo_choice=$((num_profiles + 1))
    local cancel_choice=$((num_profiles + 2))

    if [[ "$choice" == "$exo_choice" ]]; then
        print_step "Launching exo setup"
        setup_exo
        return
    fi

    if [[ "$choice" == "$cancel_choice" || "$choice" == "cancel" ]]; then
        echo "Installation cancelled."
        return
    fi

    local profile
    profile=$(get_profile_for_choice "$choice") || {
        echo "Invalid selection: '$choice'"
        return 1
    }
    print_step "Profile resolved: $profile"

    print_step "Loading model list for profile: $profile"
    load_profile_models "$profile" || {
        echo "Error: Could not load models for profile $profile"
        return 1
    }

    local profile_name="$(_profile_name "$profile")"

    echo ""
    echo "What would you like to do?"
    echo "  1) Install / update local models   — Ollama pulls, remote/cloud manifests, GGUF artifacts, context variants"
    echo "  2) Prune unused local models       — remove models not in the $profile_name stack"
    echo "  3) Sync local model stack          — install/update, then prune"
    echo ""
    read -p "Enter action [1-3] (Enter = 1): " action
    action="${action:-1}"

    case $action in
        1)
            install_local_models_for_profile "$profile" "$profile_name"
            ;;
        2)
            prune_local_models_for_profile "$profile" "$profile_name"
            ;;
        3)
            install_local_models_for_profile "$profile" "$profile_name"
            echo ""
            prune_local_models_for_profile "$profile" "$profile_name"
            ;;
        *)
            echo "Invalid action."
            return 1
            ;;
    esac
}

install_coding_assistants() {
    manage_local_models "$@"
}

# ==============================================
# INFO
# ==============================================

list_model_profiles() {
    echo "Available hardware profiles:"
    echo ""

    local i=1
    local folder
    while IFS= read -r folder; do
        echo "📋 $(_profile_label "$folder") — $(_profile_description "$folder")"
        i=$((i + 1))
    done < <(_get_profile_folders)

    echo "📋 exo — distributed inference across multiple Apple Silicon Macs"
    echo ""
    echo "Run install_coding_assistants to select and install"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_model_profiles
    install_coding_assistants
fi
