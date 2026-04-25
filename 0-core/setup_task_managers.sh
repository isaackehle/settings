#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Task Managers & Design - Project management and design tools.

_install_task_managers() {
    print_info "Installing task management and design tools..."
    brew install --cask clickup figma
}

verify_task_managers() {
    [[ -d "/Applications/ClickUp.app" ]] || [[ -d "/Applications/Figma.app" ]]
}

setup_task_managers() {
    print_info "Setting up task managers and design tools..."
    
    verify_task_managers || _install_task_managers || { print_error "Failed to install task management tools"; return 1; }
    
    print_status "Task managers and design tools setup complete. Start: Open the apps from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_task_managers
fi