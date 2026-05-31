#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILES_DIR="${ROOT_DIR}/ai/profiles"
TEMPLATE_BEGIN="# >>> SHARED GGUF-FIRST DEFINITIONS >>>"
TEMPLATE_END="# <<< SHARED GGUF-FIRST DEFINITIONS <<<"
SOURCE_PROFILE="${1:-${PROFILES_DIR}/macbook-m5-64gb/models.sh}"

extract_block() {
  awk -v begin="$TEMPLATE_BEGIN" -v end="$TEMPLATE_END" '
    $0 == begin { printing=1 }
    printing { print }
    $0 == end { printing=0 }
  ' "$1"
}

replace_block() {
  local file="$1"
  local block="$2"
  python3 - "$file" "$TEMPLATE_BEGIN" "$TEMPLATE_END" "$block" <<'PY2'
from pathlib import Path
import sys
path, begin, end, block = sys.argv[1:5]
text = Path(path).read_text()
start = text.find(begin)
finish = text.find(end)
if start == -1 or finish == -1:
    raise SystemExit(f"Missing sync markers in {path}")
finish += len(end)
Path(path).write_text(text[:start] + block + text[finish:])
PY2
}

BLOCK="$(extract_block "$SOURCE_PROFILE")"
if [[ -z "$BLOCK" ]]; then
  echo "No shared block found in $SOURCE_PROFILE" >&2
  exit 1
fi

while IFS= read -r -d '' file; do
  [[ "$file" == "$SOURCE_PROFILE" ]] && continue
  replace_block "$file" "$BLOCK"
  echo "Synced: ${file#$ROOT_DIR/}"
done < <(find "$PROFILES_DIR" -name models.sh -print0)
