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
log_warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*" >&2; }
log_status()  { echo -e "${GREEN}✗${NC} $*" >&2; }
die()         { log_error "$*"; exit 1; }


# Ollama colon form → LiteLLM dash form  (qwen3-32b:q5 → qwen3-32b-q5)
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
