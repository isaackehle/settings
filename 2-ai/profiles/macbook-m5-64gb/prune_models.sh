#!/opt/homebrew/bin/bash

# ==============================================================================
# Ollama Model Pruning Tool
# This script identifies installed models that are not required by the current
# machine profile and allows interactive deletion via fzf.
# ==============================================================================

# Source the model definitions
# If $1 is provided, use it as the directory containing models.sh
PROFILE_DIR="${1:-.}"
MODELS_FILE="${PROFILE_DIR}/models.sh"
if [[ -f "$MODELS_FILE" ]]; then
    source "$MODELS_FILE"
else
    echo "Error: $MODELS_FILE not found in $PROFILE_DIR"
    exit 1
fi

# Use an associative array to track why a model is required
declare -A REQUIRED_MODELS

# Helper to add model and reason
add_required() {
    local model=$1
    local reason=$2
    # Clean cloud models and empty strings
    if [[ -n "$model" ]] && [[ "$model" != *":cloud" ]]; then
        # Remove trailing context numbers if present in the alias (e.g., :q4-256k -> :q4)
        # Actually, ollama list usually shows the exact tag.
        # We'll keep the model as is but store it.
        REQUIRED_MODELS["$model"]="$reason"
    fi
}

# 1. Extract from OLLAMA_MODELS
for entry in "${OLLAMA_MODELS[@]}"; do
    # Split by pipe using a more robust method to avoid IFS issues in the loop
    IFS='|'
    read -ra PARTS <<< "$entry"
    IFS=' ' # Reset IFS to default
    for part in "${PARTS[@]}"; do
        # Ignore parts that are just numbers (context windows)
        if [[ ! "$part" =~ ^[0-9]+$ ]]; then
            add_required "$part" "Primary Model Definition"
        fi
    done
done

# 2. Extract from OPENCODE_AGENTS
for role in "${!OPENCODE_AGENTS[@]}"; do
    add_required "${OPENCODE_AGENTS[$role]}" "OpenCode Agent ($role)"
done

# 3. Extract from CONTINUE_ROLES
for role in "${!CONTINUE_ROLES[@]}"; do
    add_required "${CONTINUE_ROLES[$role]}" "Continue Role ($role)"
done

# 4. Extract from specific variables
add_required "$CLINE_MODEL" "Cline Model"
add_required "$CLINE_MODEL_CLOUD" "Cline Cloud Model"
add_required "$CLAUDE_CODE_SONNET" "Claude Code Sonnet"
add_required "$CLAUDE_CODE_HAIKU" "Claude Code Haiku"
add_required "$CLAUDE_CODE_OPUS" "Claude Code Opus"

# Get currently installed models (skipping header)
# Use a temporary file to store the list to avoid shell expansion issues
INSTALLED_MODELS_FILE=$(mktemp)
ollama list | tail -n +2 | tr -d '\r' | awk '{print $1}' > "$INSTALLED_MODELS_FILE"

# Load superseded reasons from model list.md if available
declare -A SUPERSEDED_REASONS
if [[ -f "model list.md" ]]; then
    while read -r line; do
        # Match either [SUPERCEDED] or [DELETE - SUPERCEDED]
        if [[ "$line" =~ ^\[(SUPERCEDED|DELETE\ -\ SUPERCEDED)\]\ ([^[:space:]]+)\ \|\ (.+)$ ]]; then
            SUPERSEDED_REASONS["${BASH_REMATCH[2]}"]="${BASH_REMATCH[3]}"
        fi
    done < "model list.md"
fi

# Prepare lists for fzf
KEEP_TMP=$(mktemp)
DELETE_TMP=$(mktemp)

# Use while read loop instead of for loop for robust string handling
while read -r model; do
    [[ -z "$model" ]] && continue
    
    if [[ -n "${REQUIRED_MODELS[$model]}" ]]; then
        printf "[KEEP]   %s | %s\n" "$model" "${REQUIRED_MODELS[$model]}" >> "$KEEP_TMP"
    elif [[ "$model" == *":cloud" ]] || [[ "$model" == *"-cloud" ]]; then
        printf "[CLOUD]      %s | Cloud-based model\n" "$model" >> "$DELETE_TMP"
    elif [[ -n "${SUPERSEDED_REASONS[$model]}" ]]; then
        printf "[SUPERCEDED] %s | %s\n" "$model" "${SUPERSEDED_REASONS[$model]}" >> "$DELETE_TMP"
    else
        printf "[DELETE]     %s | No specific use identified\n" "$model" >> "$DELETE_TMP"
    fi
done < "$INSTALLED_MODELS_FILE"

# Sort lists alphabetically.
SORTED_KEEP=$(sort "$KEEP_TMP")
SORTED_DELETE=$(sort "$DELETE_TMP")

# Clean up temp files
rm "$KEEP_TMP" "$DELETE_TMP" "$INSTALLED_MODELS_FILE"

# Combine lists: KEEP items first, then DELETE items
FZF_INPUT=$(printf "%s\n%s" "$SORTED_KEEP" "$SORTED_DELETE")

if [[ -z "$FZF_INPUT" ]]; then
    echo "No models installed."
    exit 0
fi

# Interactive selection using fzf
# -m allows multi-select with Tab or Space
# We pass the full list so the user sees everything on one page.
SELECTED_LINES=$(echo "$FZF_INPUT" | fzf -m \
    --bind 'space:toggle' \
    --header "SPACE to select models to delete, ENTER to confirm. [KEEP] items will be ignored." \
    --prompt "Pruning models: ")

if [[ -n "$SELECTED_LINES" ]]; then
    echo ""
    echo "Processing selection..."
    
    # Extract model names only for those marked [DELETE], [CLOUD], or [SUPERCEDED]
    MODELS_TO_DELETE=$(echo "$SELECTED_LINES" | grep -E "^(\[DELETE|\[CLOUD|\[SUPERCEDED)" | awk '{print $2}')

    if [[ -z "$MODELS_TO_DELETE" ]]; then
        echo "No deletable models were selected."
    else
        for model in $MODELS_TO_DELETE; do
            echo "Removing $model..."
            ollama rm "$model"
        done
        echo "Pruning complete."
    fi
else
    echo "No models selected for deletion."
fi


