#!/bin/bash
# Update all machine profiles to use ~/.models and running servers
# Usage: bash update-all-profiles.sh

PROFILES_DIR="$SETTINGS_BASE/ai/profiles"
[ -z "$SETTINGS_BASE" ] && SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SETTINGS_BASE/ai/profiles"

for profile in "$PROFILES_DIR"/*/; do
    [ -d "$profile" ] || continue
    name=$(basename "$profile")
    echo "=== Updating $name ==="
    
    # Update crush config
    if [ -f "$profile/crush/crush.json" ]; then
        echo "  - crush/crush.json"
    fi
    
    # Add more files as needed
done
