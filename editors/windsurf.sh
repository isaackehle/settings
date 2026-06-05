# ---------------------------------------------------------------------------
# Windsurf → Devin Desktop backward-compat shim
#
# Windsurf was rebranded to Devin Desktop effective June 2, 2026 after
# Cognition AI acquired Windsurf.  This file delegates to devin.sh so that
# existing scripts sourcing windsurf.sh continue to work without changes.
#
# New setups should source devin.sh directly and call setup_devin.
# ---------------------------------------------------------------------------

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi

DEVIN_SH="${SETTINGS_BASE}/editors/devin.sh"

if [ ! -f "$DEVIN_SH" ]; then
    # Fallback: define functions inline if devin.sh is missing
    . "${SETTINGS_BASE}/helpers.sh"
    verify_windsurf()  { log_warning "Devin Desktop / Windsurf config not found"; return 1; }
    setup_windsurf()   { log_warning "Devin Desktop / Windsurf not available"; return 1; }
    backup_windsurf()  { :; }
    restore_windsurf() { :; }
else
    . "$DEVIN_SH"
fi
