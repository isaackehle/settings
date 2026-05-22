#!/opt/homebrew/bin/bash

# ==============================================================================
# OLLAMA MODEL PRUNER
# Identifies installed models not defined in the current profile
# and provides an interactive interface to remove them.
#
# Usage:
#   ./prune_models.sh                  # auto-detect profile
#   ./prune_models.sh macbook-m5-64gb  # specify profile
# ==============================================================================

set -euo pipefail

PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load helpers for profile detection
SETTINGS_BASE="$(cd "$PROFILES_DIR/.." && pwd)"
if [[ -f "$SETTINGS_BASE/helpers.sh" ]]; then
    . "$SETTINGS_BASE/helpers.sh"
fi

# ------------------------------------------------------------------------------
# Resolve profile
# ------------------------------------------------------------------------------
if [[ $# -ge 1 ]]; then
    PROFILE="$1"
else
    PROFILE="${MACHINE_PROFILE}"
fi

if [[ -z "$PROFILE" ]]; then
    echo "Error: Could not auto-detect profile. Pass a profile name as argument."
    echo "Available profiles:"
    ls -d "$PROFILES_DIR"/*/ 2>/dev/null | while read -r d; do
        echo "  $(basename "$d")"
    done
    exit 1
fi

MODELS_SH="$PROFILES_DIR/$PROFILE/models.sh"

if [[ ! -f "$MODELS_SH" ]]; then
    echo "Error: $MODELS_SH not found."
    exit 1
fi

echo "Profile: $PROFILE"
echo "Config:  $MODELS_SH"

# Source the models configuration
source "$MODELS_SH"

# Temporary files for tracking
REQUIRED_MODELS_FILE=$(mktemp)
REASON_MAP_FILE=$(mktemp)
trap 'rm -f "$REQUIRED_MODELS_FILE" "$REASON_MAP_FILE"' EXIT

# Helper to register a required model and its reason
register_model() {
    local model_str="$1"
    local reason="$2"

    # Trim whitespace
    model_str=$(echo "$model_str" | xargs)
    if [[ -n "$model_str" ]]; then
        echo "$model_str" >> "$REQUIRED_MODELS_FILE"
        echo "$model_str|$reason" >> "$REASON_MAP_FILE"
    fi
}

echo "Analyzing requirements from $MODELS_SH..."

# 1. Process OLLAMA_MODELS array
if declare -p OLLAMA_MODELS &>/dev/null; then
    for entry in "${OLLAMA_MODELS[@]}"; do
        register_model "$entry" "Defined in OLLAMA_MODELS list"
    done
fi

# 2. Process OPENCODE_AGENTS
if declare -p OPENCODE_AGENTS &>/dev/null; then
    for agent in "${!OPENCODE_AGENTS[@]}"; do
        register_model "${OPENCODE_AGENTS[$agent]}" "Used by OpenCode agent: $agent"
    done
fi

# 3. Process CONTINUE_ROLES
if declare -p CONTINUE_ROLES &>/dev/null; then
    for role in "${!CONTINUE_ROLES[@]}"; do
        register_model "${CONTINUE_ROLES[$role]}" "Used by Continue role: $role"
    done
fi

# 4. Dynamically discover all other scalar model variables
#    Capture known prefixes and any variable that looks like a model assignment
for var in $(compgen -v); do
    # Skip arrays and associative arrays already processed above
    declare -p "$var" &>/dev/null || continue
    [[ "$(declare -p "$var" 2>/dev/null)" == "declare -"* ]] && continue

    # Only process variables that look like model names
    # (contain typical Ollama model patterns but aren't shell internals)
    val="${!var:-}"
    [[ -z "$val" ]] && continue

    # Skip arrays/assoc arrays, shell internals, and already-processed vars
    case "$var" in
        OLLAMA_MODELS|OPENCODE_AGENTS|CONTINUE_ROLES|OPENROUTER_MODELS) continue ;;
        BASH*|COMP*|DIRSTACK|FUNCNAME|GROUPS|PIPESTATUS|SHLVL|_|RANDOM|SECONDS|LINENO|OPTERR) continue ;;
        PROFILE|PROFILES_DIR|SETTINGS_BASE|MODELS_SH|REQUIRED_MODELS_FILE|REASON_MAP_FILE) continue ;;
        DATE|BACKUP_DIR|HW_MODEL|HW_MEM_GB|REPO_ROOT|NC|BLUE|GREEN|PURPLE|RED|YELLOW) continue ;;
    esac

    # Match variables whose values look like Ollama model identifiers
    # (contain a colon or match known model patterns, and aren't paths/numbers)
    if [[ "$val" == *":"* ]] && [[ "$val" != /* ]] && [[ "$val" != *"/"* ]]; then
        register_model "$val" "Used by variable: $var"
    fi
done

# Get unique list of required models
sort -u "$REQUIRED_MODELS_FILE" -o "$REQUIRED_MODELS_FILE"

# Get currently installed models from Ollama
INSTALLED_MODELS=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

echo -e "\n=== REQUIRED MODELS (INSTALLED) ==="
printf "%-35s %s\n" "MODEL" "REASON"
echo "--------------------------------------------------------------------------------"

OBSOLETE_MODELS=()

if [[ -z "$INSTALLED_MODELS" ]]; then
    echo "(no models installed)"
fi

while read -r installed; do
    [[ -z "$installed" ]] && continue
    # Check if installed model is in required list
    if grep -q "^${installed}$" "$REQUIRED_MODELS_FILE"; then
        reason=$(grep "^${installed}|" "$REASON_MAP_FILE" | cut -d'|' -f2 | head -n 1)
        printf "%-35s %s\n" "$installed" "$reason"
    else
        OBSOLETE_MODELS+=("$installed")
    fi
done <<< "$INSTALLED_MODELS"

if [ ${#OBSOLETE_MODELS[@]} -eq 0 ]; then
    echo -e "\nNo obsolete models found. Your installation is clean!"
    exit 0
fi

echo -e "\n=== OBSOLETE MODELS (NOT IN CONFIG) ==="
echo "The following models are installed but not required by profile: $PROFILE"
echo "Use SPACE to select models for removal, ENTER to confirm."

# Check for fzf
if command -v fzf >/dev/null 2>&1; then
     # Use fzf for interactive multi-selection
     SELECTED_MODELS=$(printf "%s\n" "${OBSOLETE_MODELS[@]}" | fzf --multi --header "Select models to DELETE (Space=Select, Enter=Confirm)" --bind 'space:toggle')

    if [[ -n "$SELECTED_MODELS" ]]; then
        echo -e "\nRemoving selected models..."
        while read -r model; do
            echo "Removing $model..."
            ollama rm "$model"
        done <<< "$SELECTED_MODELS"
        echo "Pruning complete."
    else
        echo "No models selected for removal."
    fi
else
    echo "Error: 'fzf' is not installed. Interactive selection is unavailable."
    echo "Please install fzf via 'brew install fzf' for the best experience."
    echo ""
    echo "Obsolete models:"
    printf "  %s\n" "${OBSOLETE_MODELS[@]}"
    exit 1
fi