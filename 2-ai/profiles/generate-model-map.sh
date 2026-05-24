#!/opt/homebrew/bin/bash
# generate-model-map.sh — Generate model→tool→role table + mermaid chart
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

# --- Edge collection ---
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

# Associative arrays — key = role label
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

# --- Unique model list ---
declare -A _seen=()
ALL_MODELS=()
for edge in "${EDGES[@]}"; do
    m="${edge%%|*}"
    if [[ -z "${_seen["$m"]:-}" ]]; then
        ALL_MODELS+=("$m")
        _seen["$m"]=1
    fi
done
IFS=$'\n' ALL_MODELS=($(sort -f <<<"${ALL_MODELS[*]}")); IFS=$' \t\n'
unset _seen

# --- Model metadata ---
declare -A MODEL_CAT=()
declare -A MODEL_SIZE=()

# Extract sizes from models.sh inline comments using ripgrep
if command -v rg &>/dev/null; then
    while IFS='|' read -r _name _size; do
        [[ -n "$_name" && -n "$_size" ]] && MODEL_SIZE["$_name"]="${_size} GB"
    done < <(rg -o '"(?P<n>[^"]+)"\s+#[^~]*~(?P<s>[\d.]+)\s*GB' "$MODELS_SH" -r '$n|$s' 2>/dev/null || true)
fi

# Fallback size inference by model name pattern
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

# Classify models by category
for m in "${ALL_MODELS[@]}"; do
    case "$m" in
        *"qwen3-coder-next"*)   MODEL_CAT["$m"]="Solo Coding" ;;
        *"qwen3-coder-30b"*)    MODEL_CAT["$m"]="Co-resident Coding" ;;
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

# --- Build per-category table data ---
declare -A CAT_ROWS=()
for edge in "${EDGES[@]}"; do
    IFS='|' read -r model tool role <<< "$edge"
    cat="${MODEL_CAT["$model"]}"
    size="${MODEL_SIZE["$model"]:-}"
    label="$model${size:+ ($size)}"
    CAT_ROWS["$cat"]+="${label}|${tool}|${role}"$'\n'
done

CAT_ORDER=("Solo Coding" "Co-resident Coding" "Architect" "Dense / Vision" "Writing" "Reasoning" "Planning" "Apply / Insert" "Autocomplete" "Embeddings" "Cloud")

sanitize() { echo "${1//[^a-zA-Z0-9]/_}"; }

# --- Generate output ---
OUTPUT="$PROFILES_DIR/$PROFILE/model-map.md"
{
    echo "# Model Map — $PROFILE"
    echo ""

    # ==============================
    # SECTION 1: MARKDOWN TABLE
    # ==============================
    echo "## Assignments by Category"
    echo ""

    for cat in "${CAT_ORDER[@]}"; do
        rows="${CAT_ROWS["$cat"]:-}"
        [[ -z "$rows" ]] && continue

        echo "### ${cat}"
        echo ""
        echo "| Model | Tool | Role |"
        echo "|------|------|------|"

        IFS=$'\n' sorted=($(sort -f <<< "$rows")); IFS=$' \t\n'
        for row in "${sorted[@]}"; do
            [[ -z "$row" ]] && continue
            IFS='|' read -r model tool role <<< "$row"
            echo "| \`${model}\` | ${tool} | ${role} |"
        done
        echo ""
    done

    # ==============================
    # SECTION 2: MERMAID CHART
    # ==============================
    echo "## Flow Diagram"
    echo ""
    echo '```mermaid'
    echo "graph LR"
    echo ""

    # Model nodes grouped by subgraph
    for cat in "${CAT_ORDER[@]}"; do
        _in=false
        for m in "${ALL_MODELS[@]}"; do
            if [[ "${MODEL_CAT["$m"]}" == "$cat" ]]; then
                if ! $_in; then
                    echo "    subgraph ${cat}[\"${cat}\"]"
                    _in=true
                fi
                mid=$(sanitize "$m")
                ml=$(echo "$m" | sed 's/:/\\:/g')
                echo "    ${mid}(\"${ml}\")"
            fi
        done
        if $_in; then
            echo "    end"
            echo ""
        fi
    done

    # Tool nodes
    echo "    subgraph Tools[\"Tools\"]"
    echo "    Cline[\"Cline\"]"
    echo "    ZooCode[\"Zoo Code\"]"
    echo "    KiloCode[\"Kilo Code\"]"
    echo "    Aider[\"Aider\"]"
    echo "    Zed[\"Zed\"]"
    echo "    Cursor[\"Cursor\"]"
    echo "    OpenCode[\"OpenCode\"]"
    echo "    Continue[\"Continue\"]"
    echo "    ClaudeCode[\"Claude Code\"]"
    echo "    end"
    echo ""

    # Edges with role labels
    for edge in "${EDGES[@]}"; do
        IFS='|' read -r model tool role <<< "$edge"
        mid=$(sanitize "$model")
        tid=$(sanitize "$tool")
        echo "    ${mid} -.->|${role}| ${tid}"
    done

    echo ""
    # Styles
    echo "    classDef local fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:#0d47a1"
    echo "    classDef cloud fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c"
    echo "    classDef tool fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#bf360c"
    for m in "${ALL_MODELS[@]}"; do
        mid=$(sanitize "$m")
        if [[ "${MODEL_CAT["$m"]}" == "Cloud" ]]; then
            echo "    class ${mid} cloud"
        else
            echo "    class ${mid} local"
        fi
    done
    for t in Cline ZooCode KiloCode Aider Zed Cursor OpenCode Continue ClaudeCode; do
        echo "    class $(sanitize "$t") tool"
    done

    # OpenRouter reference
    if [[ ${#OPENROUTER_MODELS[@]} -gt 0 ]]; then
        echo ""
        echo "    subgraph OpenRouterAvailable[\"OpenRouter (available)\"]"
        for cm in "${OPENROUTER_MODELS[@]}"; do
            echo "    or_$(sanitize "$cm")(\"${cm}\")"
        done
        echo "    end"
    fi

    echo '```'
    echo ""

    # ==============================
    # SECTION 3: OPENROUTER LIST
    # ==============================
    echo "## OpenRouter (cloud)"
    echo ""
    echo "The following models are available via OpenRouter but not stored locally:"
    echo ""
    for cm in "${OPENROUTER_MODELS[@]:-}"; do
        echo "- ${cm}"
    done
    echo ""
    echo "---"
    echo "Generated by \`generate-model-map.sh\` for profile \`$PROFILE\`. Edit \`models.sh\` and re-run to regenerate."
} > "$OUTPUT"

echo "✅ Wrote $OUTPUT"
