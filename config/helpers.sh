# Colors for output

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
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
