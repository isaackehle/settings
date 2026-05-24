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
link "${AIDER_MODEL:-}"              "Aider"     "default"
link "${AIDER_WEAK_MODEL:-}"         "Aider"     "weak"
link "${AIDER_EDITOR_MODEL:-}"       "Aider"     "editor"
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
# OUTPUT
# ==============================================
OUTPUT="$PROFILES_DIR/$PROFILE/model-map.md"
{
    echo "# Model Map — $PROFILE"
    echo ""

    # ------------------------------------------------------------------
    # 1. PIVOT MATRIX — tools × models
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
    # 2. MODEL CATEGORIES REFERENCE
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
    # 3. OPENROUTER CLOUD MODELS
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
