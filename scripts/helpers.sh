# Colors for output

# ==============================================
# PROFILE DEFINITIONS
# ==============================================

# SCRIPT_DIR should be set by the sourcing script before using profile functions
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Profile folders are in the profiles subdirectory (relative to SCRIPT_DIR)
PROFILES_DIR="${SCRIPT_DIR}/profiles"

# Resolve to absolute path for reliability
PROFILES_DIR="$(cd "$PROFILES_DIR" && pwd)"

# Cache for loaded profile data
declare -A _PROFILE_CACHE=()

# Get all profile folders by scanning for PROFILE files
_get_profile_folders() {
    local -a profiles=()
    if [[ -d "$PROFILES_DIR" ]]; then
        for dir in "$PROFILES_DIR"/*/; do
            [[ -f "${dir}PROFILE" ]] || continue
            local folder
            folder=$(basename "$dir")
            profiles+=("$folder")
        done
        # Sort alphanumerically
        printf '%s\n' "${profiles[@]}" | sort
    fi
}

# Alias for backward compatibility
_get_profile_numbers() {
    _get_profile_folders
}

# Load profile data from PROFILE file
_load_profile() {
    local profile="$1"
    local cache_key="p${profile}"
    [[ -n "${_PROFILE_CACHE[$cache_key]:-}" ]] && return 0

    local profile_file="${PROFILES_DIR}/${profile}/PROFILE"
    if [[ -f "$profile_file" ]]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^# ]] && continue
            [[ -z "$key" || -z "$value" ]] && continue
            _PROFILE_CACHE["${cache_key}_${key}"]="$value"
        done < "$profile_file"
        _PROFILE_CACHE["${cache_key}_loaded"]="1"
    fi
}

# Get profile name from PROFILE file
_profile_name() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_NAME]:-Unknown}"
}

# Get profile folder from PROFILE file (returns the FOLDER value from PROFILE)
_profile_folder() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_FOLDER]:-}"
}

# Get profile memory from PROFILE file
_profile_memory() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_MEMORY]:-0}"
}

# Get profile memory range minimum from PROFILE file
_profile_memory_range_min() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_MEMORY_RANGE_MIN]:-0}"
}

# Get profile memory range maximum from PROFILE file
_profile_memory_range_max() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_MEMORY_RANGE_MAX]:-999}"
}

# Get profile computer types from PROFILE file
_profile_computer_types() {
    local profile="$1"
    _load_profile "$profile" || return 1
    echo "${_PROFILE_CACHE[p${profile}_COMPUTER_TYPES]:-*}"
}

# Check if a profile matches the current computer using the profile's own matching logic
# Each profile defines MEMORY_RANGE_MIN, MEMORY_RANGE_MAX, and COMPUTER_TYPES
_does_profile_match_computer() {
    local profile="$1"
    local hw_mem_gb="$2"
    local hw_model="$3"

    # Get profile's memory range
    local mem_min mem_max
    mem_min=$(_profile_memory_range_min "$profile")
    mem_max=$(_profile_memory_range_max "$profile")

    # Check if memory is within range
    if [[ "$hw_mem_gb" -lt "$mem_min" ]] || [[ "$hw_mem_gb" -gt "$mem_max" ]]; then
        return 1
    fi

    # Get profile's computer types and check for match
    local computer_types
    computer_types=$(_profile_computer_types "$profile")

    # Handle wildcard matching for computer types (comma-separated patterns)
    # Portable version that works in both bash and zsh
    local matched=0
    local old_ifs="$IFS"
    IFS=','
    for pattern in $computer_types; do
        # Trim whitespace
        pattern="${pattern#"${pattern%%[![:space:]]*}"}"
        pattern="${pattern%"${pattern##*[![:space:]]}"}"
        if [[ "$hw_model" == $pattern ]]; then
            matched=1
            break
        fi
    done
    IFS="$old_ifs"

    [[ "$matched" -eq 1 ]]
}

# Detect current machine profile using each profile's own _does_profile_match_computer() logic
_detect_profile() {
    local hw_mem_gb hw_model
    hw_mem_gb=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
    hw_model=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
    local best_match=""
    local best_mem=0

    while IFS= read -r folder; do
        # Use each profile's own matching function
        if _does_profile_match_computer "$folder" "$hw_mem_gb" "$hw_model"; then
            local mem
            mem=$(_profile_memory "$folder")
            # Pick the profile with the highest memory threshold that matches
            if [[ "$mem" -gt "$best_mem" ]]; then
                best_match="$folder"
                best_mem="$mem"
            fi
        fi
    done < <(_get_profile_numbers)

    # If no match found (e.g., more memory than any profile), use highest memory profile
    if [[ -z "$best_match" ]]; then
        best_match=$(ls -d "${PROFILES_DIR}"/*/ 2>/dev/null | while read -r d; do
            [[ -f "${d}PROFILE" ]] && basename "$d"
        done | sort | tail -1)
    fi

    echo "${best_match:-}"
}

# Get profile label (alias for _profile_name)
_profile_label() {
    _profile_name "$1"
}

# Profile descriptions from PROFILE files
_profile_description() {
    local folder="$1"
    _load_profile "$folder" || return 1
    echo "${_PROFILE_CACHE[p${folder}_DESCRIPTION]:-}"
}

# Generate profile menu options dynamically
print_profile_menu() {
    local detected="$1"
    local i=1
    local profile_num

    echo "  Detected hardware: $(_profile_label "$detected") (auto-selected as [$detected])"
    echo ""

    while IFS= read -r profile_num; do
        echo "  $i) $(_profile_label "$profile_num") — $(_profile_description "$profile_num")"
        i=$((i + 1))
    done < <(_get_profile_numbers)

    echo "  $i) exo — distributed inference across Apple Silicon Macs"
    i=$((i + 1))
    echo "  $i) Cancel"
}

# ==============================================
# LEGACY ALIAS (for compatibility with detect_mac_model)
# ==============================================

detect_mac_model() {
    local hw_mem_gb hw_model
    hw_mem_gb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))
    hw_model=$(sysctl -n hw.model)
    if [[ "$hw_mem_gb" -ge 56 ]]; then
        echo "macbook-m5-64gb"
    elif [[ "$hw_mem_gb" -ge 40 ]]; then
        echo "macbook-m5-48gb"
    elif [[ "$hw_model" == Macmini* || "$hw_model" == Mac14* ]]; then
        echo "macmini-m2"
    else
        echo "macbook-m1"   # 16GB fallback for all other machines
    fi
}


# Enhanced tool check with version information
check_tool_with_version() {
    local tool_name="$1"
    local command_name="$2"

    # Check CLI command first
    if command_exists "$command_name"; then
        local version_output
        version_output=$("$command_name" --version 2>/dev/null || "$command_name" version 2>/dev/null || echo "Version check not available")
        print_status "$tool_name is installed (version: $version_output)"
        return 0
    fi

    # Check for node modules (for tools that might be installed via npm)
    if command_exists "node" && npm list -g "$command_name" &> /dev/null; then
        print_status "$tool_name Node module found"
        return 0
    fi

    # Check for uv tools (for tools that might be installed via uv)

    if command_exists "uv" && uv tool list | grep -q "$command_name"; then
        print_status "$tool_name uv tool found"
        return 0
    fi

    # Check for executable in common locations
    local common_paths=(
        "/usr/local/bin/$command_name"
        "$HOME/.local/bin/$command_name"
        "$HOME/.npm-global/bin/$command_name"
        "/opt/$command_name/bin/$command_name"
        "$HOME/.config/yarn/global/node_modules/.bin/$command_name"
    )

    for path in "${common_paths[@]}"; do
        if [ -f "$path" ]; then
            print_status "$tool_name executable found at $path"
            return 0
        fi
    done

    print_warning "$tool_name not found"
    return 1
}

# Install via npm with error handling and verbose output
install_via_npm() {
    local tool_name="$1"
    local package_name="$2"

    print_info "Installing $tool_name via npm..."

    if command_exists "npm"; then
        print_info "Attempting npm install for $package_name..."
        if npm install -g "$package_name" --silent; then
            print_success "$tool_name installed successfully via npm"
            return 0
        else
            print_error "npm installation failed for $tool_name (package: $package_name)"
            return 1
        fi
    else
        print_warning "npm not available - cannot install $tool_name via npm"
        return 1
    fi
}


# Install Homebrew if not present
setup_homebrew() {
    print_info "Installing Homebrew..."

    if ! command_exists "brew"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_status "Homebrew installed successfully"
    else
        print_status "Homebrew already installed"
    fi
}

# Check common system requirements: curl, git, node, npm, python3, docker
check_system_requirements() {
    print_info "Checking system requirements..."

    if command_exists "curl"; then
        print_status "✓ curl found"
    else
        print_warning "⚠ curl not found - may affect downloads"
    fi

    if command_exists "git"; then
        print_status "✓ git found"
    else
        print_warning "⚠ git not found - some tools may require git"
    fi

    if command_exists "node"; then
        print_status "✓ Node.js found: $(node --version)"
    else
        print_warning "⚠ Node.js not found - npm-based installations will be limited"
    fi

    if command_exists "npm"; then
        print_status "✓ npm found: $(npm --version)"
    else
        print_warning "⚠ npm not found - npm-based installations will be limited"
    fi

    if command_exists "python3"; then
        print_status "✓ Python 3 found: $(python3 --version)"
    else
        print_warning "⚠ Python 3 not found - some tools may require Python"
    fi

    if command_exists "docker"; then
        print_status "✓ Docker found: $(docker --version 2>/dev/null || echo 'Docker found')"
    else
        print_info "ℹ Docker not found - some AI tools may benefit from Docker"
    fi
}
