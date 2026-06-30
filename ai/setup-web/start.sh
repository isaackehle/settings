#!/bin/bash
# Setup AI — Web UI Launcher
# Opens the installer at http://localhost:5555

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure venv exists
if [ ! -d "$SCRIPT_DIR/.venv" ]; then
  echo "Creating virtual environment..."
  cd "$SCRIPT_DIR" && uv venv .venv && uv pip install flask
fi

echo "Starting Setup AI web UI..."
echo "Open http://localhost:5555"
echo ""

# Launch browser after 1 second
(sleep 1 && open http://localhost:5555) &

exec "$SCRIPT_DIR/.venv/bin/python3" "$SCRIPT_DIR/app.py"
