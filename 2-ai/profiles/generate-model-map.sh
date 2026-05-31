#!/opt/homebrew/bin/bash
# generate-model-map.sh — Generate a compact model→tool→role pivot matrix
set -euo pipefail

PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-${MACHINE_PROFILE:-}}"

if [[ -z "$PROFILE" ]]; then
    echo "Usage: $0 <profile-name>"
    echo "Available:"
    ls -d "$PROFILES_DIR"/*/ 2>/dev/null | while read -r d; do echo "  $(basename "$d")"; done
    exit 1
fi

MODELS_SH="$PROFILES_DIR/$PROFILE/models.sh"
[[ -f "$MODELS_SH" ]] || { echo "Error: $MODELS_SH not found."; exit 1; }
source "$MODELS_SH"

# ==============================================
# EDGE COLLECTION — model|tool|role triples
# ==============================================
EDGES=()

link() {
    local model="$1" tool="$2" role="$3"
    [[ -z "$model" ]] && return
    EDGES+=("${model}|${tool}|${role}")
}

# Associative tool model maps
if declare -p AIDER_MODELS &>/dev/null 2>&1; then
    for role in "${!AIDER_MODELS[@]}"; do
        link "${AIDER_MODELS[$role]}" "Aider" "$role"
    done
fi

# Scalar model vars
link "${CLINE_MODEL:-}"              "Cline"     "default"
link "${CLINE_MODEL_CLOUD:-}"        "Cline"     "cloud"
link "${ZOOCODE_MODEL:-}"            "ZooCode"   "default"
link "${ZOOCODE_MODEL_CLOUD:-}"      "ZooCode"   "cloud"
link "${ZOOCODE_MODE_CODE:-}"        "ZooCode"   "code"
link "${ZOOCODE_MODE_ARCHITECT:-}"   "ZooCode"   "architect"
link "${ZOOCODE_MODE_ASK:-}"         "ZooCode"   "ask"
link "${ZOOCODE_MODE_DEBUG:-}"       "ZooCode"   "debug"
link "${KILOCODE_MODEL:-}"           "KiloCode"  "default"
link "${KILOCODE_MODEL_CLOUD:-}"     "KiloCode"  "cloud"
link "${ZED_MODEL:-}"                "Zed"       "default"
link "${CURSOR_MODEL:-}"             "Cursor"    "default"
link "${CURSOR_MODEL_CLOUD:-}"       "Cursor"    "cloud"

if declare -p OPENCODE_AGENTS &>/dev/null 2>&1; then
    for role in "${!OPENCODE_AGENTS[@]}"; do
        link "${OPENCODE_AGENTS[$role]}" "OpenCode" "$role"
    done
fi
if declare -p CONTINUE_ROLES &>/dev/null 2>&1; then
    for role in "${!CONTINUE_ROLES[@]}"; do
        link "${CONTINUE_ROLES[$role]}" "Continue" "$role"
    done
fi
if declare -p CLAUDE_CODE &>/dev/null 2>&1; then
    for role in "${!CLAUDE_CODE[@]}"; do
        link "${CLAUDE_CODE[$role]}" "ClaudeCode" "$role"
    done
fi

# ==============================================
# UNIQUE MODELS — deduplicated, categorised, sorted
# ==============================================
declare -A _seen=()
ALL_MODELS=()
for edge in "${EDGES[@]}"; do
    m="${edge%%|*}"
    if [[ -z "${_seen["$m"]:-}" ]]; then
        ALL_MODELS+=("$m")
        _seen["$m"]=1
    fi
done
unset _seen

# Category classification
declare -A MODEL_CAT=()
for m in "${ALL_MODELS[@]}"; do
    case "$m" in
        *"qwen3-coder-next"*)   MODEL_CAT["$m"]="Solo Coding" ;;
        *"qwen3-coder-30b"*)    MODEL_CAT["$m"]="Co-resident" ;;
        *"codestral"*)          MODEL_CAT["$m"]="Apply / Insert" ;;
        *"qwen2.5-coder:1.5b"*) MODEL_CAT["$m"]="Autocomplete" ;;
        *"qwen2.5-coder:7b"*)   MODEL_CAT["$m"]="Autocomplete" ;;
        *"gemma4"*)             MODEL_CAT["$m"]="Dense / Vision" ;;
        *"qwen3.6"*)            MODEL_CAT["$m"]="Architect" ;;
        *"qwen3.5"*)            MODEL_CAT["$m"]="Writing" ;;
        *"deepseek-r1"*)        MODEL_CAT["$m"]="Reasoning" ;;
        *"qwen3:4b"*)           MODEL_CAT["$m"]="Planning" ;;
        *"nomic-embed"*)        MODEL_CAT["$m"]="Embeddings" ;;
        *"kimi"*)               MODEL_CAT["$m"]="Cloud" ;;
        *)                      MODEL_CAT["$m"]="Other" ;;
    esac
done

# Sort by category rank then alphabetically
CAT_ORDER=("Solo Coding" "Co-resident" "Architect" "Dense / Vision" "Writing" "Reasoning" "Planning" "Apply / Insert" "Autocomplete" "Embeddings" "Cloud")
declare -A CAT_RANK=()
for i in "${!CAT_ORDER[@]}"; do
    CAT_RANK["${CAT_ORDER[$i]}"]=$i
done

SORTED_MODELS=()
for m in "${ALL_MODELS[@]}"; do
    cat="${MODEL_CAT["$m"]}"
    rank="${CAT_RANK["$cat"]:-99}"
    SORTED_MODELS+=("${rank}|${m}")
done
IFS=$'\n' SORTED_MODELS=($(sort -t'|' -k1 -n <<<"${SORTED_MODELS[*]}")); IFS=$' \t\n'
for i in "${!SORTED_MODELS[@]}"; do
    SORTED_MODELS[$i]="${SORTED_MODELS[$i]#*|}"
done

# ==============================================
# LOOKUP — tool|model → comma-separated roles
# ==============================================
declare -A TOOL_MODEL_ROLES=()
for edge in "${EDGES[@]}"; do
    IFS='|' read -r model tool role <<< "$edge"
    key="${tool}|${model}"
    if [[ -n "${TOOL_MODEL_ROLES["$key"]:-}" ]]; then
        TOOL_MODEL_ROLES["$key"]+=", ${role}"
    else
        TOOL_MODEL_ROLES["$key"]="$role"
    fi
done

TOOLS=(Cline ZooCode KiloCode Aider Zed Cursor OpenCode Continue ClaudeCode)

# ==============================================
# MODEL SIZES — extractable comments or fallback
# ==============================================
declare -A MODEL_SIZE=()

if command -v rg &>/dev/null; then
    while IFS='|' read -r _name _size; do
        [[ -n "$_name" && -n "$_size" ]] && MODEL_SIZE["$_name"]="${_size} GB"
    done < <(rg -o '"(?P<n>[^"]+)"\s+#[^~]*~(?P<s>[\d.]+)\s*GB' "$MODELS_SH" -r '$n|$s' 2>/dev/null || true)
fi

for _m in "${ALL_MODELS[@]}"; do
    [[ -n "${MODEL_SIZE["$_m"]:-}" ]] && continue
    case "$_m" in
        *"80b"*)  MODEL_SIZE["$_m"]="48 GB" ;;
        *"35b"*)  MODEL_SIZE["$_m"]="22 GB" ;;
        *"31b"*)  MODEL_SIZE["$_m"]="19 GB" ;;
        *"30b"*)  MODEL_SIZE["$_m"]="26 GB" ;;
        *"27b"*)  MODEL_SIZE["$_m"]="19 GB" ;;
        *"22b"*)  MODEL_SIZE["$_m"]="12 GB" ;;
        *"7b"*)   MODEL_SIZE["$_m"]="5 GB" ;;
        *"4b"*)   MODEL_SIZE["$_m"]="2.5 GB" ;;
        *"1.5b"*) MODEL_SIZE["$_m"]="986 MB" ;;
        *"embed"*) MODEL_SIZE["$_m"]="0.3 GB" ;;
    esac
done


# ==============================================
# GGUF MATERIALIZATION LOOKUPS — HF → GGUF → Ollama
# ==============================================
escape_md_cell() {
    local value="$1"
    value="${value//$'\n'/<br>}"
    value="${value//|/\\|}"
    printf '%s' "$value"
}

mermaid_id() {
    local prefix="$1" value="$2" safe
    safe="$(printf '%s' "$value" | tr -c '[:alnum:]_' '_')"
    printf '%s_%s' "$prefix" "$safe"
}

mermaid_label() {
    local value="$1"
    value="${value//\"/}"
    printf '%s' "$value"
}

gguf_local_filename_for_alias() {
    local alias="$1"
    if declare -p GGUF_LOCAL_FILENAMES &>/dev/null && [[ -v "GGUF_LOCAL_FILENAMES[$alias]" ]]; then
        printf '%s' "${GGUF_LOCAL_FILENAMES[$alias]}"
    elif declare -p GGUF_FILENAMES &>/dev/null && [[ -v "GGUF_FILENAMES[$alias]" ]]; then
        printf '%s' "${GGUF_FILENAMES[$alias]}"
    fi
}

gguf_remote_filename_for_alias_quant() {
    local alias="$1" quant="$2" repo="$3"
    if declare -p GGUF_REMOTE_FILENAMES &>/dev/null && [[ -v "GGUF_REMOTE_FILENAMES[$alias]" ]]; then
        printf '%s' "${GGUF_REMOTE_FILENAMES[$alias]}"
        return
    fi

    local last base
    last="${repo#hf.co/}"
    last="${last%/}"
    last="${last##*/}"
    base="$last"
    [[ "$base" == *-GGUF ]] && base="${base%-GGUF}"
    printf '%s-%s.gguf' "$base" "$quant"
}

model_family_for_alias() {
    local alias="$1"
    if declare -p GGUF_FAMILIES &>/dev/null && [[ -v "GGUF_FAMILIES[$alias]" ]]; then
        printf '%s' "${GGUF_FAMILIES[$alias]}"
    else
        printf '%s' "${MODEL_CAT[$alias]:-local}"
    fi
}

model_params_for_alias() {
    local alias="$1"
    if declare -p MODELFILE_PARAMS &>/dev/null && [[ -v "MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s' "${MODELFILE_PARAMS[$alias]//$'\\n'/$'\n'}"
    elif declare -p OLLAMA_MODELFILE_PARAMS &>/dev/null && [[ -v "OLLAMA_MODELFILE_PARAMS[$alias]" ]]; then
        printf '%s' "${OLLAMA_MODELFILE_PARAMS[$alias]//$'\\n'/$'\n'}"
    fi
}

context_alias_suffix_for_ctx() {
    local ctx="$1"
    if [[ "$ctx" =~ ^[0-9]+$ ]] && (( ctx % 1024 == 0 )); then
        printf '%sk' "$((ctx / 1024))"
    else
        printf '%sctx' "$ctx"
    fi
}

context_values_for_alias() {
    local alias="$1"
    if declare -p OLLAMA_CONTEXT_WINDOWS &>/dev/null && [[ -v "OLLAMA_CONTEXT_WINDOWS[$alias]" ]]; then
        printf '%s' "${OLLAMA_CONTEXT_WINDOWS[$alias]}"
    fi
}

collect_materialized_aliases() {
    local alias role
    declare -A _materialized_seen=()

    if declare -p LOCAL_MODEL_NAMES &>/dev/null; then
        for role in "${!LOCAL_MODEL_NAMES[@]}"; do
            alias="${LOCAL_MODEL_NAMES[$role]}"
            if [[ -n "${alias:-}" && -z "${_materialized_seen[$alias]:-}" ]]; then
                printf '%s\n' "$alias"
                _materialized_seen[$alias]=1
            fi
        done
    fi

    if declare -p GGUF_SOURCES &>/dev/null; then
        for alias in "${!GGUF_SOURCES[@]}"; do
            if [[ -n "${alias:-}" && -z "${_materialized_seen[$alias]:-}" ]]; then
                printf '%s\n' "$alias"
                _materialized_seen[$alias]=1
            fi
        done
    fi
}

emit_materialization_row() {
    local alias="$1" repo="$2" quant="$3" local_file="$4" remote_file="$5" family="$6" ctx_values="$7" params="$8"
    local base_ctx="" variants="" ctx suffix first=true

    if [[ -n "$ctx_values" ]]; then
        read -ra _ctx_parts <<< "$ctx_values"
        base_ctx="${_ctx_parts[0]:-}"
        for ctx in "${_ctx_parts[@]:1}"; do
            [[ -z "$ctx" || "$ctx" == "$base_ctx" ]] && continue
            suffix="$(context_alias_suffix_for_ctx "$ctx")"
            if $first; then
                variants="${alias}-${suffix} (${ctx})"
                first=false
            else
                variants+=", ${alias}-${suffix} (${ctx})"
            fi
        done
    fi

    [[ -z "$variants" ]] && variants="—"
    [[ -z "$base_ctx" ]] && base_ctx="—"
    [[ -z "$params" ]] && params="—"

    printf '| `%s` | `%s` | `%s` | `%s` | `%s` | `%s` | `%s` | %s | %s |\n' \
        "$(escape_md_cell "$alias")" \
        "$(escape_md_cell "$repo")" \
        "$(escape_md_cell "$remote_file")" \
        "$(escape_md_cell "$quant")" \
        "$(escape_md_cell "$local_file")" \
        "$(escape_md_cell "$family")" \
        "$(escape_md_cell "$base_ctx")" \
        "$(escape_md_cell "$variants")" \
        "$(escape_md_cell "$params")"
}

emit_materialization_mermaid() {
    local aliases=("$@")
    local alias repo quant local_file remote_file family ctx_values params
    local hf_id remote_id local_id alias_id params_id ctx_id ctx suffix
    local emitted=false

    echo '```mermaid'
    echo 'flowchart LR'
    echo '  classDef hf fill:#eef6ff,stroke:#4b8bbe,color:#111;'
    echo '  classDef file fill:#f7f7f7,stroke:#999,color:#111;'
    echo '  classDef ollama fill:#edf7ed,stroke:#4f9d5d,color:#111;'
    echo '  classDef params fill:#fff7e6,stroke:#d99000,color:#111;'

    for alias in "${aliases[@]}"; do
        [[ -z "$alias" ]] && continue
        if ! declare -p GGUF_SOURCES &>/dev/null || [[ ! -v "GGUF_SOURCES[$alias]" ]]; then
            continue
        fi

        repo="${GGUF_SOURCES[$alias]}"
        quant="${GGUF_QUANTS[$alias]:-unknown}"
        local_file="$(gguf_local_filename_for_alias "$alias")"
        remote_file="$(gguf_remote_filename_for_alias_quant "$alias" "$quant" "$repo")"
        family="$(model_family_for_alias "$alias")"
        ctx_values="$(context_values_for_alias "$alias")"
        params="$(model_params_for_alias "$alias")"

        hf_id="$(mermaid_id hf "$repo")"
        remote_id="$(mermaid_id remote "${repo}|${remote_file}")"
        local_id="$(mermaid_id local "$local_file")"
        alias_id="$(mermaid_id ollama "$alias")"

        echo "  ${hf_id}[\"HF: $(mermaid_label "$repo")\"]:::hf"
        echo "  ${remote_id}[\"Remote GGUF: $(mermaid_label "$remote_file")\"]:::file"
        echo "  ${local_id}[\"Local GGUF: $(mermaid_label "$local_file")\"]:::file"
        echo "  ${alias_id}[\"Ollama: $(mermaid_label "$alias")\\nquant=${quant}; family=${family}\"]:::ollama"
        echo "  ${hf_id} --> ${remote_id} --> ${local_id} --> ${alias_id}"

        if [[ -n "$params" ]]; then
            params_id="$(mermaid_id params "$alias")"
            echo "  ${params_id}[\"MODELFILE params\"]:::params"
            echo "  ${params_id} -.-> ${alias_id}"
        fi

        if [[ -n "$ctx_values" ]]; then
            read -ra _ctx_parts <<< "$ctx_values"
            local base_ctx="${_ctx_parts[0]:-}"
            for ctx in "${_ctx_parts[@]:1}"; do
                [[ -z "$ctx" || "$ctx" == "$base_ctx" ]] && continue
                suffix="$(context_alias_suffix_for_ctx "$ctx")"
                ctx_id="$(mermaid_id ctx "${alias}-${suffix}")"
                echo "  ${ctx_id}[\"Ollama alias: $(mermaid_label "${alias}-${suffix}")\\nnum_ctx=${ctx}\"]:::ollama"
                echo "  ${alias_id} --> ${ctx_id}"
            done
        fi

        emitted=true
    done

    if ! $emitted; then
        echo '  none["No Hugging Face GGUF materialization metadata defined for this profile"]'
    fi
    echo '```'
}

# ==============================================
# OUTPUT
# ==============================================
OUTPUT="$PROFILES_DIR/$PROFILE/model-map.md"
{
    echo "# Model Map — $PROFILE"
    echo ""

    mapfile -t MATERIALIZED_ALIASES < <(collect_materialized_aliases | sort)

    # ------------------------------------------------------------------
    # 1. HF → GGUF → OLLAMA MATERIALIZATION
    # ------------------------------------------------------------------
    echo "## Hugging Face → GGUF → Ollama Materialization"
    echo ""
    echo "This is the profile-specific install graph: Hugging Face source repo, exact remote GGUF filename, normalized local artifact name, Ollama alias, MODELFILE parameters, and context-window aliases."
    echo ""
    echo "| Ollama alias | HF repo | Remote GGUF | Quant | Local GGUF | Family | Base num_ctx | Context aliases | MODELFILE params |"
    echo "| --- | --- | --- | --- | --- | --- | ---: | --- | --- |"
    for alias in "${MATERIALIZED_ALIASES[@]}"; do
        [[ -z "$alias" ]] && continue
        if ! declare -p GGUF_SOURCES &>/dev/null || [[ ! -v "GGUF_SOURCES[$alias]" ]]; then
            continue
        fi
        emit_materialization_row             "$alias"             "${GGUF_SOURCES[$alias]}"             "${GGUF_QUANTS[$alias]:-unknown}"             "$(gguf_local_filename_for_alias "$alias")"             "$(gguf_remote_filename_for_alias_quant "$alias" "${GGUF_QUANTS[$alias]:-unknown}" "${GGUF_SOURCES[$alias]}")"             "$(model_family_for_alias "$alias")"             "$(context_values_for_alias "$alias")"             "$(model_params_for_alias "$alias")"
    done
    echo ""
    echo "### Materialization graph"
    echo ""
    emit_materialization_mermaid "${MATERIALIZED_ALIASES[@]}"
    echo ""
    echo "---"
    echo ""

    # ------------------------------------------------------------------
    # 2. PIVOT MATRIX — tools × models
    # ------------------------------------------------------------------
    echo "## Model Assignment Matrix"
    echo ""
    echo "Tools across the rows, models across the columns. Cells show the role(s)"
    echo "each model plays in each tool.  \`-\` = not assigned."
    echo ""

    # Header row: model names with category in italics
    echo -n "| Tool |"
    for m in "${SORTED_MODELS[@]}"; do
        echo -n " ${m} |"
    done
    echo ""

    # Alignment row: centered for all model columns
    echo -n "| --- |"
    for _ in "${SORTED_MODELS[@]}"; do
        echo -n " :---: |"
    done
    echo ""

    # Data rows
    for tool in "${TOOLS[@]}"; do
        echo -n "| **${tool}** |"
        for model in "${SORTED_MODELS[@]}"; do
            key="${tool}|${model}"
            roles="${TOOL_MODEL_ROLES["$key"]:-}"
            if [[ -n "$roles" ]]; then
                echo -n " ${roles} |"
            else
                echo -n " — |"
            fi
        done
        echo ""
    done

    echo ""
    echo "---"
    echo ""

    # ------------------------------------------------------------------
    # 3. MODEL CATEGORIES REFERENCE
    # ------------------------------------------------------------------
    echo "## Model Categories"
    echo ""
    echo "| Category | # | Models |"
    echo "| --- | ---:| --- |"
    for cat in "${CAT_ORDER[@]}"; do
        cat_models=()
        for m in "${SORTED_MODELS[@]}"; do
            [[ "${MODEL_CAT["$m"]}" == "$cat" ]] && cat_models+=("$m")
        done
        [[ ${#cat_models[@]} -eq 0 ]] && continue
        first=true
        buf=""
        for m in "${cat_models[@]}"; do
            sz="${MODEL_SIZE["$m"]:-}"
            entry="\`${m}\`${sz:+ (${sz})}"
            if $first; then
                buf="$entry"
                first=false
            else
                buf+=", ${entry}"
            fi
        done
        echo "| **${cat}** | ${#cat_models[@]} | ${buf} |"
    done
    echo ""

    # ------------------------------------------------------------------
    # 4. OPENROUTER CLOUD MODELS
    # ------------------------------------------------------------------
    if [[ ${#OPENROUTER_MODELS[@]} -gt 0 ]]; then
        echo "## OpenRouter (cloud models)"
        echo ""
        echo "These models are available via OpenRouter — no local storage needed:"
        echo ""
        for cm in "${OPENROUTER_MODELS[@]:-}"; do
            echo "- ${cm}"
        done
        echo ""
    fi

    echo "---"
    echo "Generated by \`generate-model-map.sh\` for profile \`$PROFILE\`. Edit \`models.sh\` and re-run to regenerate."
} > "$OUTPUT"

echo "✅ Wrote $OUTPUT"
