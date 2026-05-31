#!/opt/homebrew/bin/bash
# suggest-models.sh — Check OpenRouter for new models worth trying
#
# Fetches OpenRouter's model catalog and highlights models that:
#   - Match interest categories (coding, reasoning, vision, embedding, fast)
#   - Are not already configured in the current profile's models.sh
#   - Are relatively recent additions
#
# Usage:
#   suggest-models.sh <profile-name>
#   MACHINE_PROFILE=<name> suggest-models.sh
#
# Integration: called from deploy_configs() in setup_ai.sh as optional step.

set -euo pipefail

PROFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-${MACHINE_PROFILE:-}}"

if [[ -z "$PROFILE" ]]; then
    echo "Usage: $0 <profile-name>" >&2
    echo "Available:" >&2
    ls -d "$PROFILES_DIR"/*/ 2>/dev/null | while read -r d; do echo "  $(basename "$d")" >&2; done
    exit 1
fi

MODELS_SH="$PROFILES_DIR/$PROFILE/models.sh"
[[ -f "$MODELS_SH" ]] || { echo "Error: $MODELS_SH not found." >&2; exit 1; }

# ------------------------------------------------------------------
# Source profile to collect known model names
# ------------------------------------------------------------------
source "$MODELS_SH"

# Collect all known model names from this profile into a grep pattern
_known_models() {
    # Canonical local aliases from GGUF-first profile metadata
    for m in "${LOCAL_MODEL_NAMES[@]:-}"; do echo "$m"; done

    # Additional concurrent local GGUF variants
    if declare -p GGUF_VARIANTS &>/dev/null 2>&1; then
        for alias in "${LOCAL_MODEL_NAMES[@]:-}"; do
            variants="${GGUF_VARIANTS[$alias]:-}"
            [[ -z "$variants" ]] && continue
            IFS=',' read -ra _variant_specs <<< "$variants"
            for spec in "${_variant_specs[@]}"; do
                spec="$(echo "$spec" | sed 's/^ *//;s/ *$//')"
                [[ -z "$spec" ]] && continue
                IFS='|' read -r extra_quant _extra_filename _extra_source <<< "$spec"
                [[ -z "$extra_quant" ]] && continue
                safe_quant="$(echo "$extra_quant" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')"
                echo "${alias}-${safe_quant}"
            done
        done
    fi

    # Ollama cloud manifests
    for m in "${OLLAMA_CLOUD_MODELS[@]:-}"; do echo "${m%:cloud}"; done

    # OPENROUTER_MODELS entries
    for m in "${OPENROUTER_MODELS[@]:-}"; do echo "$m"; done
    # Scalar model vars
    for v in CLINE_MODEL ZOOCODE_MODEL KILOCODE_MODEL AIDER_MODEL AIDER_WEAK_MODEL \
             AIDER_EDITOR_MODEL ZED_MODEL CURSOR_MODEL; do
        echo "${!v:-}"
    done
    # Scalar cloud vars
    for v in CLINE_MODEL_CLOUD ZOOCODE_MODEL_CLOUD KILOCODE_MODEL_CLOUD CURSOR_MODEL_CLOUD; do
        echo "${!v:-}"
    done
    # Associative array values
    for arr in AIDER_MODELS OPENCODE_AGENTS CONTINUE_ROLES CLAUDE_CODE; do
        if declare -p "$arr" &>/dev/null 2>&1; then
            declare -n _ref="$arr"
            for val in "${_ref[@]}"; do echo "$val"; done
        fi
    done
}

# Build patterns for filtering
IFS=$'\n' KNOWN_MODELS=($(_known_models | sort -u)); IFS=$' \t\n'

# Extract base names (before colon) for matching
KNOWN_BASES=()
for m in "${KNOWN_MODELS[@]}"; do
    [[ -z "$m" ]] && continue
    base="${m%%:*}"
    KNOWN_BASES+=("$base")
done
IFS=$'\n' KNOWN_BASES=($(printf '%s\n' "${KNOWN_BASES[@]}" | sort -u)); IFS=$' \t\n'

# Build a grep pattern to exclude known models
_EXCLUDE=$(printf '%s\n' "${KNOWN_BASES[@]}" | while read -r m; do
    [[ -n "$m" ]] && echo -n "$m|"
done)
_EXCLUDE="${_EXCLUDE%|}"

# ------------------------------------------------------------------
# Fetch OpenRouter models
# ------------------------------------------------------------------
echo "  Fetching OpenRouter model catalog…" >&2
OR_DATA=$(curl -s --max-time 10 "https://openrouter.ai/api/v1/models" 2>/dev/null) || {
    echo "  ⚠ Failed to fetch OpenRouter API (timeout or network issue)" >&2
    exit 0
}

# ------------------------------------------------------------------
# Filter and display using Python with temp file
# Quoted heredoc avoids all bash quote-mangling issues.
# ------------------------------------------------------------------
PYFILE=$(mktemp) || { echo "  Failed to create temp file" >&2; exit 1; }
cat > "$PYFILE" <<'PYEOF'
import json, sys, re, os
from datetime import datetime, timezone

data = json.loads(sys.stdin.read())
models = data.get('data', data)

known_pattern = re.compile(os.environ.get('EXCLUDE_PATTERN', ''), re.IGNORECASE) if os.environ.get('EXCLUDE_PATTERN') else None

CATEGORIES = [
    ('Coding',       r'coding|coder|code|swe(-bench)?|agent(ic)?|developer|program'),
    ('Reasoning',    r'reason|think|deep.?think|r1\b'),
    ('Vision',       r'vision|multimodal|image|visual'),
    ('Fast / Cheap', r'flash|mini|small|nano|tiny|lite|fast'),
    ('Embeddings',   r'embed|retrieval|dense|semantic'),
    ('Instruct',     r'instruct'),
]

now = datetime.now(timezone.utc).timestamp()
max_age = 180 * 24 * 3600
results = []
seen_ids = set()

for m in models:
    mid = m.get('id', '')
    name = m.get('name', '')
    desc = m.get('description', '') or ''
    created = m.get('created', 0)
    ctx = m.get('context_length', 0)

    if mid.startswith('~'):
        continue

    short = mid.split('/')[-1] if '/' in mid else mid
    if known_pattern and (known_pattern.search(mid) or known_pattern.search(short)):
        continue

    if created and (now - created) > max_age:
        continue

    base_id = mid.replace(':free', '')
    if base_id in seen_ids:
        continue

    matched_cats = []
    text = f'{mid} {name} {desc}'.lower()
    for cat_name, pattern in CATEGORIES:
        if re.search(pattern, text, re.IGNORECASE):
            matched_cats.append(cat_name)
    if not matched_cats:
        continue

    snippet = (desc.strip()[:120] + '...') if desc and len(desc) > 120 else (desc.strip() if desc else '')
    snippet = snippet.replace('\n', ' ')

    if created:
        age_days = int((now - created) / 86400)
        age_label = 'new' if age_days < 7 else f'{age_days}d'
    else:
        age_label = ''

    has_free = ':free' in mid or f'{base_id}:free' in seen_ids

    results.append({
        'id': base_id,
        'cats': matched_cats,
        'snippet': snippet,
        'age': age_label,
        'ctx': ctx,
        'has_free': has_free,
    })
    seen_ids.add(base_id)

if not results:
    print('  No new models found -- your catalog is current.')
    sys.exit(0)

from collections import OrderedDict
groups = OrderedDict()
cat_priority = [c[0] for c in CATEGORIES]
for r in results:
    primary = r['cats'][0]
    for cp in cat_priority:
        if cp in r['cats']:
            primary = cp
            break
    groups.setdefault(primary, []).append(r)

count = len(results)
print(f'  {count} new/unconfigured model{"s" if count != 1 else ""} worth checking:\n')

for cat_name in cat_priority:
    items = groups.get(cat_name)
    if not items:
        continue
    print(f'  \033[1m{cat_name}\033[0m')
    for r in items[:3]:
        parts = []
        if r['age']:
            parts.append(r['age'])
        if r['ctx']:
            parts.append(f'{r["ctx"] // 1024}k')
        if r['has_free']:
            parts.append('free')
        tag = f' [{" ".join(parts)}]' if parts else ''
        print(f'    \033[36m{r["id"]}\033[0m{tag}')
        if r['snippet']:
            print(f'      {r["snippet"]}')
    if len(items) > 3:
        print(f'    ... and {len(items) - 3} more')
    print()

print('  Run `model-scout` for interactive selection and config updates.')
PYEOF

EXCLUDE_PATTERN="${_EXCLUDE}" python3 "$PYFILE" <<< "$OR_DATA" || true
rm -f "$PYFILE"

echo "  Done." >&2
