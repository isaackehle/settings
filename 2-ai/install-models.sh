#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/2-ai/exo.sh"

# ==============================================
# PROFILE CONFIGURATION
# ==============================================

load_profile_models() {
    local profile="$1"
    local profile_file="${SETTINGS_BASE}/2-ai/profiles/${profile}/models.sh"
    if [[ -f "$profile_file" ]]; then
        . "$profile_file"
        return 0
    fi
    return 1
}

# ==============================================
# CONTEXT WINDOW VARIANTS
# Reads MODEL_CONTEXTS from the sourced models.sh and creates
# aliases via ollama create with PARAMETER num_ctx.
# Share underlying weights — zero additional disk space.
# ==============================================

create_context_variants() {
    if ! declare -p MODEL_CONTEXTS &>/dev/null; then
        echo "No MODEL_CONTEXTS defined — skipping context variants."
        return 0
    fi

    echo "Creating context window variants..."
    echo "===================================="
    echo ""

    local created=0 skipped=0
    for base_model in "${!MODEL_CONTEXTS[@]}"; do
        # Check that the base model weights exist locally.
        # If the exact tag isn't installed, try to create it from a context variant.
        local from_model
        from_model=$(ollama_find_model "$base_model")
        if [[ -z "$from_model" ]]; then
            echo "⚠ Base model not installed yet: $base_model — skipping context variants"
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
                echo "  ⚠ Failed to create base alias: $base_model — skipping context variants"
                rm -f "$tmp_mf"
                continue
            fi
            rm -f "$tmp_mf"
            # Now from_model = base_model for the context variant creation
            from_model="$base_model"
        fi

        local contexts="${MODEL_CONTEXTS[$base_model]}"
        for ctx in $contexts; do
            local alias="${base_model}-${ctx}"
            if ollama_model_exists "$alias"; then
                echo "✅ Already exists: $alias"
                ((skipped++)) || true
                continue
            fi

            # Parse num_ctx from suffix (e.g., "128k" → 131072, "32k" → 32768, "40k" → 40960)
            local num_ctx
            if [[ "$ctx" == *"k" ]]; then
                num_ctx=$((${ctx%k} * 1024))
            else
                num_ctx=$ctx
            fi

            echo "▶ Creating $alias (context=$num_ctx)"
            local tmp_mf
            tmp_mf=$(mktemp /tmp/ollama_ctx_XXXXXX)
            printf 'FROM %s\nPARAMETER num_ctx %s\n' "$from_model" "$num_ctx" > "$tmp_mf"
            if ollama create "$alias" -f "$tmp_mf"; then
                ((created++)) || true
                _ollama_list_invalidate
            else
                echo "⚠ Failed to create $alias"
            fi
            rm -f "$tmp_mf"
        done
    done

    echo ""
    echo "Context variants: $created created, $skipped already present"
    echo ""
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
            echo "✅ Already installed: $entry"
            passed+=("$entry")
        else
            echo "▶ Pulling cloud manifest: $entry"
            if ollama pull "$entry" 2>&1; then
                echo "✅ Cloud manifest installed: $entry"
                _ollama_list_invalidate
                passed+=("$entry")
            else
                echo "⚠ Failed to pull cloud manifest: $entry"
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

install_remote_models() {
    if ! declare -p MODEL_REMOTES &>/dev/null || [[ ${#MODEL_REMOTES[@]} -eq 0 ]]; then
        echo "No MODEL_REMOTES defined — skipping remote model aliases."
        return 0
    fi

    echo "Installing remote model aliases..."
    echo "===================================="
    echo ""

    local -a passed=()
    local -a failed=()

    for local_name in "${!MODEL_REMOTES[@]}"; do
        local remote_name="${MODEL_REMOTES[$local_name]}"

        # Skip if local alias already exists — exact match
        if ollama_model_exists "$local_name"; then
            echo "✅ Already installed: $local_name"
            passed+=("$local_name")
            echo ""
            continue
        fi

        echo "▶ Pulling remote: $remote_name → $local_name"
        if ollama pull "$remote_name"; then
            _ollama_list_invalidate
            # Create local alias from remote model
            local tmp_mf
            tmp_mf=$(mktemp /tmp/ollama_alias_XXXXXX)
            printf 'FROM %s\n' "$remote_name" > "$tmp_mf"
            if ollama create "$local_name" -f "$tmp_mf"; then
                echo "✅ Created alias: $local_name → $remote_name"
                _ollama_list_invalidate
                passed+=("$local_name")
            else
                echo "⚠ Pulled $remote_name but failed to create alias $local_name"
                echo "  Using remote name directly — tool configs may need updating."
                failed+=("$local_name")
            fi
            rm -f "$tmp_mf"
        else
            echo "⚠ Failed to pull: $remote_name"
            failed+=("$local_name")
        fi
        echo ""
    done

    echo "===================================="
    echo "Remote aliases: ${#passed[@]} installed, ${#failed[@]} failed"
    echo "===================================="
    echo ""
}

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
    # grep -q returns 0 on match, 1 on no match; suppress set -e concerns
    _ollama_list | grep -q "^${model_tag}[[:space:]]" && return 0 || return 1
}

# ==============================================
# HELPER: Check whether model weights exist locally.
# Matches exact tag OR any context variant (model:tag-NNNk).
# Returns the first matching model name (exact or variant), or empty.
# ==============================================
ollama_find_model() {
    local model_tag="$1"
    # Try exact match first
    local exact
    exact=$(_ollama_list | grep "^${model_tag}[[:space:]]" | awk '{print $1}' | head -1)
    if [[ -n "$exact" ]]; then
        echo "$exact"
        return 0
    fi
    # Fall back to context variant match (model:tag-NNNk)
    local variant
    variant=$(_ollama_list | grep "^${model_tag}-[0-9]" | awk '{print $1}' | head -1)
    if [[ -n "$variant" ]]; then
        echo "$variant"
        return 0
    fi
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
        echo "✅ Created alias: $base_model → $variant"
        rm -f "$tmp_mf"
        _ollama_list_invalidate
        return 0
    else
        echo "⚠ Failed to create alias $base_model from $variant"
        rm -f "$tmp_mf"
        return 1
    fi
}

# ==============================================
# MODEL INSTALLATION
# Pulls Ollama models. Entry format: plain Ollama name (e.g., "qwen3:14b").
# Skips :cloud entries (documentation only).
# ==============================================

install_ollama_models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _models
    eval "_models=(\"\${${arr_name}[@]}\")"

    echo "Installing Ollama models for $profile_name configuration..."
    echo "===================================================="
    echo ""

    local -a passed=()
    local -a failed=()
    local -a skipped_cloud=()
    local -a skipped_remote=()
    local entry

    for entry in "${_models[@]}"; do
        # Skip cloud entries (documentation only)
        if [[ "$entry" == *":cloud" ]]; then
            skipped_cloud+=("${entry%:cloud}")
            continue
        fi

        # Skip if a remote mapping exists — install_remote_models will handle it
        if declare -p MODEL_REMOTES &>/dev/null && [[ -n "${MODEL_REMOTES[$entry]+_}" ]]; then
            echo "⏭ $entry — will install from remote in next step"
            skipped_remote+=("$entry")
            continue
        fi

        # Skip if already installed — exact match on model:tag
        if ollama_model_exists "$entry"; then
            echo "✅ Already installed: $entry"
            passed+=("$entry")
            echo ""
            continue
        fi

        echo "▶ Installing: $entry"
        if ollama pull "$entry" 2>&1; then
            _ollama_list_invalidate
            passed+=("$entry")
        else
            # Pull failed — try to create base alias from an existing context variant
            echo "⚠ Pull failed for $entry — checking for context variant alias..."
            if create_base_from_context_variant "$entry"; then
                passed+=("$entry")
            else
                echo "⚠ No context variant found for $entry either"
                failed+=("$entry")
            fi
        fi
        echo ""
    done

    # Summary
    echo "===================================================="
    echo "Installation Summary for $profile_name:"
    echo "✅ Installed:"
    [[ ${#passed[@]} -eq 0 ]] && echo "  none" || printf '  - %s\n' "${passed[@]}"
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "❌ Failed:"
        printf '  - %s\n' "${failed[@]}"
    fi
    if [[ ${#skipped_cloud[@]} -gt 0 ]]; then
        echo "☁ Skipped cloud models:"
        printf '  - %s\n' "${skipped_cloud[@]}"
    fi
    if [[ ${#skipped_remote[@]} -gt 0 ]]; then
        echo "⏭ To be installed from remote (next step):"
        printf '  - %s\n' "${skipped_remote[@]}"
    fi
    echo "===================================================="
    echo ""

    # Offer to pull alternative quants and create local aliases
    if declare -p MODEL_QUANTS &>/dev/null && [[ ${#MODEL_QUANTS[@]} -gt 0 ]]; then
        echo "Alternative (higher-quality) quants available:"
        local q_index=1
        local -a q_tags=()
        local -a q_aliases=()
        # Sort keys for deterministic display order
        while IFS= read -r model_name; do
            local info="${MODEL_QUANTS[$model_name]}"
            # Format: "pull-tag|local-alias|size description"
            #   pull-tag:    the Ollama registry tag to pull
            #   local-alias:  the tag to create locally (empty = no alias needed)
            #   description:  human-readable size and role info
            # e.g. "qwen3.5:27b-q8_0|qwen3.5-27b:q8|29 GB (solo prose)"
            # e.g. "gemma4:31b-it-q8_0||28 GB (solo deep reasoning)"  (no alias needed)
            local pull_tag="${info%%|*}"
            local rest="${info#*|}"
            local local_alias="${rest%%|*}"
            local desc="${rest#*|}"
            q_tags+=("$pull_tag")
            q_aliases+=("$local_alias")
            if [[ -n "$local_alias" ]]; then
                echo "  $q_index) $pull_tag → $local_alias — $desc"
            else
                echo "  $q_index) $pull_tag — $desc"
            fi
            ((q_index++)) || true
        done < <(printf '%s\n' "${!MODEL_QUANTS[@]}" | sort)
        if [[ ${#q_tags[@]} -gt 0 ]]; then
            read -p "Pull any? Enter numbers (space-separated), 'a' for all, or Enter to skip: " quant_choices
            if [[ -n "$quant_choices" ]]; then
                echo ""
                if [[ "$quant_choices" == "a" || "$quant_choices" == "A" ]]; then
                    for i in "${!q_tags[@]}"; do
                        local q_model="${q_tags[$i]}"
                        local q_alias="${q_aliases[$i]}"
                        echo "▶ Pulling alternative quant: $q_model"
                        if ollama pull "$q_model"; then
                            echo "✅ $q_model pulled"
                            _ollama_list_invalidate
                            # Create local alias if one is specified
                            if [[ -n "$q_alias" ]]; then
                                echo "  ↳ Creating alias $q_alias → $q_model"
                                local tmp_mf
                                tmp_mf=$(mktemp /tmp/ollama_quant_XXXXXX)
                                printf 'FROM %s\n' "$q_model" > "$tmp_mf"
                                if ollama create "$q_alias" -f "$tmp_mf"; then
                                    echo "  ✅ Alias created: $q_alias"
                                    _ollama_list_invalidate
                                else
                                    echo "  ⚠ Failed to create alias $q_alias (model pulled but not aliased)"
                                fi
                                rm -f "$tmp_mf"
                            fi
                        else
                            echo "⚠ Failed to pull $q_model"
                        fi
                        echo ""
                    done
                else
                    for choice in $quant_choices; do
                        local idx=$((choice-1))
                        if [[ "$idx" -ge 0 && "$idx" -lt "${#q_tags[@]}" ]]; then
                            local q_model="${q_tags[$idx]}"
                            local q_alias="${q_aliases[$idx]}"
                            echo "▶ Pulling alternative quant: $q_model"
                            if ollama pull "$q_model"; then
                                echo "✅ $q_model pulled"
                                _ollama_list_invalidate
                                if [[ -n "$q_alias" ]]; then
                                    echo "  ↳ Creating alias $q_alias → $q_model"
                                    local tmp_mf
                                    tmp_mf=$(mktemp /tmp/ollama_quant_XXXXXX)
                                    printf 'FROM %s\n' "$q_model" > "$tmp_mf"
                                    if ollama create "$q_alias" -f "$tmp_mf"; then
                                        echo "  ✅ Alias created: $q_alias"
                                        _ollama_list_invalidate
                                    else
                                        echo "  ⚠ Failed to create alias $q_alias (model pulled but not aliased)"
                                    fi
                                    rm -f "$tmp_mf"
                                fi
                            else
                                echo "⚠ Failed to pull $q_model"
                            fi
                            echo ""
                        fi
                    done
                fi
            fi
        fi
    fi

    echo "✅ Installation process complete for $profile_name"
}

# ==============================================
# MAIN INSTALLER MENU
# ==============================================

install_coding_assistants() {
    print_step "Detecting hardware profile"
    local detected="${MACHINE_PROFILE}"

    echo ""
    echo "Ollama Model Installer"
    echo "======================"
    echo ""
    print_profile_menu "$detected"
    echo ""

    local num_profiles
    num_profiles=$(ls -d "${SETTINGS_BASE}/2-ai/profiles"/*/ 2>/dev/null | wc -l | tr -d ' ')
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
    echo "  1) Install / update models   — pull missing, create context variants"
    echo "  2) Prune orphan models       — remove models not in the $profile_name stack"
    echo "  3) Both                      — install then prune"
    echo ""
    read -p "Enter action [1-3] (Enter = 1): " action
    action="${action:-1}"

    case $action in
        1)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            install_remote_models
            install_cloud_models
            create_context_variants
            ;;
        2)
            print_step "Pruning orphan models for $profile_name"
            bash "${SETTINGS_BASE}/2-ai/profiles/prune_models.sh" "$profile"
            ;;
        3)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            install_remote_models
            install_cloud_models
            create_context_variants
            echo ""
            print_step "Pruning orphan models for $profile_name"
            bash "${SETTINGS_BASE}/2-ai/profiles/prune_models.sh" "$profile"
            ;;
        *)
            echo "Invalid action."
            return 1
            ;;
    esac
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
