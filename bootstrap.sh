#!/opt/homebrew/bin/bash
set -e

# Bootstrap script for Isaac's environment
# Handles core dependencies and provides selective installation based on docs categories.

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ---------------------------------------------------------------------------
# 1. Core Dependencies
# ---------------------------------------------------------------------------

install_core_dependencies() {
    echo "=== Step 1: Core Dependencies ==="
    
    # Install Homebrew if missing
    if ! command -v brew &> /dev/null; then
        print_info "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add brew to path for the current session
        eval "$(/opt/homebrew/bin/brew shellenv)"
        print_success "Homebrew installed."
    else
        print_info "Homebrew is already installed."
    fi
    
    # Install GitHub CLI (gh) if missing
    if ! command -v gh &> /dev/null; then
        print_info "GitHub CLI (gh) not found. Installing..."
        brew install gh
        print_success "GitHub CLI installed."
    else
        print_info "GitHub CLI is already installed."
    fi
}

# ---------------------------------------------------------------------------
# 2. Selective Installation
# ---------------------------------------------------------------------------

run_selective_install() {
    echo ""
    echo "=== Step 2: Selective Installation ==="
    echo "Based on the 'docs' structure, choose which portions to install:"
    echo "------------------------------------------------------------------"
    echo "1) 00 - Setup & 01 - Terminal  (Shell configs, Homebrew tweaks, etc.)"
    echo "2) 02 - Development            (Core dev tools, languages, DBs)"
    echo "3) 03 - Apps                   (GUI Applications)"
    echo "4) 04 - AI                     (LLMs, AI Assistants, Configs)"
    echo "a) All of the above"
    echo "q) Quit / Skip"
    echo "------------------------------------------------------------------"
    
    read -p "Choice [1-4, a, q]: " choice
    choice="${choice:-q}"
    
    case "$choice" in
        1|a)
            print_info "Running Setup & Terminal configuration..."
            bash "$SCRIPT_DIR/setup_config.sh"
            [[ "$choice" != "a" ]] && return
        ;;
    esac
    
    if [[ "$choice" == "a" || "$choice" == "2" ]]; then
        print_info "Installing Core Development tools..."
        # This is a generalized list based on docs/02 - Development
        # In a real scenario, this could be a Brewfile
        brew install git git-delta ripgrep fd fzf jq tree
        print_success "Core dev tools installed."
    fi
    
    if [[ "$choice" == "a" || "$choice" == "3" ]]; then
        print_info "Installing Common GUI Apps..."
        # Based on docs/03 - Apps
        # Using brew install --cask for GUI apps
        # Example: brew install --cask iterm2 visual-studio-code obsidian
        print_warning "GUI app installation typically requires manual confirmation or a Brewfile."
        print_info "Please refer to 'docs/03 - Apps' for the full list of preferred GUI tools."
    fi
    
    if [[ "$choice" == "a" || "$choice" == "4" ]]; then
        print_info "Running AI Tool setup..."
        bash "$SCRIPT_DIR/setup_ai.sh"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure we are running from the scripts directory context
cd "$SCRIPT_DIR"

install_core_dependencies
run_selective_install

echo ""
print_success "Bootstrap process complete!"