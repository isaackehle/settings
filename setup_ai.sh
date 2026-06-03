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
. "${SETTINGS_BASE}/ai/agents/aichat.sh"
. "${SETTINGS_BASE}/ai/agents/aider.sh"
. "${SETTINGS_BASE}/ai/other/anythingllm.sh"
. "${SETTINGS_BASE}/ai/agents/claude.sh"
. "${SETTINGS_BASE}/editors/cline.sh"
. "${SETTINGS_BASE}/ai/agents/codex.sh"
. "${SETTINGS_BASE}/editors/continue.sh"
. "${SETTINGS_BASE}/ai/agents/crush.sh"
. "${SETTINGS_BASE}/editors/cursor.sh"
. "${SETTINGS_BASE}/ai/other/exo.sh"
. "${SETTINGS_BASE}/ai/agents/fabric.sh"
. "${SETTINGS_BASE}/ai/agents/gemini.sh"
. "${SETTINGS_BASE}/editors/github-copilot.sh"
. "${SETTINGS_BASE}/ai/agents/goose.sh"
. "${SETTINGS_BASE}/ai/agents/grok.sh"
. "${SETTINGS_BASE}/ai/cloud/groq.sh"
. "${SETTINGS_BASE}/ai/agents/hermes.sh"
. "${SETTINGS_BASE}/ai/runtimes/install-models.sh"
. "${SETTINGS_BASE}/ai/agents/ironclaw.sh"
. "${SETTINGS_BASE}/editors/kilocode.sh"
. "${SETTINGS_BASE}/ai/agents/llm.sh"
. "${SETTINGS_BASE}/ai/runtimes/lmstudio.sh"
. "${SETTINGS_BASE}/ai/runtimes/omlx.sh"
. "${SETTINGS_BASE}/ai/runtimes/ollama.sh"
. "${SETTINGS_BASE}/ai/other/olol.sh"
. "${SETTINGS_BASE}/ai/agents/open-hands.sh"
. "${SETTINGS_BASE}/ai/agents/open-interpreter.sh"
. "${SETTINGS_BASE}/ai/agents/opencode.sh"
. "${SETTINGS_BASE}/ai/other/openwebui.sh"
. "${SETTINGS_BASE}/ai/cloud/openrouter.sh"
. "${SETTINGS_BASE}/ai/agents/openclaw.sh"
. "${SETTINGS_BASE}/ai/agents/picoclaw.sh"
. "${SETTINGS_BASE}/ai/agents/plandex.sh"
. "${SETTINGS_BASE}/ai/agents/pi.sh"
. "${SETTINGS_BASE}/editors/pi-studio.sh"
. "${SETTINGS_BASE}/editors/sublime.sh"
. "${SETTINGS_BASE}/ai/agents/zeroclaw.sh"
. "${SETTINGS_BASE}/editors/zoocode.sh"
. "${SETTINGS_BASE}/ai/other/tabby.sh"
. "${SETTINGS_BASE}/editors/vscode.sh"
. "${SETTINGS_BASE}/editors/windsurf.sh"
. "${SETTINGS_BASE}/editors/zed.sh"

# ============================================================================
# CONFIGURATION DEPLOYMENT
# ============================================================================

deploy_mcp_servers() {
  print_step "MCP Servers"
  read -p "Install Claude MCP servers? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local mcp_dest="$HOME/.mcp.json"
    local mcp_src
    mcp_src=$(find_source "mcp.json")
    [ -z "$mcp_src" ] && mcp_src="$SETTINGS_BASE/ai/claude-code/mcp.json"

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
}

deploy_configs() {
  log_info "Deploying AI tool configurations..."
  print_step "Copying AI tool configs"

  # Resolve per-profile config directory and source models.sh
  local _profile _profdir
  _profile="${MACHINE_PROFILE}"
  _profdir="${SETTINGS_BASE}/ai/profiles/${_profile}"
  [ -n "$_profile" ] && log_info "Profile: ${_profile}" ||
    log_warning "Profile not detected — per-profile configs will be skipped"

  # Source the single source of truth for all model assignments
  # Promote declare -A to declare -gA so associative arrays survive
  # the function scope and are visible to install-models.sh functions.
  local _models_sh="${_profdir}/models.sh"
  if [ -f "$_models_sh" ]; then
    source <(sed 's/^declare -A /declare -gA /g' "$_models_sh")
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

  # Also trust the canonical runtime inventory maps. Provider catalogs often
  # list selectable local models that are not assigned to a specific tool role.
  [ -n "${LOCAL_MODEL_NAMES[*]:-}" ] && _collect_models "LOCAL_MODEL_NAMES"
  if declare -p OLLAMA_CONTEXT_WINDOWS &>/dev/null; then
    local _ctx_model
    for _ctx_model in "${!OLLAMA_CONTEXT_WINDOWS[@]}"; do
      _known_models+=("$_ctx_model")
    done
  fi
  if declare -p MODEL_REMOTES &>/dev/null; then
    local _remote_model
    for _remote_model in "${!MODEL_REMOTES[@]}"; do
      _known_models+=("$_remote_model")
    done
  fi
  [ -n "${OLLAMA_CLOUD_MODELS[*]:-}" ] && _collect_models "OLLAMA_CLOUD_MODELS"

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
  copy_file "${SETTINGS_BASE}/ai/agents/gemini-projects.json" "$HOME/.gemini/projects.json"

  [ -L "$HOME/.continue" ] && rm "$HOME/.continue"
  mkdir -p "$HOME/.continue"
  copy_file "${_profdir}/continue/config.yaml" "$HOME/.continue/config.yaml"
  _validate_config_models "$HOME/.continue/config.yaml" "Continue"

  [ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
  mkdir -p "$HOME/.config/opencode"
  copy_file "${_profdir}/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
  _validate_config_models "$HOME/.config/opencode/opencode.jsonc" "OpenCode"
  # Deploy shared OpenCode agent prompts (profile-agnostic)
  mkdir -p "$HOME/.config/opencode/agents"
  for _agent_md in "${SETTINGS_BASE}/ai/opencode/agents/"*.md; do
    [ -f "$_agent_md" ] && copy_file "$_agent_md" "$HOME/.config/opencode/agents/$(basename "$_agent_md")"
  done

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

  mkdir -p "$HOME/.config/zed"
  copy_file "${_profdir}/zed/settings.json" "$HOME/.config/zed/settings.json"
  _validate_config_models "$HOME/.config/zed/settings.json" "Zed"

  mkdir -p "$HOME/.aider"
  copy_file "${_profdir}/aider/aider.conf.yml" "$HOME/.aider.conf.yml"
  _validate_config_models "$HOME/.aider.conf.yml" "Aider"

  mkdir -p "$HOME/.kilo"
  copy_file "${_profdir}/kilocode/kilo.jsonc" "$HOME/.kilo/kilo.jsonc"
  _validate_config_models "$HOME/.kilo/kilo.jsonc" "Kilo Code"
  # Deploy shared Kilo Code agent prompts (profile-agnostic)
  mkdir -p "$HOME/.kilo/agents"
  for _agent_md in "${SETTINGS_BASE}/ai/kilocode/agents/"*.md; do
    [ -f "$_agent_md" ] && copy_file "$_agent_md" "$HOME/.kilo/agents/$(basename "$_agent_md")"
  done

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

    # Canonical local models from LOCAL_MODEL_NAMES plus any explicit GGUF variants
    if declare -p LOCAL_MODEL_NAMES &>/dev/null 2>&1; then
      for _alias in "${LOCAL_MODEL_NAMES[@]}"; do
        _local+=("$_alias")

        local _variants="${GGUF_VARIANTS[$_alias]:-}"
        if [[ -n "$_variants" ]]; then
          IFS=',' read -ra _variant_specs <<< "$_variants"
          for _spec in "${_variant_specs[@]}"; do
            _spec="$(echo "$_spec" | sed 's/^ *//;s/ *$//')"
            [[ -z "$_spec" ]] && continue
            IFS='|' read -r _extra_quant _extra_filename _extra_source <<< "$_spec"
            [[ -z "$_extra_quant" ]] && continue
            local _safe_quant
            _safe_quant="$(echo "$_extra_quant" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')"
            _local+=("${_alias}-${_safe_quant}")
          done
        fi
      done
    fi

    # Cloud Ollama manifests retained separately
    if declare -p OLLAMA_CLOUD_MODELS &>/dev/null 2>&1; then
      for _m in "${OLLAMA_CLOUD_MODELS[@]}"; do
        _cloud+=("${_m%:cloud}")
      done
    fi

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

    # Scalar model vars — split by suffix
    for _v in CLINE_MODEL ZOOCODE_MODEL KILOCODE_MODEL \
              AIDER_MODEL AIDER_WEAK_MODEL AIDER_EDITOR_MODEL \
              ZED_MODEL CURSOR_MODEL; do
      local _val="${!_v:-}"
      [ -n "$_val" ] && _local+=("$_val")
    done
    for _v in CLINE_MODEL_CLOUD ZOOCODE_MODEL_CLOUD \
              KILOCODE_MODEL_CLOUD CURSOR_MODEL_CLOUD; do
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
  local _mapper="${SETTINGS_BASE}/ai/profiles/generate-model-map.sh"
  if [ -f "$_mapper" ]; then
    bash "$_mapper" "${_profile}" 2>/dev/null && log_info "  Updated model-map.md" || true
  fi

  # --- Offer to scout for new agents ---
  echo ""
  echo "  Agent Scanner"
  echo "  -------------"
  read -p "  Check for new terminal AI agents worth adding? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local _agent_scout="${SETTINGS_BASE}/agent-scout.sh"
    if [ -f "$_agent_scout" ]; then
      bash "$_agent_scout" 2>/dev/null || true
    fi
  fi

  log_info "Local model install/update is handled by the setup wizard Local Models step or ./setup_ai.sh models."
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
  backup_llm
  backup_aichat
  backup_fabric
  backup_goose
  backup_plandex
  backup_openclaw
  backup_ironclaw
  backup_hermes
  backup_picoclaw
  backup_zeroclaw
  backup_zoocode
  backup_pi
  backup_pi_studio
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
  restore_llm
  restore_aichat
  restore_fabric
  restore_goose
  restore_plandex
  restore_openclaw
  restore_ironclaw
  restore_hermes
  restore_picoclaw
  restore_zeroclaw
  restore_zoocode
  restore_pi
  restore_pi_studio
  log_status "All configurations restored successfully"
}

verify_installations() {
  log_info "Verifying tool installations..."
  local verification_results=""
  local all_passed=true
  for check in verify_ollama verify_openrouter verify_openwebui verify_claude_code verify_cline_cli verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_groq verify_github_copilot verify_aider verify_cursor verify_kilocode verify_zed verify_tabby verify_llm verify_aichat verify_fabric verify_goose verify_plandex verify_openclaw verify_ironclaw verify_hermes verify_picoclaw verify_zeroclaw verify_zoocode verify_pi verify_pi_studio; do
    local label="${check#verify_}"
    [[ "$label" == "claude_code" ]] && label="claude"
    [[ "$label" == "cline_cli" ]] && label="cline"
    [[ "$label" == "pi_studio" ]] && label="pi-studio"
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
  ["terminal-agents"]="claude cline opencode crush aider codex gemini grok llm fabric aichat goose plandex pi openclaw ironclaw hermes picoclaw zeroclaw"
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
  ["llm"]="setup_llm"
  ["fabric"]="setup_fabric"
  ["aichat"]="setup_aichat"
  ["goose"]="setup_goose"
  ["plandex"]="setup_plandex"
  ["openclaw"]="setup_openclaw"
  ["ironclaw"]="setup_ironclaw"
  ["hermes"]="setup_hermes"
  ["picoclaw"]="setup_picoclaw"
  ["zeroclaw"]="setup_zeroclaw"
  ["zoocode"]="setup_zoocode"
  ["pi"]="setup_pi"
  ["pi-studio"]="setup_pi_studio"
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
  ["llm"]="verify_llm"
  ["fabric"]="verify_fabric"
  ["aichat"]="verify_aichat"
  ["goose"]="verify_goose"
  ["plandex"]="verify_plandex"
  ["openclaw"]="verify_openclaw"
  ["ironclaw"]="verify_ironclaw"
  ["hermes"]="verify_hermes"
  ["picoclaw"]="verify_picoclaw"
  ["zeroclaw"]="verify_zeroclaw"
  ["zoocode"]="verify_zoocode"
  ["pi"]="verify_pi"
  ["pi-studio"]="verify_pi_studio"
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
  ["llm"]="LLM"
  ["fabric"]="Fabric"
  ["aichat"]="AIChat"
  ["goose"]="Goose"
  ["plandex"]="Plandex"
  ["openclaw"]="OpenClaw"
  ["ironclaw"]="IronClaw"
  ["hermes"]="Hermes"
  ["picoclaw"]="PicoClaw"
  ["zeroclaw"]="ZeroClaw"
  ["zoocode"]="Zoo Code"
  ["pi"]="Pi"
  ["pi-studio"]="Pi Studio"
)


# Tools in this family are intentionally never installed as an implicit bundle.
# They are experimental/overlapping terminal agents, so every setup path must
# force an explicit fzf selection before installing any of them.
CLAW_SELECTOR_TOOLS=(plandex openclaw ironclaw hermes picoclaw zeroclaw)

declare -A CLAW_SELECTOR_TOOL_DESCRIPTIONS=(
  ["plandex"]="Terminal AI planner for multi-file coding tasks"
  ["openclaw"]="Personal AI assistant with 25+ messaging channels"
  ["ironclaw"]="Privacy-first Agent OS with 13 security layers"
  ["hermes"]="Self-improving AI agent from Nous Research"
  ["picoclaw"]="Tiny AI for embedded devices / optional dev toolchain"
  ["zeroclaw"]="Fast Rust AI assistant / OpenClaw successor"
)

is_claw_selector_tool() {
  local tool="$1" candidate
  for candidate in "${CLAW_SELECTOR_TOOLS[@]}"; do
    [[ "$tool" == "$candidate" ]] && return 0
  done
  return 1
}

select_claw_tools_with_fzf() {
  local candidates=("$@")
  local candidate selected line
  local entries=()

  if [ ${#candidates[@]} -eq 0 ]; then
    return 0
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is required to choose optional Claw/Plandex tools. Run: brew install fzf"
    return 1
  fi

  for candidate in "${candidates[@]}"; do
    entries+=("${candidate}"$'	'"$(printf '%-10s  %s' "${DISPLAY_NAMES[$candidate]:-$candidate}" "${CLAW_SELECTOR_TOOL_DESCRIPTIONS[$candidate]:-Optional terminal agent}")")
  done

  selected=$(printf "%s
" "${entries[@]}" |     fzf --multi         --header "Choose optional Claw/Plandex tools to install (Tab/Space=toggle, Enter=confirm, q=skip)"         --layout=reverse -d $'	' --with-nth=2 --bind 'space:toggle') || true

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    cut -f1 <<<"$line"
  done <<< "$selected"
}

install_selected_claw_tools() {
  local candidates=("$@")
  local selected=()
  local tool

  mapfile -t selected < <(select_claw_tools_with_fzf "${candidates[@]}") || return 1

  if [ ${#selected[@]} -eq 0 ]; then
    log_info "Skipped optional Claw/Plandex tools."
    return 0
  fi

  CLAW_SELECTOR_ACTIVE=1
  for tool in "${selected[@]}"; do
    install_tool "$tool"
  done
  unset CLAW_SELECTOR_ACTIVE
}

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

apply_infrastructure_stack() {
  local runtimes="$1"
  local access_layers="$2"

  local current
  current=$(check_current_infrastructure)
  local desired="${runtimes} ${access_layers}"
  desired="$(echo "$desired" | xargs 2>/dev/null)"

  echo ""
  echo "  Selected runtimes: ${runtimes:-none}"
  echo "  Selected access:   ${access_layers:-none}"
  echo "  Final stack:       ${desired:-hosted-only}"

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

  echo ""
  log_info "Installing infrastructure: ${desired:-hosted-only}"

  for comp in $desired; do
    case "$comp" in
      ollama)     setup_ollama ;;
      llama.cpp)  log_info "llama.cpp runtime selected — managed via local GGUF / llama.cpp tooling" ;;
      omlx)       setup_omlx ;;
      exo)        setup_exo ;;
      openrouter) setup_openrouter ;;
      openwebui)  setup_openwebui ;;
      lmstudio)   setup_lmstudio ;;
    esac
  done

  log_status "Infrastructure setup complete!"
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
  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is required for runtime selection. Run: brew install fzf"
    return 1
  fi
  echo "  Local runtimes run AI models directly on this machine."
  echo "  Pick the ones you want to use:"
  echo "    ollama    — Model manager, simplest local runtime"
  echo "    llama.cpp — Direct GGUF serving (router mode, port 10000)"
  echo "    omlx      — Apple Silicon MLX runtime (experimental)"
  echo "    exo       — Distributed inference across devices"
  echo "  (Tab/Space=toggle, Enter=confirm, Esc=hosted-only)"
  runtimes=$(printf "ollama\nllama.cpp\nomlx\nexo" | \
    fzf --multi \
        --height ~40% \
        --layout=reverse \
        --bind 'space:toggle') || true
  if [ -z "$runtimes" ]; then
    echo "  -> No local runtimes (hosted-only mode)"
  else
    runtimes=$(echo "$runtimes" | tr '\n' ' ' | xargs)
    echo "  -> Selected: $runtimes"
  fi

  echo ""
  echo "  Choose access layer components:"
  echo ""
  echo "  1) Standard access layer  - OpenRouter + OpenWebUI + Unsloth Studio"
  echo "  2) OpenRouter only"
  echo "  3) OpenWebUI only"
  echo "  4) Unsloth Studio only"
  echo "  5) None"
  echo "  6) Custom access layer"
  echo ""
  printf "Select access option [1]: "
  read -r access_choice
  access_choice="${access_choice:-1}"

  local access_layers=""
  case "$access_choice" in
    1) access_layers="openrouter openwebui lmstudio" ;;
    2) access_layers="openrouter" ;;
    3) access_layers="openwebui" ;;
    4) access_layers="lmstudio" ;;
    5) access_layers="" ;;
    6)
      echo ""
      echo "Select access layer components (space-separated, enter to confirm):"
      echo "  openrouter - Cloud model fallback / broker"
      echo "  openwebui  - Web UI"
      echo "  lmstudio   - Unsloth Studio / local GUI"
      echo ""
      printf "Access components [openrouter openwebui lmstudio]: "
      read -r access_layers
      access_layers="${access_layers:-openrouter openwebui lmstudio}"
      ;;
    *)
      log_error "Invalid option"
      return 1
      ;;
  esac

  apply_infrastructure_stack "$runtimes" "$access_layers"
}

install_tool() {
  local tool="$1"
  local setup_func="${GROUP_SETUP_FUNCS[$tool]}"
  local verify_func="${GROUP_VERIFY_FUNCS[$tool]}"
  local display_name="${DISPLAY_NAMES[$tool]:-$tool}"

  if is_claw_selector_tool "$tool" && [[ "${CLAW_SELECTOR_ACTIVE:-0}" != "1" ]]; then
    install_selected_claw_tools "$tool"
    return $?
  fi

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

  local claw_candidates=()
  for tool in $tools; do
    if is_claw_selector_tool "$tool"; then
      claw_candidates+=("$tool")
      continue
    fi
    install_tool "$tool"
  done

  if [ ${#claw_candidates[@]} -gt 0 ]; then
    install_selected_claw_tools "${claw_candidates[@]}"
  fi
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

wizard_init_context() {
  WIZARD_PROFILE="${MACHINE_PROFILE:-}"
  WIZARD_INFRA_ACTION="skip"
  WIZARD_MODEL_ACTION="skip"
  WIZARD_CONFIG_ACTION="skip"
  WIZARD_TOOL_ACTION="skip"
  WIZARD_VERIFY_ACTION="skip"
}

prompt_wizard_choice() {
  local prompt="$1"
  shift

  echo ""
  echo "$prompt"
  local option
  for option in "$@"; do
    echo "  $option"
  done
  echo ""
  read -r -p "Enter choice: " WIZARD_CHOICE
}

wizard_step_profile() {
  print_step "Profile"

  local detected="${MACHINE_PROFILE:-unknown}"
  local profiles_dir="${SETTINGS_BASE}/ai/profiles"

  echo "Detected profile: ${detected}"
  prompt_wizard_choice \
    "Choose profile handling:" \
    "1) Use detected profile (${detected})" \
    "2) Choose another profile" \
    "3) Cancel"

  case "${WIZARD_CHOICE:-1}" in
    1|"")
      WIZARD_PROFILE="$detected"
      ;;
    2)
      print_profile_menu "$detected"
      echo ""
      local num_profiles
      num_profiles=$(ls -d "${profiles_dir}"/*/ 2>/dev/null | wc -l | tr -d ' ')
      local total_options=$((num_profiles + 2))
      read -r -p "Enter selection [1-$total_options] (Enter = $detected): " choice
      choice="${choice:-$detected}"
      local profile
      profile=$(get_profile_for_choice "$choice") || {
        log_error "Invalid selection: '$choice'"
        return 1
      }
      WIZARD_PROFILE="$profile"
      ;;
    3)
      log_info "Setup cancelled."
      return 1
      ;;
    *)
      log_error "Invalid selection."
      return 1
      ;;
  esac

  export MACHINE_PROFILE="$WIZARD_PROFILE"
  log_info "Using profile: ${WIZARD_PROFILE}"
}

wizard_step_infrastructure() {
  print_step "Infrastructure"
  echo ""
  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is required for runtime selection. Run: brew install fzf"
    return 1
  fi
  echo "  Local runtimes run AI models directly on this machine."
  echo "  Pick the ones you want to use:"
  echo "    ollama    — Model manager, simplest local runtime"
  echo "    llama.cpp — Direct GGUF serving (router mode, port 10000)"
  echo "    omlx      — Apple Silicon MLX runtime (experimental)"
  echo "    exo       — Distributed inference across devices"
  echo "  (Tab/Space=toggle, Enter=confirm, Esc=hosted-only)"
  local runtimes
  runtimes=$(printf "ollama\nllama.cpp\nomlx\nexo" | \
    fzf --multi \
        --height ~40% \
        --layout=reverse \
        --bind 'space:toggle') || true
  if [ -z "$runtimes" ]; then
    echo "  -> No local runtimes (hosted-only mode)"
    WIZARD_INFRA_ACTION="hosted-only"
  else
    runtimes=$(echo "$runtimes" | tr '\n' ' ' | xargs)
    WIZARD_INFRA_ACTION="${runtimes// /+}"
    echo "  -> Selected: $runtimes"
  fi

  prompt_wizard_choice \
    "Choose access layer:" \
    "1) Standard access layer (OpenRouter + OpenWebUI + Unsloth Studio)" \
    "2) OpenRouter only" \
    "3) OpenWebUI only" \
    "4) Unsloth Studio only" \
    "5) None" \
    "6) Custom access layer"

  local access_layers=""
  case "${WIZARD_CHOICE:-1}" in
    1|"") access_layers="openrouter openwebui lmstudio" ;;
    2) access_layers="openrouter" ;;
    3) access_layers="openwebui" ;;
    4) access_layers="lmstudio" ;;
    5) access_layers="" ;;
    6)
      echo ""
      echo "Select access layer components (space-separated, enter to confirm):"
      echo "  openrouter - Cloud model fallback / broker"
      echo "  openwebui  - Web UI"
      echo "  lmstudio   - Unsloth Studio / local GUI"
      echo ""
      read -r -p "Access components [openrouter openwebui lmstudio]: " access_layers
      access_layers="${access_layers:-openrouter openwebui lmstudio}"
      ;;
    *)
      log_error "Invalid selection."
      return 1
      ;;
  esac

  apply_infrastructure_stack "$runtimes" "$access_layers"
}

wizard_step_local_models() {
  print_step "Local Models"

  local profile_name="$(_profile_name "$WIZARD_PROFILE")"
  local runtime_selection="${WIZARD_INFRA_ACTION:-all}"

  # Pre-generate the model plan for the preview pane
  local plan_file
  plan_file=$(mktemp)
  review_local_model_plan_for_profile "$WIZARD_PROFILE" "$profile_name" "$runtime_selection" > "$plan_file" 2>&1

  while true; do
    local choice
    choice=$(printf "skip\nreview plan\ninstall/update\nsync (install/update + prune)\ncancel" | \
      fzf --header "How should local models be handled for ${profile_name}? (enter to confirm, space to toggle plan preview)" \
          --layout=reverse \
          --height ~60% \
          --bind 'space:toggle-preview' \
          --preview-window=up:55%:wrap \
          --preview "
            if [ {} = 'review plan' ]; then
              cat '$plan_file'
            else
              case {} in
                'install/update')
                  echo 'Download missing GGUFs and register Ollama aliases.'
                  echo 'Non-destructive — existing models are kept.'
                  ;;
                'sync (install/update + prune)')
                  echo 'Install/update, then prune — full profile sync.'
                  echo 'Downloads missing models, removes extras not in profile.'
                  ;;
                'cancel')
                  echo 'Cancel the setup wizard.'
                  ;;
                *)
                  echo 'Skip this step — no changes to local models.'
                  ;;
              esac
            fi
          ") || true

    case "$choice" in
      "")
        # Esc or no selection — skip
        WIZARD_MODEL_ACTION="skip"
        break
        ;;
      "review plan")
        # Plan is visible in the preview pane
        echo ""
        read -r -p "  Press Enter to return to the menu..." -n 1
        echo ""
        continue
        ;;
      "skip")
        WIZARD_MODEL_ACTION="skip"
        break
        ;;
      "install/update")
        WIZARD_MODEL_ACTION="install:${runtime_selection}"
        echo ""
        read -r -p "Proceed with local model install/update? (y/N) " -n 1 -r
        echo ""
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
          install_local_models_for_profile "$WIZARD_PROFILE" "$profile_name" "$runtime_selection"
        else
          log_info "Skipped local model install/update."
          WIZARD_MODEL_ACTION="skip"
        fi
        break
        ;;
      "sync (install/update + prune)")
        WIZARD_MODEL_ACTION="sync:${runtime_selection}"
        echo ""
        read -r -p "Proceed with local model sync (install/update, then prune)? (y/N) " -n 1 -r
        echo ""
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
          install_local_models_for_profile "$WIZARD_PROFILE" "$profile_name" "$runtime_selection"
          prune_local_models_for_profile "$WIZARD_PROFILE" "$profile_name"
        else
          log_info "Skipped local model sync."
          WIZARD_MODEL_ACTION="skip"
        fi
        break
        ;;
      "cancel")
        log_info "Setup cancelled."
        return 1
        ;;
    esac
  done

  # --- OpenRouter model suggestions ---
  echo ""
  echo "  OpenRouter Model Discovery"
  echo "  --------------------------"
  read -p "  Check OpenRouter for new models worth trying? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    local _suggester="${SETTINGS_BASE}/ai/profiles/suggest-models.sh"
    if [ -f "$_suggester" ]; then
      bash "$_suggester" "$WIZARD_PROFILE" 2>/dev/null || true
    fi
  fi

  rm -f "$plan_file"
}

wizard_step_tool_search() {
  print_step "AI Tool Discovery"
  echo ""
  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is required for tool discovery. Run: brew install fzf"
    return 1
  fi

  local tools_catalog=(
    "server:ollama:Local model manager"
    "server:exo:Distributed inference"
    "server:tabby:Autocomplete server"
    "cloud:openrouter:Cloud model proxy"
    "cloud:groq:Groq API config"
    "agent:claude:Claude Code CLI"
    "agent:opencode:OpenCode AI agent"
    "agent:aider:Aider coding agent"
    "agent:crush:Crush terminal agent"
    "agent:codex:Codex CLI"
    "agent:gemini:Gemini CLI"
    "agent:grok:Grok CLI"
    "agent:llm:Swiss-army-knife LLM CLI"
    "agent:fabric:Prompt framework"
    "agent:aichat:Rust AI CLI with MCP"
    "agent:goose:Open-source agent"
    "agent:open-hands:Open Hands (Docker)"
    "agent:plandex:Terminal AI planner"
    "agent:openclaw:Personal AI assistant"
    "agent:ironclaw:Privacy-first Agent OS"
    "agent:hermes:Self-improving agent"
    "agent:zeroclaw:Fast Rust AI assistant"
    "agent:pi:Pi coding agent CLI"
    "editor:continue:Continue VS Code ext"
    "editor:cline:Cline VS Code ext"
    "editor:copilot:GitHub Copilot"
    "editor:kilocode:Kilo Code ext"
    "editor:windsurf:Windsurf IDE"
    "editor:cursor:Cursor IDE"
    "editor:zed:Zed editor"
    "editor:sublime:Sublime Text"
    "misc:anythingllm:AnythingLLM desktop"
    "misc:zoocode:Zoo Code ext"
    "misc:pi-studio:Pi Studio desktop GUI for Pi coding agent"
  )

  local selected
  selected=$(printf "%s\n" "${tools_catalog[@]}" | \
    fzf --multi \
        --header "Search and select AI tools to install (Tab/Space=toggle, Enter=confirm, Esc=skip)" \
        --layout=reverse \
        --height ~70% \
        --bind 'space:toggle' \
        --bind 'ctrl-/:toggle-preview' \
        --preview "
          case {} in
            server:*) echo 'Server / runtime tool — installs system-wide.' ;;
            cloud:*) echo 'Cloud provider — deploys API config.' ;;
            agent:*) echo 'AI terminal agent — installs CLI and config.' ;;
            editor:*) echo 'Editor / IDE — installs app or extension.' ;;
            misc:*) echo 'Other AI tool — installs and configures.' ;;
          esac
          echo ''
          echo 'Tool: {}'
        " \
        --preview-window=up:3:wrap) || true

  if [ -z "$selected" ]; then
    log_info "Skipped tool discovery."
    return 0
  fi

  echo ""
  echo "  Selected tools:"
  local line tool
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    tool=$(echo "$line" | cut -d: -f2)
    echo "    - $tool"
  done <<< "$selected"

  read -r -p "  Install selected tools? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      tool=$(echo "$line" | cut -d: -f2)
      install_tool "$tool" 2>/dev/null || log_warning "  Failed to install $tool"
    done <<< "$selected"
    log_status "Tool installation complete."
  else
    log_info "Skipped tool installation."
  fi
}

wizard_step_mcp_servers() {
  deploy_mcp_servers
}

wizard_step_configs() {
  print_step "Configs"
  prompt_wizard_choice \
    "How should AI configs be handled?" \
    "1) Skip" \
    "2) Deploy recommended configs" \
    "3) Cancel"

  case "${WIZARD_CHOICE:-1}" in
    1|"")
      WIZARD_CONFIG_ACTION="skip"
      ;;
    2)
      WIZARD_CONFIG_ACTION="deploy"
      deploy_configs
      ;;
    3)
      log_info "Setup cancelled."
      return 1
      ;;
    *)
      log_error "Invalid selection."
      return 1
      ;;
  esac
}

wizard_step_tools() {
  print_step "AI Tools"
  prompt_wizard_choice \
    "How should AI tools be installed?" \
    "1) Skip" \
    "2) Recommended tool bundles" \
    "3) Choose tool groups" \
    "4) Open legacy interactive menu" \
    "5) Cancel"

  case "${WIZARD_CHOICE:-1}" in
    1|"")
      WIZARD_TOOL_ACTION="skip"
      ;;
    2)
      WIZARD_TOOL_ACTION="recommended"
      install_group "infrastructure"
      install_group "terminal-agents"
      install_group "vscode-extensions"
      ;;
    3)
      WIZARD_TOOL_ACTION="groups"
      echo "Available groups: infrastructure, terminal-agents, vscode-extensions, ides, self-hosted, all"
      read -r -p "Enter comma-separated groups: " groups
      [ -n "${groups:-}" ] && install_groups "$groups"
      ;;
    4)
      WIZARD_TOOL_ACTION="legacy-menu"
      interactive_menu
      ;;
    5)
      log_info "Setup cancelled."
      return 1
      ;;
    *)
      log_error "Invalid selection."
      return 1
      ;;
  esac
}

wizard_step_verify() {
  print_step "Verification"
  prompt_wizard_choice \
    "Run verification checks now?" \
    "1) Skip" \
    "2) Run verification" \
    "3) Cancel"

  case "${WIZARD_CHOICE:-1}" in
    1|"")
      WIZARD_VERIFY_ACTION="skip"
      ;;
    2)
      WIZARD_VERIFY_ACTION="verify"
      verify_installations
      ;;
    3)
      log_info "Setup cancelled."
      return 1
      ;;
    *)
      log_error "Invalid selection."
      return 1
      ;;
  esac
}

wizard_step_summary() {
  print_step "Summary"
  echo "Profile:        ${WIZARD_PROFILE:-unknown}"
  echo "Infrastructure: ${WIZARD_INFRA_ACTION}"
  echo "Local models:   ${WIZARD_MODEL_ACTION}"
  echo "Configs:        ${WIZARD_CONFIG_ACTION}"
  echo "AI tools:       ${WIZARD_TOOL_ACTION}"
  echo "Verification:   ${WIZARD_VERIFY_ACTION}"
}

run_ai_setup_wizard() {
  print_step "AI Setup Wizard"
  wizard_init_context
  wizard_step_profile || return 1
  wizard_step_infrastructure || return 1
  wizard_step_local_models || return 1
  wizard_step_tool_search || return 1
  wizard_step_mcp_servers || return 1
  wizard_step_configs || return 1
  wizard_step_tools || return 1
  wizard_step_verify || return 1
  wizard_step_summary
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
  setup:models) manage_local_models ;;
  setup:ollama) setup_ollama ;;
  setup:olol) setup_olol ;;
  setup:anythingllm) setup_anythingllm ;;
  setup:lmstudio) setup_lmstudio ;;

  setup:open-hands) setup_openhands ;;
  setup:openrouter) setup_openrouter ;;
  setup:opencode) setup_opencode ;;
  setup:llm) setup_llm ;;
  setup:fabric) setup_fabric ;;
  setup:aichat) setup_aichat ;;
  setup:goose) setup_goose ;;
  setup:plandex) install_tool "plandex" ;;
  setup:openclaw) install_tool "openclaw" ;;
  setup:ironclaw) install_tool "ironclaw" ;;
  setup:hermes) install_tool "hermes" ;;
  setup:picoclaw) install_tool "picoclaw" ;;
  setup:zeroclaw) install_tool "zeroclaw" ;;
  setup:pi) setup_pi ;;
  setup:pi-studio) setup_pi_studio ;;
  setup:zoocode) setup_zoocode ;;

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
  restore:llm) restore_llm ;;
  restore:fabric) restore_fabric ;;
  restore:aichat) restore_aichat ;;
  restore:goose) restore_goose ;;
  restore:plandex) restore_plandex ;;
  restore:openclaw) restore_openclaw ;;
  restore:ironclaw) restore_ironclaw ;;
  restore:hermes) restore_hermes ;;
  restore:picoclaw) restore_picoclaw ;;
  restore:zeroclaw) restore_zeroclaw ;;
  restore:pi) restore_pi ;;
  restore:pi-studio) restore_pi_studio ;;
  restore:zoocode) restore_zoocode ;;
  restore:*) log_info "No restore available for $tool — skipping" ;;
  backup:claude) backup_claude ;;
  backup:continue) backup_continue ;;
  backup:crush) backup_crush ;;
  backup:grok) backup_grok ;;
  backup:groq) backup_groq ;;

  backup:olol) backup_olol ;;
  backup:opencode) backup_opencode ;;
  backup:llm) backup_llm ;;
  backup:fabric) backup_fabric ;;
  backup:aichat) backup_aichat ;;
  backup:goose) backup_goose ;;
  backup:plandex) backup_plandex ;;
  backup:openclaw) backup_openclaw ;;
  backup:ironclaw) backup_ironclaw ;;
  backup:hermes) backup_hermes ;;
  backup:picoclaw) backup_picoclaw ;;
  backup:zeroclaw) backup_zeroclaw ;;
  backup:pi) backup_pi ;;
  backup:pi-studio) backup_pi_studio ;;
  backup:zoocode) backup_zoocode ;;
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
    "llm|tools|Simon Willison's swiss-army-knife CLI for LLMs (Ollama plugins)"
    "fabric|tools|Prompt framework with 100+ patterns, YouTube scraping, custom roles"
    "aichat|tools|Rust CLI with shell assistant, RAG, MCP tools, agents"
    "goose|tools|Block's open-source agent (desktop + CLI + API) with MCP"
    "plandex|tools|Terminal AI planner for multi-file coding tasks"
    "openclaw|tools|Personal AI assistant with 25+ messaging channels"
    "ironclaw|tools|Privacy-first Agent OS with 13 security layers (Rust)"
    "hermes|tools|Self-improving AI agent from Nous Research"
    "zeroclaw|tools|Fast Rust AI assistant (OpenClaw successor)"
    "picoclaw|tools|Tiny AI for embedded devices (optional dev toolchain)"
    "pi|tools|Install Pi coding agent CLI + configure auth"
    "pi-studio|editors|Install Pi Studio desktop GUI for Pi coding agent"
    "open-hands|tools|Install Open Hands (Docker) + deploy config"

     "cursor|editors|Install Cursor IDE + show Ollama config"

    "kilocode|editors|Install Kilo Code VS Code extension"
    "sublime|editors|Install Sublime Text"
    "zed|editors|Install Zed editor + deploy config"
    "vscode|editors|Install VS Code + Continue + Cline extensions"
    "windsurf|editors|Install Windsurf IDE + deploy argv.json"

    "continue|extensions|Deploy Continue.dev config"
    "copilot|extensions|Install gh-copilot extension + VS Code extensions"
    "zoocode|extensions|Deploy Zoo Code VS Code config merge"
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
  pi)
    setup_pi
    ;;
  pi-studio)
    setup_pi_studio
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
  llm)
    setup_llm
    ;;
  fabric)
    setup_fabric
    ;;
  aichat)
    setup_aichat
    ;;
  goose)
    setup_goose
    ;;
  plandex|openclaw|ironclaw|hermes|picoclaw|zeroclaw)
    install_tool "$1"
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
    manage_local_models
    ;;
  deploy)
    deploy_mcp_servers
    deploy_configs
    ;;
  infrastructure)
    select_infrastructure
    ;;
  wizard|"")
    run_ai_setup_wizard
    ;;
  *)
    echo "Usage: $0 {backup|restore|deploy|vscode|windsurf|continue|opencode|crush|claude|cline|aider|cursor|kilocode|zed|tabby|open-hands|pi|pi-studio|setup|ollama|grok|olol|exo|codex|gemini|llm|fabric|aichat|goose|plandex|anythingllm|lmstudio|copilot|check|verify|install|infrastructure|models}"
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
    echo "  install:vscode-extensions  - Continue, Copilot, Kilocode"
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
    echo "  llm         - Setup LLM CLI"
    echo "  fabric      - Setup Fabric"
    echo "  aichat      - Setup AIChat"
    echo "  goose       - Setup Goose"
    echo "  pi          - Install Pi coding agent CLI"
    echo "  pi-studio   - Install Pi Studio desktop GUI"
    echo "  plandex     - Setup Plandex"
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
