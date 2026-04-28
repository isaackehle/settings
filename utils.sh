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

print_step() {
    echo ""
    echo -e "${BLUE}━━━ $1 ━━━${NC}"
    log_message "STEP: $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
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