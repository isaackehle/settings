#!/bin/bash
# Grok CLI Setup Script

echo "Sourcing Grok environment variables..."
if [ -f "$HOME/.profile.d/grok_env" ]; then
    source "$HOME/.profile.d/grok_env"
    echo "Grok environment variables sourced from ~/.profile.d/grok_env"
elif [ -f "$HOME/.zshrc.d/grok_env" ]; then
    source "$HOME/.zshrc.d/grok_env"
    echo "Grok environment variables sourced from ~/.zshrc.d/grok_env"
else
    echo "Warning: Grok environment file not found in standard locations"
fi

echo ""
echo "To use Grok CLI:"
echo "1. Source this script: source grok_setup.sh"
echo "2. Use: grok --prompt \"Explain this codebase\""
echo ""
echo "This enables fully offline AI coding assistance when combined with Ollama, preserving privacy and reducing costs."
