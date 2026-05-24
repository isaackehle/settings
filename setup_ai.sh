#!/opt/homebrew/bin/bash
# setup_ai.sh — Install and configure AI development tools

# Refuse to run when sourced — the script calls `exit` on completion and on
# errors, which would close the parent shell (terminal) instead of just
# stopping the script. Return cleanly so the parent shell survives.
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "setup_ai.sh must be executed, not sourced. Run it with: bash setup_ai.sh" >&2
  return 1 2>/dev/null || exit 1
fi

set -euo pipefail

# Ensure we are running in bash, not sh or zsh
if [ -z "$BASH_VERSION" ]; then
  echo "Error: This script must be run with bash."
  echo "Please run it as: bash $(basename "$0")"
  exit 1
fi

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SETTINGS_BASE"

. "${SETTINGS_BASE}/helpers.sh"
# Source AI tool setup scripts
. "${SETTINGS_BASE}/2-ai/aider.sh"
. "${SETTINGS_BASE}/2-ai/anythingllm.sh"
. "${SETTINGS_BASE}/2-ai/claude.sh"
. "${SETTINGS_BASE}/2-ai/cline.sh"
. "${SETTINGS_BASE}/2-ai/codex.sh"
. "${SETTINGS_BASE}/2-ai/continue.sh"
. "${SETTINGS_BASE}/2-ai/crush.sh"
. "${SETTINGS_BASE}/2-ai/cursor.sh"
. "${SETTINGS_BASE}/2-ai/exo.sh"
. "${SETTINGS_BASE}/2-ai/gemini.sh"
. "${SETTINGS_BASE}/2-ai/github-copilot.sh"
. "${SETTINGS_BASE}/2-ai/grok.sh"
. "${SETTINGS_BASE}/2-ai/groq.sh"
. "${SETTINGS_BASE}/2-ai/install-models.sh"
. "${SETTINGS_BASE}/2-ai/kilocode.sh"
. "${SETTINGS_BASE}/2-ai/lmstudio.sh"
. "${SETTINGS_BASE}/2-ai/ollama.sh"
. "${SETTINGS_BASE}/2-ai/olol.sh"
. "${SETTINGS_BASE}/2-ai/open-hands.sh"
. "${SETTINGS_BASE}/2-ai/open-interpreter.sh"
. "${SETTINGS_BASE}/2-ai/opencode.sh"
. "${SETTINGS_BASE}/2-ai/openwebui.sh"
. "${SETTINGS_BASE}/2-ai/openrouter.sh"
. "${SETTINGS_BASE}/2-ai/zoocode.sh"
. "${SETTINGS_BASE}/2-ai/sublime.sh"
. "${SETTINGS_BASE}/2-ai/tabby.sh"
. "${SETTINGS_BASE}/2-ai/vscode.sh"
. "${SETTINGS_BASE}/2-ai/windsurf.sh"
. "${SETTINGS_BASE}/2-ai/zed.sh"

# ============================================================================
# CONFIGURATION DEPLOYMENT
# ============================================================================

deploy_configs() {
  log_info "Deploying AI tool configurations..."

  # --- MCP config (~/.mcp.json) ---
  print_step "MCP Servers"
  read -p "Install Claude MCP servers? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local mcp_dest="$HOME/.mcp.json"
    local mcp_src
    mcp_src=$(find_source "mcp.json")
    [ -z "$mcp_src" ] && mcp_src="$SETTINGS_BASE/2-ai/claude-code/mcp.json"

    local do_install=true
    if [ -f "$mcp_dest" ]; then
      read -p "  ~/.mcp.json already exists. Overwrite? (y/N) " -n 1 -r
      echo
      [[ ! $REPLY =~ ^[Yy]$ ]] && do_install=false
    fi

    if [ "$do_install" = true ] && [ -f "$mcp_src" ]; then
      [ -L "$mcp_dest" ] && rm "$mcp_dest"
      cp "$mcp_src" "$mcp_dest"
      echo "  copied $mcp_src -> $mcp_dest"

      if grep -q "home-assistant" "$mcp_dest"; then
        echo ""
        echo "  Home Assistant server detected."
        read -p "    URL (enter = ${HOMEASSISTANT_URL:-keep placeholder}): " HA_URL
        HA_URL="${HA_URL:-$HOMEASSISTANT_URL}"
        [ -n "$HA_URL" ] && sed -i '' "s|YOUR_HOMEASSISTANT_URL|$HA_URL|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_URL."
        read -p "    Long-lived token (enter = keep placeholder): " HA_TOKEN
        HA_TOKEN="${HA_TOKEN:-$HOMEASSISTANT_TOKEN}"
        [ -n "$HA_TOKEN" ] && sed -i '' "s|YOUR_LONG_LIVED_TOKEN|$HA_TOKEN|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_TOKEN."
      fi
      chmod 600 "$mcp_dest"
    else
      [ "$do_install" = false ] && echo "  Skipped."
      [ ! -f "$mcp_src" ] && echo "  (skip) source not found: $mcp_src"
    fi
  fi

  # --- AI tool configs ---
  print_step "Copying AI tool configs"

  # Resolve per-profile config directory and source models.sh
  local _profile _profdir
  _profile="${MACHINE_PROFILE}"
  _profdir="${SETTINGS_BASE}/2-ai/profiles/${_profile}"
  [ -n "$_profile" ] && log_info "Profile: ${_profile}" ||
    log_warning "Profile not detected — per-profile configs will be skipped"

  # Source the single source of truth for all model assignments
  local _models_sh="${_profdir}/models.sh"
  if [ -f "$_models_sh" ]; then
    source "$_models_sh"
    log_info "  Loaded model config from $_models_sh"
  else
    log_warning "  models.sh not found at $_models_sh — configs may use stale values"
  fi

  # Build known model list for validation
  local _known_models=()
  _collect_models() {
    local _var_name="$1"
    local _val
    if [[ "$(declare -p "$_var_name" 2>/dev/null)" =~ "declare -A" ]]; then
      # Associative array — iterate values
      eval "for _val in \"\${$_var_name[@]}\"; do _known_models+=(\"\$_val\"); done"
    else
      # Scalar
      local _tmp="${!_var_name:-}"
      if [ -n "$_tmp" ]; then
        _known_models+=("$_tmp")
      fi
    fi
  }
  _collect_models "CLINE_MODEL"
  _collect_models "CLINE_MODEL_CLOUD"
  _collect_models "ZOOCODE_MODEL"
  _collect_models "ZOOCODE_MODEL_CLOUD"
  _collect_models "KILOCODE_MODEL"
  _collect_models "KILOCODE_MODEL_CLOUD"
  _collect_models "AIDER_MODEL"
  _collect_models "AIDER_WEAK_MODEL"
  _collect_models "AIDER_EDITOR_MODEL"
  _collect_models "ZED_MODEL"
  _collect_models "CURSOR_MODEL"
  _collect_models "CURSOR_MODEL_CLOUD"
  [ -n "${OPENCODE_AGENTS[*]:-}" ] && _collect_models "OPENCODE_AGENTS"
  [ -n "${CONTINUE_ROLES[*]:-}" ]   && _collect_models "CONTINUE_ROLES"
  [ -n "${CLAUDE_CODE[*]:-}" ]       && _collect_models "CLAUDE_CODE"
  log_info "  Model list built (${#_known_models[@]} entries)"

  # Validate: check that model references in a config file match known models
  _validate_config_models() {
    local _file="$1"
    local _label="$2"
    [ ! -f "$_file" ] && return 0
    local _found _issues=0
    # Extract model-like strings from config (values following "model", colon-separated)
    for _found in $(rg -o '[a-zA-Z][a-zA-Z0-9._-]*:[a-zA-Z][a-zA-Z0-9._-]*' "$_file" 2>/dev/null); do
      # Strip context suffix (e.g. :q4-64k → :q4)
      local _base="${_found%%-*}"
      local _matched=false
      for _known in "${_known_models[@]}"; do
        if [[ "$_found" == "$_known" || "$_found" == "${_known}"* ]]; then
          _matched=true
          break
        fi
      done
      if [ "$_matched" = false ]; then
        log_warning "  $_label: unstaged model '$_found' not in models.sh"
        _issues=$((_issues + 1))
      fi
    done
    return 0
  }

  print_step "Deploying per-tool configs"

  [ -L "$HOME/.groq" ] && rm "$HOME/.groq"
  mkdir -p "$HOME/.groq"
  copy_file "${_profdir}/groq/local-settings.json" "$HOME/.groq/local-settings.json"

  [ -L "$HOME/.gemini" ] && rm "$HOME/.gemini"
  mkdir -p "$HOME/.gemini"
  copy_file "${_profdir}/gemini/settings.json" "$HOME/.gemini/settings.json"
  _validate_config_models "$HOME/.gemini/settings.json" "Gemini"
  copy_file "${_profdir}/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
  copy_file "${SETTINGS_BASE}/2-ai/gemini-projects.json" "$HOME/.gemini/projects.json"

  [ -L "$HOME/.continue" ] && rm "$HOME/.continue"
  mkdir -p "$HOME/.continue"
  copy_file "${_profdir}/continue/config.yaml" "$HOME/.continue/config.yaml"
  _validate_config_models "$HOME/.continue/config.yaml" "Continue"

  [ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
  mkdir -p "$HOME/.config/opencode"
  copy_file "${_profdir}/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
  _validate_config_models "$HOME/.config/opencode/opencode.jsonc" "OpenCode"

  [ -L "$HOME/.ollama" ] && rm "$HOME/.ollama"
  mkdir -p "$HOME/.ollama"
  copy_file "${_profdir}/ollama/config.json" "$HOME/.ollama/config.json"
  _validate_config_models "$HOME/.ollama/config.json" "Ollama"

  mkdir -p "$HOME/.config/crush"
  copy_file "${_profdir}/crush/crush.json" "$HOME/.config/crush/crush.json"
  _validate_config_models "$HOME/.config/crush/crush.json" "Crush"

  mkdir -p "$HOME/.config/grok"
  copy_file "${_profdir}/grok/grok.json" "$HOME/.config/grok/grok.json"
  _validate_config_models "$HOME/.config/grok/grok.json" "Grok"

  # --- Claude Code CLI (~/.claude/settings.json) ---
  mkdir -p "$HOME/.claude"
  copy_file "${_profdir}/claude/settings.json" "$HOME/.claude/settings.json"
  _validate_config_models "$HOME/.claude/settings.json" "Claude Code"

  # --- Helper: merge VS Code extension settings into settings.json ---
  _merge_vscode_extension() {
    local prefix="$1"    # e.g. "cline" or "zoo-code"
    local src_file="$2"  # path to settings.jsonc snippet
    local vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"

    if [ ! -f "$src_file" ]; then
      return 0
    fi

    # Skip if source hasn't changed since last merge (stamp file)
    local _stamp_dir="$HOME/.ollama/vscode-merge-stamps"
    mkdir -p "$_stamp_dir"
    local _src_mtime
    _src_mtime=$(stat -f "%m" "$src_file" 2>/dev/null || echo "0")
    if [ -f "$_stamp_dir/$prefix" ]; then
      local _stored_mtime
      _stored_mtime=$(cat "$_stamp_dir/$prefix")
      if [ "$_src_mtime" = "$_stored_mtime" ]; then
        return 0
      fi
    fi

    # Strip comments/empty lines and extract inner block
    local ext_block
    ext_block=$(sed '/^\s*\/\//d; /^\s*$/d' "$src_file" | sed '1d;$d' | sed 's/^  //')

    # Remove existing settings with this prefix from VS Code settings
    if [ -f "$vscode_settings" ]; then
      local tmp_settings
      tmp_settings=$(awk -v pfx="$prefix" 'index($0, "\"" pfx ".") {skip=1} skip && /^[[:space:]]*}[[:space:]]*,?$/ {skip=0; next} !skip {print} {skip=0}' "$vscode_settings")
      echo "$tmp_settings" > "$vscode_settings"
    fi

    # Append extension block
    if [ -f "$vscode_settings" ] && [ -s "$vscode_settings" ]; then
      sed -i '' '$ d' "$vscode_settings"
      echo "," >> "$vscode_settings"
      echo "$ext_block" >> "$vscode_settings"
      echo "}" >> "$vscode_settings"
    else
      sed 's/\/\/.*$//' "$src_file" | sed '/^\s*$/d' > "$vscode_settings"
    fi
    echo "$_src_mtime" > "$_stamp_dir/$prefix"
    log_status "${prefix} settings merged into $vscode_settings"
  }

  # --- One-time VS Code settings dedup ---
  local _vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
  local _dedup_stamp="$HOME/.ollama/vscode-merge-stamps/.dedup-done"
  if [ -f "$_vscode_settings" ] && [ ! -f "$_dedup_stamp" ]; then
    local _py_script
    _py_script=$(mktemp)
    cat > "$_py_script" << PYEOF
import json, sys
try:
    with open("$_vscode_settings") as f:
        data = json.load(f)
    with open("$_vscode_settings", "w") as f:
        json.dump(data, f, indent=2)
    sys.exit(0)
except Exception:
    sys.exit(1)
PYEOF
    if python3 "$_py_script" 2>/dev/null; then
      mkdir -p "$(dirname "$_dedup_stamp")"
      touch "$_dedup_stamp"
      log_info "  Deduplicated VS Code settings.json"
    fi
    rm -f "$_py_script"
  fi

  # --- Cline ---
  _merge_vscode_extension "cline" "${_profdir}/cline/settings.jsonc"

  # --- Zoo Code VS Code extension ---
  _merge_vscode_extension "zoo-code" "${_profdir}/zoocode/settings.jsonc"

  mkdir -p "$HOME/.config/zed"
  copy_file "${_profdir}/zed/settings.json" "$HOME/.config/zed/settings.json"
  _validate_config_models "$HOME/.config/zed/settings.json" "Zed"

  mkdir -p "$HOME/.aider"
  copy_file "${_profdir}/aider/aider.conf.yml" "$HOME/.aider.conf.yml"
  _validate_config_models "$HOME/.aider.conf.yml" "Aider"

  mkdir -p "$HOME/.kilo"
  copy_file "${_profdir}/kilocode/kilo.jsonc" "$HOME/.kilo/kilo.jsonc"
  _validate_config_models "$HOME/.kilo/kilo.jsonc" "Kilo Code"

  # --- Cursor (separate IDE from VS Code) ---
  local cursor_settings="$HOME/Library/Application Support/Cursor/User/settings.json"
  local cursor_src="${_profdir}/cursor/settings.jsonc"
  if [ -f "$cursor_src" ]; then
    mkdir -p "$(dirname "$cursor_settings")"
    # Strip comments and merge into Cursor's settings.json
    local cursor_block
    cursor_block=$(sed '/^\s*\/\//d; /^\s*$/d' "$cursor_src" | sed '1d;$d' | sed 's/^  //')
    if [ -f "$cursor_settings" ] && [ -s "$cursor_settings" ]; then
      sed -i '' '$ d' "$cursor_settings"
      echo "," >> "$cursor_settings"
      echo "$cursor_block" >> "$cursor_settings"
      echo "}" >> "$cursor_settings"
    else
      sed 's/\/\/.*$//' "$cursor_src" | sed '/^\s*$/d' > "$cursor_settings"
    fi
    log_status "Cursor settings merged into $cursor_settings"
  fi

  # --- IDE selection ---
  print_step "IDE Selection"
  echo "  1) VS Code   (recommended — broader extension ecosystem)"
  echo "  2) Windsurf  (VS Code fork with built-in Codeium AI)"
  echo "  3) Both      (deploy configs for both, install neither)"
  echo ""
  read -p "Which IDE? [1/2/3] (Enter = 1): " IDE_CHOICE
  IDE_CHOICE="${IDE_CHOICE:-1}"

  if [[ "$IDE_CHOICE" == "2" || "$IDE_CHOICE" == "3" ]]; then
    [ -L "$HOME/.codeium" ] && rm "$HOME/.codeium"
    mkdir -p "$HOME/.codeium"
    copy_file "${_profdir}/windsurf/codeium-config.json" "$HOME/.codeium/config.json"

    [ -L "$HOME/.windsurf" ] && rm "$HOME/.windsurf"
    mkdir -p "$HOME/.windsurf"
    copy_file "${_profdir}/windsurf/argv.json" "$HOME/.windsurf/argv.json"
    log_status "Windsurf config deployed."
  fi

  if [[ "$IDE_CHOICE" == "1" || "$IDE_CHOICE" == "3" ]]; then
    log_info "VS Code config: extensions are installed via 'setup vscode' in the menu."
    log_info "Continue config is shared with both IDEs at ~/.continue/config.yaml."
  fi

  # --- Shell profile.d ---
  print_step "Copying profile.d files"
  local profiled_src="${_profdir}/profile.d"
  [ ! -d "$profiled_src" ] && profiled_src="$SETTINGS_BASE/config/profile.d"

  # Capture existing keep-alive value BEFORE profile.d copy overwrites it
  local _current_keep="5m"
  if [ -f "$HOME/.profile.d/_ollama" ]; then
    local _read_keep
    _read_keep=$(grep -o 'OLLAMA_KEEP_ALIVE="[^"]*"' "$HOME/.profile.d/_ollama" | cut -d'"' -f2)
    [ -n "$_read_keep" ] && _current_keep="$_read_keep"
  fi

  if [ -d "$profiled_src" ]; then
    mkdir -p "$HOME/.profile.d"
    cp -R "$profiled_src/." "$HOME/.profile.d/"
    log_info "  copied profile.d/ -> $HOME/.profile.d/"

    # --- Ollama Keep Alive Selection ---
    if [ -f "$HOME/.profile.d/_ollama" ]; then
      echo ""
      echo "  Ollama Memory Management"
      echo "  ------------------------"
      read -p "  Keep models warm in RAM? (0 = immediate unload, 5m = keep for 5 mins) [$_current_keep]: " KEEP_ALIVE
      KEEP_ALIVE="${KEEP_ALIVE:-$_current_keep}"
      sed -i '' "s/export OLLAMA_KEEP_ALIVE=\".*\"/export OLLAMA_KEEP_ALIVE=\"$KEEP_ALIVE\"/" "$HOME/.profile.d/_ollama"
      echo "    Set OLLAMA_KEEP_ALIVE to $KEEP_ALIVE"
    fi
  fi

  log_status "AI tool configs deployed."

  # --- Generate required models list for pruner ---
  mkdir -p "$HOME/.ollama"
  local _reqfile="$HOME/.ollama/required-models.txt"
  {
    echo "# Required models for $(basename "${_profdir}")"
    echo "# Generated by setup_ai.sh deploy_configs — edit to add/remove models"
    echo ""
    echo "# ============================================================"
    echo "# LOCAL MODELS (pulled by ollama pull, stored on disk)"
    echo "# Add any models here that Ollama should keep."
    echo "# ============================================================"

    local _local=() _cloud=()

    # OLLAMA_MODELS
    for _m in "${OLLAMA_MODELS[@]}"; do
      if [[ "$_m" == *":cloud" ]]; then
        _cloud+=("${_m%:cloud}")
      else
        _local+=("$_m")
      fi
    done

    # Context variants from MODEL_CONTEXTS
    if declare -p MODEL_CONTEXTS &>/dev/null 2>&1; then
      for _base in "${!MODEL_CONTEXTS[@]}"; do
        for _ctx in ${MODEL_CONTEXTS[$_base]}; do
          _local+=("${_base}-${_ctx}")
        done
      done
    fi

    # Tool assignment arrays (local models only — skip :cloud values)
    for _arr in OPENCODE_AGENTS CONTINUE_ROLES CLAUDE_CODE; do
      if declare -p "$_arr" &>/dev/null 2>&1; then
        local -n _ref="$_arr"
        for _k in "${!_ref[@]}"; do
          local _val="${_ref[$_k]}"
          if [[ "$_val" == *":cloud" ]]; then
            _cloud+=("${_val%:cloud}")
          else
            _local+=("$_val")
          fi
        done
      fi
    done

    # Scalar model vars
    for _v in CLINE_MODEL CLINE_MODEL_CLOUD \
              ZOOCODE_MODEL ZOOCODE_MODEL_CLOUD \
              KILOCODE_MODEL KILOCODE_MODEL_CLOUD \
              AIDER_MODEL AIDER_WEAK_MODEL AIDER_EDITOR_MODEL \
              ZED_MODEL CURSOR_MODEL CURSOR_MODEL_CLOUD; do
      local _val="${!_v:-}"
      [ -n "$_val" ] && _cloud+=("$_val")
    done

    # Print local models
    printf "%s\n" "${_local[@]}" | sort -u
    echo ""
    echo "# ============================================================"
    echo "# CLOUD MODELS (via OpenRouter — not stored in Ollama)"
    echo "# These are listed for reference only. Remove any from Ollama."
    echo "# ============================================================"
    printf "# %s\n" $(printf "%s\n" "${_cloud[@]}" | sort -u)
  } > "$_reqfile"
  log_info "  Wrote required models list to $_reqfile"

  # --- Generate model map ---
  local _mapper="${SETTINGS_BASE}/2-ai/profiles/generate-model-map.sh"
  if [ -f "$_mapper" ]; then
    bash "$_mapper" "${_profile}" 2>/dev/null && log_info "  Updated model-map.md" || true
  fi

  # --- Offer to prune old Ollama models ---
  echo ""
  echo "  Ollama Model Management"
  echo "  -----------------------"
  echo "  Edit ~/.ollama/required-models.txt to add models you want to keep."
  read -p "  Prune obsolete Ollama models? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local _pruner="${SETTINGS_BASE}/2-ai/profiles/prune_models.sh"
    if [ -f "$_pruner" ]; then
      bash "$_pruner" "${_profile}"
    else
      echo "  (skip) pruner script not found at $_pruner"
    fi
  fi
}

# Function to backup existing configurations
backup_existing_configs() {
  log_status "Backing up existing AI tool configurations..."
  backup_continue
  backup_opencode
  backup_crush
  backup_claude
  backup_grok
  backup_olol

  backup_kilocode
  log_status "All existing configurations backed up successfully"
}

# Function to restore configurations from backup
restore_configs() {
  log_status "Restoring AI tool configurations from backup..."
  restore_continue
  restore_opencode
  restore_crush
  restore_claude
  restore_grok
  restore_olol

  restore_kilocode
  log_status "All configurations restored successfully"
}

verify_installations() {
  log_info "Verifying tool installations..."
  local verification_results=""
  local all_passed=true
  for check in verify_ollama verify_openrouter verify_openwebui verify_claude_code verify_cline_cli verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_groq verify_github_copilot verify_aider verify_cursor verify_kilocode verify_zed verify_tabby; do
    local label="${check#verify_}"
    if $check; then
      verification_results="$verification_results ✓ $label - OK\n"
    else
      verification_results="$verification_results ✗ $label - FAILED\n"
      all_passed=false
    fi
  done
  echo -e "$verification_results"
  if [ "$all_passed" = true ]; then
    log_status "All AI development tools are properly installed and functional"
  else
    log_warning "Some tools may require manual configuration or additional setup"
    return 1
  fi
}

# ============================================================================
# GROUP DEFINITIONS
# ============================================================================

declare -A TOOL_GROUPS=(
  ["infrastructure"]="ollama openrouter openwebui"
  ["terminal-agents"]="claude cline opencode crush aider codex gemini grok"
  ["vscode-extensions"]="continue copilot kilocode zoocode"
  ["ides"]="windsurf cursor zed"
  ["self-hosted"]="anythingllm tabby open-hands"
  ["all"]="infrastructure terminal-agents vscode-extensions ides self-hosted"
)

# Map group names to setup functions
declare -A GROUP_SETUP_FUNCS=(
  ["ollama"]="setup_ollama"
  ["openrouter"]="setup_openrouter"
  ["openwebui"]="setup_openwebui"
  ["claude"]="setup_claude"
  ["cline"]="setup_cline"
  ["opencode"]="setup_opencode"
  ["crush"]="setup_crush"
  ["aider"]="setup_aider"
  ["codex"]="setup_codex"
  ["gemini"]="setup_gemini"
  ["grok"]="setup_grok"
  ["continue"]="setup_continue"
  ["copilot"]="setup_github_copilot"
  ["kilocode"]="setup_kilocode"
  ["windsurf"]="setup_windsurf"
  ["cursor"]="setup_cursor"
  ["zed"]="setup_zed"
  ["anythingllm"]="setup_anythingllm"
  ["tabby"]="setup_tabby"
  ["open-hands"]="setup_openhands"
  ["zoocode"]="setup_zoocode"
)

# Verify functions map
declare -A GROUP_VERIFY_FUNCS=(
  ["ollama"]="verify_ollama"
  ["openrouter"]="verify_openrouter"
  ["openwebui"]="verify_openwebui"
  ["claude"]="verify_claude_code"
  ["cline"]="verify_cline_cli"
  ["opencode"]="verify_opencode"
  ["crush"]="verify_crush"
  ["aider"]="verify_aider"
  ["codex"]="verify_codex"
  ["gemini"]="verify_gemini"
  ["grok"]="verify_grok"
  ["continue"]="verify_continue"
  ["copilot"]="verify_github_copilot"
  ["kilocode"]="verify_kilocode"
  ["windsurf"]="verify_windsurf"
  ["cursor"]="verify_cursor"
  ["zed"]="verify_zed"
  ["anythingllm"]="verify_anythingllm"
  ["tabby"]="verify_tabby"
  ["open-hands"]="verify_openhands"
  ["zoocode"]="verify_zoocode"
)

# Display names for groups/tools
declare -A DISPLAY_NAMES=(
  ["infrastructure"]="Infrastructure (Ollama + OpenRouter + OpenWebUI)"
  ["terminal-agents"]="Terminal Agents (Claude, OpenCode, Crush, etc.)"
  ["vscode-extensions"]="VS Code Extensions (Cline, Continue, Copilot, etc.)"
  ["ides"]="IDEs (Windsurf, Cursor, Zed)"
  ["self-hosted"]="Self-Hosted (AnythingLLM, Tabby, OpenHands)"
  ["all"]="All Tools"
  ["ollama"]="Ollama"
  ["openrouter"]="OpenRouter"
  ["openwebui"]="OpenWebUI"
  ["claude"]="Claude Code"
  ["cline"]="Cline"
  ["opencode"]="OpenCode"
  ["crush"]="Crush"
  ["aider"]="Aider"
  ["codex"]="Codex"
  ["gemini"]="Gemini CLI"
  ["grok"]="Grok CLI"
  ["continue"]="Continue"
  ["copilot"]="GitHub Copilot"
  ["kilocode"]="Kilo Code"
  ["windsurf"]="Windsurf"
  ["cursor"]="Cursor"
  ["zed"]="Zed"
  ["anythingllm"]="AnythingLLM"
  ["tabby"]="Tabby"
  ["open-hands"]="OpenHands"
  ["zoocode"]="Zoo Code"
)

# ============================================================================
# INFRASTRUCTURE RECOMMENDATIONS
# ============================================================================

# All profiles get the same infrastructure stack — Ollama + OpenRouter + OpenWebUI.
# The only difference between profiles is model selection (models.sh).
get_recommended_infrastructure() {
  echo "ollama openrouter openwebui"
}

# Get profile name for display
get_profile_description() {
  local profile="${MACHINE_PROFILE:-unknown}"
  local name
  name=$(_profile_name "$profile")
  echo "${name}"
}

# Check which infrastructure components are currently installed/running
check_current_infrastructure() {
  local current=""
  verify_ollama 2>/dev/null && current="$current ollama"
  verify_openrouter 2>/dev/null && current="$current openrouter"
  verify_openwebui 2>/dev/null && current="$current openwebui"
  echo "${current# }"
}

# Uninstall an infrastructure component
uninstall_infrastructure_component() {
  local component="$1"
  local removed=false

  case "$component" in
    ollama)
      print_step "Uninstalling Ollama"
      if brew list ollama &>/dev/null; then
        read -p "  Uninstall Ollama? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          brew uninstall ollama
          removed=true
          log_status "Ollama uninstalled"
        fi
      else
        log_status "Ollama not installed via brew"
      fi
      ;;
    openwebui)
      print_step "Stopping OpenWebUI"
      if docker ps -a | grep -q open-webui; then
        read -p "  Stop and remove OpenWebUI container? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          docker stop open-webui 2>/dev/null || true
          docker rm open-webui 2>/dev/null || true
          removed=true
          log_status "OpenWebUI stopped and removed"
        fi
      else
        log_status "OpenWebUI container not found"
      fi
      ;;
    openrouter)
      # OpenRouter is just config, no real uninstall needed
      log_status "OpenRouter config can be removed manually if desired"
      ;;
  esac
  echo "$removed"
}

# Handle infrastructure changes - uninstall components that won't be used
handle_infrastructure_change() {
  local current="$1"
  local desired="$2"

  # Parse current and desired into arrays
  local current_arr=($current)
  local desired_arr=($desired)

  # Find components to remove
  for comp in "${current_arr[@]}"; do
    local found=false
    for want in "${desired_arr[@]}"; do
      if [[ "$comp" == "$want" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      uninstall_infrastructure_component "$comp"
    fi
  done
}

# Interactive infrastructure selection menu
select_infrastructure() {
  local recommended
  recommended=$(get_recommended_infrastructure)
  local current
  current=$(check_current_infrastructure)
  local profile_desc
  profile_desc=$(get_profile_description)

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  INFRASTRUCTURE SETUP                                         ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "  Profile: $profile_desc"
  echo "  Recommended: $recommended"
  echo "  Current:    ${current:-none}"
  echo ""
  echo "  Choose infrastructure stack:"
  echo ""
  echo "  1) Minimal         - Ollama only"
  echo "  2) Cloud Fallback  - Ollama + OpenRouter"
  echo "  3) Full Stack      - Ollama + OpenRouter + OpenWebUI"
  echo "  4) Custom          - Choose individual components"
  echo ""
  echo "  Recommendation for your profile: $(echo $recommended | tr ' ' '+')"
  echo ""

  printf "Select option [3]: "
  read -r choice
  choice="${choice:-3}"

  local desired=""
  case "$choice" in
    1) desired="ollama" ;;
    2) desired="ollama openrouter" ;;
    3) desired="ollama openrouter openwebui" ;;
    4)
      echo ""
      echo "Select components (space-separated, enter to confirm):"
      echo "  ollama      - Local LLM server"

      echo "  openrouter - Cloud model fallback (requires API key)"
      echo "  openwebui  - Web UI (Docker)"
      echo ""
      printf "Components [ollama openrouter openwebui]: "
      read -r desired
      desired="${desired:-ollama openrouter openwebui}"
      ;;
    *)
      log_error "Invalid option"
      return 1
      ;;
  esac

  echo ""
  echo "  Selected: $desired"

  # Handle uninstalls if changing infrastructure
  if [[ -n "$current" && "$current" != "$desired" ]]; then
    echo ""
    read -p "  Change infrastructure? This may uninstall unused components. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_info "Cancelled."
      return 1
    fi
    handle_infrastructure_change "$current" "$desired"
  fi

  # Install the selected components
  echo ""
  log_info "Installing infrastructure: $desired"

  for comp in $desired; do
    case "$comp" in
      ollama)     setup_ollama ;;

      openrouter) setup_openrouter ;;
      openwebui)  setup_openwebui ;;
    esac
  done

  log_status "Infrastructure setup complete!"
}

install_tool() {
  local tool="$1"
  local setup_func="${GROUP_SETUP_FUNCS[$tool]}"
  local verify_func="${GROUP_VERIFY_FUNCS[$tool]}"
  local display_name="${DISPLAY_NAMES[$tool]:-$tool}"

  if [ -n "$verify_func" ] && [ -n "$setup_func" ]; then
    print_step "$display_name"
    if $verify_func 2>/dev/null; then
      log_status "  $display_name already installed"
    else
      $setup_func || log_error "Failed to install $display_name"
    fi
  else
    log_warning "  $display_name: setup function not defined"
  fi
}

install_group() {
  local group="$1"
  local tools="${TOOL_GROUPS[$group]}"

  if [ -z "$tools" ]; then
    log_error "Unknown group: $group"
    return 1
  fi

  log_info ""
  log_info "=== Installing group: ${DISPLAY_NAMES[$group]:-$group} ==="

  for tool in $tools; do
    install_tool "$tool"
  done
}

install_groups() {
  local groups="$1"

  # Split by comma
  IFS=',' read -ra GROUP_ARRAY <<< "$groups"

  for group in "${GROUP_ARRAY[@]}"; do
    install_group "$group"
  done
}

install_tools() {
  # Legacy: install all tools
  install_group "infrastructure"
  install_group "terminal-agents"
  install_group "vscode-extensions"
  install_group "ides"
  install_group "self-hosted"
}

# Dispatch a single action+tool pair
_run_one() {
  local action="$1" tool="$2"
  case "$action:$tool" in
  setup:aider) setup_aider ;;
  setup:claude) setup_claude ;;
  setup:cline) setup_cline ;;
  setup:codex) setup_codex ;;
  setup:continue) setup_continue ;;
  setup:crush) setup_crush ;;
  setup:cursor) setup_cursor ;;
  setup:exo) setup_exo ;;
  teardown:exo) teardown_exo ;;
  setup:gemini) setup_gemini ;;
  setup:grok) setup_grok ;;
  setup:groq) setup_groq ;;
  setup:kilocode) setup_kilocode ;;
  backup:kilocode) backup_kilocode ;;
  restore:kilocode) restore_kilocode ;;
  setup:models) install_coding_assistants ;;
  setup:ollama) setup_ollama ;;
  setup:olol) setup_olol ;;
  setup:anythingllm) setup_anythingllm ;;
  setup:lmstudio) setup_lmstudio ;;

  setup:open-hands) setup_openhands ;;
  setup:openrouter) setup_openrouter ;;
  setup:opencode) setup_opencode ;;

  setup:tabby) setup_tabby ;;
  setup:copilot) setup_github_copilot ;;
  setup:sublime) setup_sublime ;;
  setup:vscode) setup_vscode ;;
  setup:windsurf) setup_windsurf ;;
  setup:zed) setup_zed ;;
  restore:claude) restore_claude ;;
  restore:continue) restore_continue ;;
  restore:crush) restore_crush ;;
  restore:grok) restore_grok ;;
  restore:groq) restore_groq ;;

  restore:olol) restore_olol ;;
  restore:opencode) restore_opencode ;;
  restore:*) log_info "No restore available for $tool — skipping" ;;
  backup:claude) backup_claude ;;
  backup:continue) backup_continue ;;
  backup:crush) backup_crush ;;
  backup:grok) backup_grok ;;
  backup:groq) backup_groq ;;

  backup:olol) backup_olol ;;
  backup:opencode) backup_opencode ;;
  backup:*) log_info "No backup available for $tool — skipping" ;;
  esac
}

_run_for_tools() {
  local action="$1"
  shift
  for tool in "$@"; do
    _run_one "$action" "$tool"
  done
}

# Interactive tool picker and action selector
interactive_menu() {
  # Tool definitions: name|group|description
  local tools_info=(
    "ollama|servers|Install server + start via brew services"
    "models|models|Install / prune Ollama models (auto-detects hardware)"
    "lmstudio|servers|Install LM Studio (GUI app)"

    "exo|servers|Install exo distributed inference"
    "olol|servers|Install Ollama load balancer"
    "tabby|servers|Install Tabby autocomplete server"

    "openrouter|cloud provider|Install OpenRouter proxy + deploy config"
    "groq|cloud provider|Deploy Groq config + API key instructions"


    "claude|tools|Install CLI + deploy config"
    "cline|tools|Install VS Code extension + CLI"
    "codex|tools|Install Codex CLI"
    "crush|tools|Install + deploy crush config"
    "grok|tools|Install + deploy grok config"
    "gemini|tools|Install Gemini CLI"
    "opencode|tools|Install + deploy opencode config"
    "anythingllm|tools|Install + configure Ollama provider"
    "aider|tools|Install Aider coding agent + deploy config"
    "open-hands|tools|Install Open Hands (Docker) + deploy config"

     "cursor|editors|Install Cursor IDE + show Ollama config"

    "kilocode|editors|Install Kilo Code VS Code extension"
    "sublime|editors|Install Sublime Text"
    "zed|editors|Install Zed editor + deploy config"
    "vscode|editors|Install VS Code + Continue + Cline extensions"
    "windsurf|editors|Install Windsurf IDE + deploy argv.json"

    "continue|extensions|Deploy Continue.dev config"
    "copilot|extensions|Install gh-copilot extension + VS Code extensions"
  )

  local max_name=0 max_group=0
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r _n _g _d <<<"$entry"
    (( ${#_n} > max_name )) && max_name=${#_n}
    (( ${#_g} > max_group )) && max_group=${#_g}
  done

  local tools=() entries=()
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r name group desc <<<"$entry"
    tools+=("$name")
    entries+=("${name}"$'\t'"$(printf '[%-*s]  %-*s  %s' "$max_group" "$group" "$max_name" "$name" "$desc")")
  done

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is not installed. Run: brew install fzf"
    return 1
  fi

   local selected
   selected=$(printf "%s\n" "${entries[@]}" | \
     fzf --multi --header "Select tools (Tab/Space=toggle, Enter=confirm, q=quit)" \
         --layout=reverse -d $'\t' --with-nth=2 --bind 'space:toggle')

  local chosen=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    chosen+=("$(cut -f1 <<<"$line")")
  done <<< "$selected"

  if [ ${#chosen[@]} -eq 0 ]; then
    log_warning "No tools selected."
    return
  fi

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  Select action                                                 ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo "  1) setup   - backup existing + apply new config / install"
  echo "  2) restore - restore from latest backup"
  echo "  3) backup  - backup only"
  echo ""
  printf "Action [1]: "
  read -r act
  act="${act:-1}"

  case "$act" in
  1 | setup) _run_for_tools setup "${chosen[@]}" ;;
  2 | restore) _run_for_tools restore "${chosen[@]}" ;;
  3 | backup) _run_for_tools backup "${chosen[@]}" ;;
  *)
    log_error "Invalid action"
    return 1
    ;;
  esac
}

# Main execution function
main() {
  case "$1" in
  backup)
    backup_existing_configs
    ;;
  restore)
    restore_configs
    ;;
  aider)
    setup_aider
    ;;
  continue)
    setup_continue
    ;;
  cursor)
    setup_cursor
    ;;
  kilocode)
    setup_kilocode
    ;;
  open-hands)
    setup_openhands
    ;;
  opencode)
    setup_opencode
    ;;
  tabby)
    setup_tabby
    ;;
  zed)
    setup_zed
    ;;
  crush)
    setup_crush
    ;;
  claude)
    setup_claude
    ;;
  cline)
    setup_cline
    ;;
  setup)
    setup_continue
    setup_opencode
    setup_crush
    setup_claude
    setup_cline
    setup_github_copilot
    log_status "All tool configurations applied"
    ;;
  vscode)
    setup_vscode
    ;;
  windsurf)
    setup_windsurf
    ;;
  ollama)
    setup_ollama
    ;;
  grok)
    setup_grok
    ;;
  groq)
    setup_groq
    ;;
  openrouter)
    setup_openrouter
    ;;
  olol)
    setup_olol
    ;;
  exo)
    setup_exo
    ;;
  teardown-exo)
    teardown_exo
    ;;
  codex)
    setup_codex
    ;;
  gemini)
    setup_gemini
    ;;
  anythingllm)
    setup_anythingllm
    ;;
  lmstudio)
    setup_lmstudio
    ;;
  openwebui)
    setup_openwebui
    ;;
  copilot)
    setup_github_copilot
    ;;
  check)
    check_system_requirements
    ;;
  verify)
    verify_installations
    ;;
  install)
    install_tools
    ;;
  install:infrastructure)
    install_group "infrastructure"
    ;;
  install:terminal-agents)
    install_group "terminal-agents"
    ;;
  install:vscode-extensions)
    install_group "vscode-extensions"
    ;;
  install:ides)
    install_group "ides"
    ;;
  install:self-hosted)
    install_group "self-hosted"
    ;;
  install:all)
    install_group "all"
    ;;
  install:*)
    local groups="${1#install:}"
    install_groups "$groups"
    ;;
  models)
    install_coding_assistants
    ;;
  deploy)
    deploy_configs
    ;;
  infrastructure)
    select_infrastructure
    ;;
  "")
    interactive_menu
    ;;
  *)
    echo "Usage: $0 {backup|restore|deploy|vscode|windsurf|continue|opencode|crush|claude|cline|aider|cursor|kilocode|zed|tabby|open-hands|setup|ollama|grok|olol|exo|codex|gemini|anythingllm|lmstudio|copilot|check|verify|install|infrastructure|models}"
    echo "  (no args)   - Interactive tool picker"
    echo "  deploy      - Copy all AI tool configs to their home-directory locations"
    echo ""
    echo "=== INFRASTRUCTURE (recommended) ==="
    echo "  infrastructure - Interactive menu to select LLM stack (profile-based)"
    echo ""
    echo "    All profiles: Ollama + OpenRouter + OpenWebUI"
    echo "    (Model selection differs by RAM, not infrastructure)"
    echo ""
    echo "=== GROUPS (recommended) ==="
    echo "  install:infrastructure   - Ollama + OpenRouter + OpenWebUI"
    echo "  install:terminal-agents    - Claude Code, Cline, OpenCode, Crush, Aider, etc."
    echo "  install:vscode-extensions  - Continue, Copilot, Kilocode, ZooCode"
    echo "  install:ides               - Windsurf, Cursor, Zed"
    echo "  install:self-hosted        - AnythingLLM, Tabby, OpenHands"
    echo "  install:all                - Everything"
    echo "  install:infra,terminal    - Multiple groups (comma-separated)"
    echo ""
    echo "=== LEGACY (individual tools) ==="
    echo "  install     - Install all tools (legacy)"
    echo "  ollama      - Install + start Ollama server"

    echo "  openwebui   - Setup OpenWebUI (Docker)"
    echo "  claude      - Install Claude Code CLI"
    echo "  cline       - Install Cline VS Code extension"
    echo "  opencode    - Setup OpenCode"
    echo "  windsurf    - Install Windsurf IDE"
    echo "  cursor      - Install Cursor IDE"
    echo "  zed         - Install Zed editor"
    echo "  anythingllm - Install AnythingLLM"
    echo ""
    echo "=== OTHER ==="
    echo "  olol        - Setup Ollama load balancer"
    echo "  exo         - Setup distributed inference"
    echo "  models      - Install / prune Ollama models"
    echo "  verify      - Verify all installations"
    echo "  check       - Check system requirements"
    echo "  copilot     - Install gh-copilot extension + VS Code Copilot extensions"

    echo "  kilocode    - Install Kilo Code VS Code extension + show config"
    echo "  tabby       - Install Tabby autocomplete server"
    echo ""
    echo "=== COMMANDS ==="
    echo "  setup       - Setup all tool configs at once"
    echo "  deploy      - Copy all AI tool configs to home-directory locations"
    echo "  backup      - Backup all existing configurations"
    echo "  restore     - Restore all configurations from backup"
    echo "  check       - Check system requirements"
    echo "  verify      - Verify all tool installations"
    echo "  install     - Install all tools (check + install-if-missing + verify)"
    exit 1
    ;;
  esac

  echo ""
  echo "=== AI TOOL CONFIGURATION PROCESS COMPLETED ==="
  echo "Backup directory: ${BACKUP_DIR:-Not defined}"
}

# Run the script with provided argument only if it's being executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "${1:-}"
fi
