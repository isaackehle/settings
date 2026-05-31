#!/opt/homebrew/bin/bash
# swap-model.sh — interactively replace a model for a given role and machine
# Cascades the change to all affected config files.
# Usage: swap-model.sh [--help]

# Only enable strict mode when this file is executed directly, not when sourced.
# Sourcing into an interactive shell with `set -e` would cause the parent shell
# to exit on the first non-zero status (e.g. closing the terminal).
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    set -euo pipefail
fi


if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

CONFIG_DIR="$SETTINGS_BASE/config"

CONFIG_DIR="$SETTINGS_BASE/config"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

# Color codes
NC='\033[0m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
YELLOW='\033[1;33m'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info()    { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${PURPLE}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*" >&2; }
log_status()  { echo -e "${GREEN}>${NC} $*" >&2; }
die()         { log_error "$*"; exit 1; }


# Ollama colon form → LiteLLM dash form  (qwen3-32b:q5-32k → qwen3-32b-q5-32k)
colon_to_dash() { echo "${1//:/-}"; }

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ai_setup.log
}

print_status() {
    echo -e "${GREEN}✓ $1${NC}"
    log_message "STATUS: $1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log_message "INFO: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    log_message "WARNING: $1"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    log_message "ERROR: $1"
}

print_success() {
    echo -e "${PURPLE}✓ SUCCESS: $1${NC}"
    log_message "SUCCESS: $1"
}

print_step() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
    log_message "STEP: $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a GitHub CLI extension is installed
# Usage: gh_extension_exists "extension"
gh_extension_exists() {
    local extension="$1"
    command_exists "gh" && gh extension list 2>/dev/null | grep -q "$extension"
}

# Compare two version strings. Returns 0 if $1 >= $2
version_ge() {
    [[ "$1" == "$2" ]] && return 0
    local IFS=.
    local i
    local v1=($1)
    local v2=($2)
    for ((i=${#v1[@]}; i<${#v2[@]}; i++)); do v1[i]=0; done
    for ((i=0; i<${#v1[@]}; i++)); do
        if [[ ${v1[i]} -gt ${v2[i]} ]]; then return 0; fi
        if [[ ${v1[i]} -lt ${v2[i]} ]]; then return 1; fi
    done
    return 0
}

# Check if a tool exists and meets a minimum version requirement
# Usage: check_tool_with_version "tool-name" "1.2.3"
check_tool_with_version() {
    local tool="$1"
    local min_version="$2"
    local version=""

    if [[ "$tool" == "zsh" ]]; then
        version=$(zsh -c 'echo $ZSH_VERSION' 2>/dev/null || echo "")
    elif command -v "$tool" >/dev/null 2>&1; then
        local output
        output=$("$tool" --version 2>&1)
        # Handle Homebrew Caskroom style output: /path/to/bin -> /path/to/Caskroom/tool/version/bin
        if [[ "$output" == *" -> "* ]]; then
            # Split by ' -> ' and take the target path
            local target_path="${output#* -> }"
            # Extract version from the target path (the segment that is just numbers and dots)
            version=$(echo "$target_path" | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1)
        elif [[ "$output" == *"/Caskroom/"* ]]; then
            version=$(echo "$output" | grep -oE '/[0-9]+(\.[0-9]+)+/' | head -n1 | tr -d '/')
        else
            version=$(echo "$output" | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1)
        fi
    else
        log_error "Tool '$tool' is not installed."
        return 1
    fi

    if [[ -z "$version" ]]; then
        log_error "Could not determine version for '$tool'."
        return 1
    fi

    if ! version_ge "$version" "$min_version"; then
        log_error "Tool '$tool' version $version is less than required $min_version."
        return 1
    fi

    return 0
}

# Check installed version of an npm package
check_with_version_via_npm() {
    local package="$1"
    local version
    version=$(npm ls -g "$package" --json 2>/dev/null | jq -r ".dependencies[\"$package\"].version // empty")
    echo "$version"
}


# Check installed version of a package via Homebrew (handles Caskroom path parsing)
check_with_version_via_brew() {
    local package="$1"
    local output

    # Use brew list --versions to get the package name and version
    output=$(brew list --versions "$package" 2>/dev/null)

    if [[ -z "$output" ]]; then
        echo ""
        return
    fi

    # Extract the version part (everything after the package name)
    echo "$output" | awk '{print $2}'
}

# Basic system requirements check
check_system_requirements() {
    echo "Checking system requirements..."
    if ! command_exists brew; then
        echo "Error: Homebrew is not installed. Please install it from https://brew.sh/"
        return 1
    fi
    echo "System requirements met."
    return 0
}

# Check if a VS Code extension is installed and print its details
# Usage: check_vscode_extension "extension.id"
check_vscode_extension() {
    local ext_id="$1"
    if ! command_exists "code"; then
        return 1
    fi

    local info
    info=$(code --list-extensions --show-versions | grep "^${ext_id}@")

    if [[ -z "$info" ]]; then
        return 1
    fi

    # Output format: extension.id@version
    # We can't easily get the 'Friendly Name' from CLI without parsing the marketplace or using a complex grep
    # but we can provide ID and Version.
    echo "$info"
    return 0
}

# Install a package via npm
install_via_npm() {
    local name="$1"
    local package="$2"

    print_info "Installing $name ($package)..."
    if npm install -g "$package" --silent; then
        print_success "$name installed successfully"
        return 0
    else
        print_error "Failed to install $name"
        return 1
    fi
}

# Shared backup globals (used by all setup scripts)
DATE="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/settings-backups"
mkdir -p "$BACKUP_DIR"


# Machine folder → folder name (Used for resolution in update functions)
declare -A MACHINE_DIRS=(
    ["macbook-m1-16gb"]="ai/profiles/macbook-m1-16gb"
    ["macbook-m2-32gb"]="ai/profiles/macbook-m2-32gb"
    ["macbook-m5-48gb"]="ai/profiles/macbook-m5-48gb"
    ["macbook-m5-64gb"]="ai/profiles/macbook-m5-64gb"
    ["macmini-m2-16gb"]="ai/profiles/macmini-m2-16gb"
)


# Find the best source file: model-specific takes precedence over default.
# Usage: find_source <relative-path-within-settings-repo>
# Prints the resolved path, or empty string if not found.
find_source() {
    local rel="$1"

    local model="${MACHINE_PROFILE:-}"

    local model_path="$SETTINGS_BASE/profiles/$model/$rel"
    local default_path="$SETTINGS_BASE/scripts/$rel"
    if [ -f "$model_path" ]; then
        echo "$model_path"
        elif [ -f "$default_path" ]; then
        echo "$default_path"
    else
        echo ""
    fi
}

# Copy src to dest, backing up any existing non-symlink file first.
copy_file() {
    local src="$1"
    local dest="$2"

    # Resolve source if it's a symlink
    if [ -L "$src" ]; then
        local real_src
        real_src=$(readlink -f "$src")
        if [ -n "$real_src" ] && [ -f "$real_src" ]; then
            src="$real_src"
        fi
    fi

    if [ -z "$src" ] || [ ! -f "$src" ]; then
        log_info "  (skip) source not found for $dest [$src]"
        return
    fi

    # Handle destination symlink (including broken symlinks) BEFORE other checks
    # Use -e to check if path exists (works for broken symlinks too)
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -f "$dest" ]; then
        # Skip if destination is identical to source
        if cmp -s "$src" "$dest"; then
            log_warning "  (skip) $dest is already up to date"
            return
        fi
        # Back up a real file that is different from what we'd copy
        mv "$dest" "${dest}.backup-$(date +%s)"
        echo "  backed up existing $(basename "$dest")"
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  copied $src -> $dest"
}

# Same as copy_file but looks up the source via find_source.
# Usage: install_config_file <config_file> <dest>
install_config_file() {
    local config_file="$1"
    local dest="$2"
    local src
    src="$CONFIG_DIR/$config_file"
    log_info "Installing $(basename "$dest") from $src..."
    copy_file "$src" "$dest"
}

# ============================================================================
# PROFILE DETECTION & MANAGEMENT
# ============================================================================

PROFILES_DIR="$SETTINGS_BASE/ai/profiles"
declare -A _PROFILE_CACHE

_get_profile_numbers() {
    # List directories in profiles dir, sorted
    ls -d "$PROFILES_DIR"/*/ 2>/dev/null | while read -r d; do
        basename "$d"
    done | sort
}

_load_profile() {
    local folder="$1"
    local profile_file="$PROFILES_DIR/$folder/PROFILE"
    if [[ ! -f "$profile_file" ]]; then return 1; fi

    # Load key=value pairs into cache
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        _PROFILE_CACHE["p${folder}_${key}"]="$value"
    done < "$profile_file"
}

_profile_name() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_NAME]:-Unknown}"
}

_profile_memory() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_MEMORY]:-0}"
}

_profile_computer_types() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_COMPUTER_TYPES]:-}"
}

_profile_description() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_DESCRIPTION]:-No description}"
}

_does_profile_match_computer() {
    local folder="$1"
    local hw_mem=$2
    local hw_model=$3

    _load_profile "$folder" || return 1

    local min=${_PROFILE_CACHE[p${folder}_MEMORY_RANGE_MIN]:-0}
    local max=${_PROFILE_CACHE[p${folder}_MEMORY_RANGE_MAX]:-9999}

    if [[ "$hw_mem" -lt "$min" || "$hw_mem" -gt "$max" ]]; then
        return 1
    fi

    local types=${_PROFILE_CACHE[p${folder}_COMPUTER_TYPES]:-""}
    local patterns=()
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        IFS=',' read -rA patterns <<< "$types"
    else
        IFS=',' read -ra patterns <<< "$types"
    fi
    for pattern in "${patterns[@]}"; do
        if [[ "$hw_model" == $pattern ]]; then
            return 0
        fi
    done

    return 1
}

_detect_hw() {
    HW_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
    HW_MEM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
}

_detect_profile() {
    _detect_hw
    local best_match=""
    local best_mem=0

    while IFS= read -r folder; do
        if _does_profile_match_computer "$folder" "$HW_MEM_GB" "$HW_MODEL"; then
            local mem
            mem=$(_profile_memory "$folder")
            if [[ "$mem" -gt "$best_mem" ]]; then
                best_match="$folder"
                best_mem="$mem"
            fi
        fi
    done < <(_get_profile_numbers)

    echo "${best_match:-}"
}

# Resolve machine profile once when helpers.sh is sourced.
# Pre-set MACHINE_PROFILE in the environment to override auto-detection.
if [ -z "${MACHINE_PROFILE:-}" ]; then
    _detect_hw
    MACHINE_PROFILE="$(_detect_profile)"
fi
export MACHINE_PROFILE HW_MODEL HW_MEM_GB

get_profile_for_choice() {
    local choice="$1"

    # If it's a number, resolve index
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$choice
        local profile
        profile=$( _get_profile_numbers | sed -n "${idx}p")
        echo "$profile"
    # If it's already a valid folder name
    elif [[ -d "$PROFILES_DIR/$choice" ]]; then
        echo "$choice"
    else
        return 1
    fi
}

# ============================================================================
# MENU / PROMPT FUNCTIONS
# ============================================================================

show_model_suggestions() {
    local mode="$1"
    echo "" >&2
    echo "  💡 Suggestions:" >&2
    if [[ "$mode" == "openrouter" ]]; then
        echo "    - anthropic/claude-3.5-sonnet" >&2
        echo "    - google/gemini-flash-1.5" >&2
        echo "    - meta-llama/llama-3.1-405b" >&2
        echo "    - deepseek/deepseek-chat" >&2
    else
        echo "    - qwen3.5:4b (planning / fast)" >&2
        echo "    - qwen2.5-coder:1.5b (autocomplete)" >&2
        echo "    - codestral:22b (apply / insert)" >&2
        echo "    - qwen3-coder-30b-a3b:q5 (coding)" >&2
    fi
    echo "" >&2
}

show_role_menu() {
    local mem_class="$1"

    # Read current models from the sourced associative array
    local -n _agents="OPENCODE_AGENTS"

    echo "" >&2
    echo "── CONFIGURE AGENT MODELS ─────────────────────────────────────" >&2
    echo "Set the model identifier for each agent role." >&2
    echo "" >&2
    echo "Current configuration ($mem_class):" >&2
    local roles=("coding" "reasoning" "research" "writing" "planning")
    local keys=("code"    "think"     "research" "write"   "plan")
    for i in "${!roles[@]}"; do
        printf "  %d) %-12s  %s\n" "$((i+1))" "${roles[$i]}" "${_agents[${keys[$i]}]:-<unset>}" >&2
    done
    echo "  6) ALL ROLES (Apply same model to all)" >&2
    echo "" >&2
}

prompt_role_menu() {
    local mem_class="$1"
    show_role_menu "$mem_class"

    local num_roles=6
    while true; do
        read -r -p "Which role are you configuring? [1-6]: " role_idx
        if [[ "$role_idx" =~ ^[1-6]$ ]]; then break; fi
        log_error "Invalid selection. Please enter 1-$num_roles."
    done

    case "$role_idx" in
        1) echo "coding" ;;
        2) echo "reasoning" ;;
        3) echo "research" ;;
        4) echo "writing" ;;
        5) echo "planning" ;;
        6) echo "all" ;;
    esac
}

print_profile_menu() {
    local detected="$1"
    local i=1
    local profile_num

    echo "  Detected hardware: $(_profile_name "$detected") (auto-selected as [$detected])" >&2
    echo "" >&2

    while IFS= read -r profile_num; do
        echo "  $i) $(_profile_name "$profile_num") — $(_profile_description "$profile_num")" >&2
        i=$((i + 1))
    done < <(_get_profile_numbers)

    echo "  $i) exo — distributed inference across Apple Silicon Macs" >&2
    i=$((i + 1))
    echo "  $i) Cancel" >&2
}

prompt_machine_class() {
    local detected
    detected="${MACHINE_PROFILE}"

    echo "" >&2
    echo "── SELECT MACHINE ──────────────────────────────────────────────────" >&2
    print_profile_menu "$detected"
    echo "" >&2

    local choice
    read -p "Select machine (Enter = $detected): " choice
    choice="${choice:-$detected}"

    # Get profile folder from choice
    local profile
    profile=$(get_profile_for_choice "$choice") || {
        log_error "Invalid selection."
        return 1
    }
    echo "$profile"
}

prompt_deployment_mode() {
    echo "" >&2
    echo "── SELECT DEPLOYMENT MODE ──────────────────────────────────────────" >&2
    echo "  1) Ollama Only (Direct)" >&2
    echo "  2) Ollama + OpenRouter (External)" >&2
    echo "" >&2

    local choice
    read -p "Select mode [1-2] (Default: 1): " choice
    choice="${choice:-1}"

    case "$choice" in
        1) echo "ollama" ;;
        2) echo "openrouter" ;;
        *)
            log_error "Invalid selection. Defaulting to Ollama."
            echo "ollama"
            ;;
    esac
}

# ============================================================================
# FILE UPDATE FUNCTIONS
# ============================================================================

# Update models.sh: agent map entry + CLAUDE_CODE_* var + CONTINUE_ROLES entry
update_models_sh() {
    local role="$1"
    local mem_class="$2"
    local old_val="$3"
    local new_val="$4"
    local mode="$5"

    local models_file="${SETTINGS_BASE}/${MACHINE_DIRS[$mem_class]}/models.sh"
    if [[ ! -f "$models_file" ]]; then
        log_warning "Models file not found: $models_file"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/models.sh..."

    # Update agent map for the given role
    if [[ "$role" != "all" ]]; then
        # Update the specific agent's model
        sed -i '' "s|^\(${role^^}_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        # Also update the cloud model if it exists (e.g., CLINE_MODEL_CLOUD)
        if grep -q "^${role^^}_MODEL_CLOUD\s*=" "$models_file"; then
            sed -i '' "s|^\(${role^^}_MODEL_CLOUD\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        fi
    else
        # Update all agents to the same model (for simplicity)
        sed -i '' "s|^\(CLINE_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(CLINE_MODEL_CLOUD\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(ZOOCODE_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(ZOOCODE_MODEL_CLOUD\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(KILOCODE_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(KILOCODE_MODEL_CLOUD\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(AIDER_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(AIDER_WEAK_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(AIDER_EDITOR_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(ZED_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(CURSOR_MODEL\s*=\).*|\1 \"${new_val}\"|" "$models_file"
        sed -i '' "s|^\(CURSOR_MODEL_CLOUD\s*=\).*|\1 \"${new_val}\"|" "$models_file"
    fi

    # Update CLAUDE_CODE_* variables (if any)
    if grep -q "^CLAUDE_CODE=" "$models_file"; then
        # We don't have a direct mapping for Claude Code roles, so we skip for now.
        # In the future, we might want to update the specific roles in the CLAUDE_CODE associative array.
        log_info "Claude Code roles are stored in an associative array; manual update may be needed."
    fi

    # Update CONTINUE_ROLES (if any)
    if grep -q "^CONTINUE_ROLES=" "$models_file"; then
        # We don't have a direct mapping for Continue roles, so we skip for now.
        log_info "Continue roles are stored in an associative array; manual update may be needed."
    fi

    log_success "  $(basename "$machine_dir")/models.sh"
}

# Update continue/config.yaml: model name
update_continue_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local continue_file="$machine_dir/continue/config.yaml"
    if [[ ! -f "$continue_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/continue/config.yaml..."

    if [[ "$mode" == "openrouter" ]]; then
        # OpenRouter uses the full model ID (e.g., anthropic/claude-3.5-sonnet)
        sed -i '' "s|model: ${old_val}|model: ${new_val}|g" "$continue_file"
        sed -i '' "s|small_model: ${old_val}|small_model: ${new_val}|g" "$continue_file"
    fi

    log_success "  $(basename "$machine_dir")/continue/config.yaml"
}

# Update claude/settings.json: model name
update_claude_settings() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local claude_file="$machine_dir/claude/settings.json"
    if [[ ! -f "$claude_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/claude/settings.json..."

    if [[ "$mode" == "openrouter" ]]; then
        # OpenRouter uses the full model ID (e.g., anthropic/claude-3.5-sonnet)
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$claude_file"
    fi

    log_success "  $(basename "$machine_dir")/claude/settings.json"
}

# Update opencode/opencode.jsonc: model name
update_opencode_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local opencode_file="$machine_dir/opencode/opencode.jsonc"
    if [[ ! -f "$opencode_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/opencode/opencode.jsonc..."

    if [[ "$mode" == "openrouter" ]]; then
        # OpenRouter uses the full model ID (e.g., anthropic/claude-3.5-sonnet)
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$opencode_file"
    fi

    log_success "  $(basename "$machine_dir")/opencode/opencode.jsonc"
}

# Update grok config: model name
update_grok_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local grok_file="$machine_dir/grok/grok.json"
    if [[ ! -f "$grok_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/grok/grok.json..."

    if [[ "$mode" == "openrouter" ]]; then
        # OpenRouter uses the full model ID (e.g., anthropic/claude-3.5-sonnet)
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$grok_file"
    fi

    log_success "  $(basename "$machine_dir")/grok/grok.json"
}


update_claude_settings() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local claude_file="$machine_dir/claude/settings.json"
    if [[ ! -f "$claude_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/claude/settings.json..."

    sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$claude_file"

    log_success "  $(basename "$machine_dir")/claude/settings.json"
}

update_opencode_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local opencode_file="$machine_dir/opencode/opencode.jsonc"
    if [[ ! -f "$opencode_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/opencode/opencode.jsonc..."

    # Model list keys + agent values
    sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$opencode_file"

    if [[ "$mode" == "ollama" ]]; then
        sed -i '' "s|ollama/${old_val}|ollama/${new_val}|g" "$opencode_file"
    fi

    log_success "  $(basename "$machine_dir")/opencode/opencode.jsonc"
}

update_grok_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local grok_file="$machine_dir/grok/grok.json"
    if [[ ! -f "$grok_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/grok/grok.json..."

    sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$grok_file"

    log_success "  $(basename "$machine_dir")/grok/grok.json"
}

update_obsidian_profile() {
    local mem_class="$1"
    local old_colon="$2"
    local new_colon="$3"

    local obsidian_file="$REPO_ROOT/config/profile.d/_obsidian"

    if [[ ! -f "$obsidian_file" ]]; then
        log_warning "_obsidian profile not found"
        return
    fi

    log_info "Updating config/profile.d/_obsidian..."

    # The profile uses colon form for Ollama direct calls
    sed -i '' "s|${old_colon}|${new_colon}|g" "$obsidian_file"

    log_success "  config/profile.d/_obsidian"
}

# ============================================================================
# MAIN FLOW
# ============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           helpers.sh — Interactive Configuration                 ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"

    # 1. Select machine
    local mem_class
    mem_class=$(prompt_machine_class) || die "Failed to select a valid machine class."

    if [[ -z "${MACHINE_DIRS[$mem_class]:-}" ]]; then
        die "Selected machine class '$mem_class' is not defined in MACHINE_DIRS."
    fi

    # 2. Select deployment mode
    local deploy_mode
    deploy_mode=$(prompt_deployment_mode)

    # Source the models file
    local models_file="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]}/models.sh"
    if [[ -f "$models_file" ]]; then
        source "$models_file"
    else
        die "Models file not found: $models_file"
    fi

    echo ""
    log_info "Machine: $mem_class (${MACHINE_DIRS[$mem_class]})"
    log_info "Mode:    $deploy_mode"

    # 3. Select role
    local role
    role=$(prompt_role_menu "$mem_class")
    echo ""
    log_info "Role: $role"

    local -n _cur_agents="OPENCODE_AGENTS"
    local current_model=""

    if [[ "$role" != "all" ]]; then
        local agent_key
        case "$role" in
            coding)   agent_key="code" ;;
            reasoning) agent_key="think" ;;
            research) agent_key="research" ;;
            writing)  agent_key="write" ;;
            planning) agent_key="plan" ;;
        esac
        current_model="${_cur_agents[$agent_key]:-}"
        if [[ -z "$current_model" ]]; then
            die "Could not determine current model for $role on $mem_class"
        fi
    else
        current_model="MULTIPLE"
    fi

    # 4. Prompt for configuration
    echo ""
    if [[ "$role" != "all" ]]; then
        echo "  Current: $current_model"
    else
        echo "  Current: Mixed (Setting all roles to same model)"
    fi
    echo ""

    show_model_suggestions "$deploy_mode"

    local prompt_text="New model alias (Ollama colon form, e.g. qwen3-32b:q6): "
    [[ "$deploy_mode" == "openrouter" ]] && prompt_text="New OpenRouter Model ID (e.g. anthropic/claude-3.5-sonnet): "

    read -r -p "$prompt_text" new_alias
    new_alias="${new_alias// /}"

    if [[ -z "$new_alias" ]]; then
        die "Model alias cannot be empty."
    fi

     local display_new="$new_alias"

    # Confirm
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                       CHANGE SUMMARY                            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "  %-12s %s\n" "Machine:"  "$mem_class (${MACHINE_DIRS[$mem_class]})"
    printf "  %-12s %s\n" "Mode:"     "$deploy_mode"
    printf "  %-12s %s\n" "Role:"     "$role"
    printf "  %-12s %s\n" "Current:" "$current_model"
    printf "  %-12s %s  →  %s\n" "Target:" "$new_alias" "$display_new"
    echo ""
    echo "  Files that will be updated:"
    echo "    scripts/models.sh"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/continue/config.yaml"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/claude/settings.json"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/opencode/opencode.jsonc"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/grok/grok.json"
    if [[ "$role" == "all" || "$role" == "research" ]]; then
        echo "    config/profile.d/_obsidian"
    fi
    echo ""

    read -r -p "Continue? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi

    echo ""
    local machine_dir="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]}"
    if [[ ! -d "$machine_dir" ]]; then
        die "Machine directory not found: $machine_dir"
    fi

    # Apply all updates
    if [[ "$role" == "all" ]]; then
        local roles=("coding" "reasoning" "research" "writing" "planning")
        local keys=("code"    "think"     "research" "write"   "plan")

        for i in "${!roles[@]}"; do
            local r="${roles[$i]}"
            local k="${keys[$i]}"
            local old="${_cur_agents[$k]:-}"

            log_info "Applying update to role: $r (Old: $old)"
            update_models_sh    "$r" "$mem_class" "$old" "$new_alias" "$deploy_mode"
            update_continue_config "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_claude_settings "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_opencode_config "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_grok_config  "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            if [[ "$r" == "research" ]]; then
                update_obsidian_profile "$mem_class" "$old" "$new_alias"
            fi
        done
    else
        update_models_sh    "$role" "$mem_class" "$current_model" "$new_alias" "$deploy_mode"
        update_continue_config "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_claude_settings "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_opencode_config "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_grok_config  "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"

        if [[ "$role" == "research" ]]; then
            update_obsidian_profile "$mem_class" "$current_model" "$new_alias"
        fi
    fi

    echo ""
    log_success "Done. Changes applied to repo — commit when ready."
    echo ""

    # Only offer to pull if using Ollama
    if [[ "$deploy_mode" == "ollama" ]]; then
        echo ""
        read -r -p "Pull new model via install_coding_assistants? (y/n): " install_choice
        if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
            source "$SETTINGS_BASE/install-models.sh"
            install_coding_assistants
        fi
    fi

    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
