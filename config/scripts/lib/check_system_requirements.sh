. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_system_requirements
fi
