#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Zsh - Default shell on macOS with Oh My Zsh for themes and plugins.

_install_zsh_core() {
    print_info "Installing Zsh and Oh My Zsh..."
    
    # Install Zsh via Homebrew
    brew install zsh
    
    # Install Oh My Zsh (non-interactive)
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        print_info "Oh My Zsh is already installed."
    fi
}

_install_zsh_plugins() {
    print_info "Installing Zsh plugins..."
    brew install zsh-autosuggestions zsh-syntax-highlighting
}

_install_zsh_theme() {
    print_info "Installing Powerlevel10k theme..."
    brew install powerlevel10k
    
    # Add theme to .zshrc if not present
    if ! grep -q "powerlevel10k.zsh-theme" "$HOME/.zshrc"; then
        echo "source \$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" >> "$HOME/.zshrc"
    fi
}

setup_zsh() {
    print_info "Setting up Zsh environment..."
    
    _install_zsh_core
    _install_zsh_plugins
    _install_zsh_theme
    
    print_info "--- Configuration ---"
    print_info "Recommended plugins for ~/.zshrc:"
    print_info "plugins=(git bundler macos rake ruby)"
    
    print_info "--- Usage ---"
    print_info "Restart your terminal to trigger the Powerlevel10k configuration wizard."
    
    print_status "Zsh setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zsh
fi