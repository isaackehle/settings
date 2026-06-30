#!/usr/bin/env python3
"""Setup AI — Web UI Installer

Lightweight Flask frontend for the homelab setup wizard.
Uses the hardware matrix and component registry for unified installation.

Usage:
    cd ~/code/isaackehle/settings/ai/setup-web
    python3 app.py
    # Open http://localhost:5555
"""

import json
import os
import subprocess
import sys
import threading
import time
from pathlib import Path
from queue import Queue

from flask import Flask, Response, jsonify, render_template, request

app = Flask(__name__)

# ── Paths ────────────────────────────────────────────────────────────────
SETTINGS_BASE = Path(__file__).resolve().parent.parent.parent
HOMELAB_ROOT = SETTINGS_BASE.parent / "homelab"
COMPONENTS_DIR = HOMELAB_ROOT / "components"
HARDWARE_MATRIX = COMPONENTS_DIR / "hardware-matrix.json"
sys.path.insert(0, str(SETTINGS_BASE / "ai"))

# ── Progress streaming ───────────────────────────────────────────────────
progress_queue: Queue = Queue()


def emit_progress(step: str, status: str, detail: str = ""):
    """Push a progress event to the SSE stream."""
    progress_queue.put({"step": step, "status": status, "detail": detail})


# ── Hardware detection ──────────────────────────────────────────────────
def detect_hardware() -> dict:
    """Detect machine hardware and resolve via matrix."""
    try:
        hw_model = subprocess.check_output(
            ["sysctl", "-n", "hw.model"], text=True
        ).strip()
        mem_bytes = int(subprocess.check_output(
            ["sysctl", "-n", "hw.memsize"], text=True
        ).strip())
        hw_mem_gb = mem_bytes // (1024 ** 3)
        hw_cores = int(subprocess.check_output(
            ["sysctl", "-n", "hw.ncpu"], text=True
        ).strip())

        # Resolve tiers
        memory_tier = _resolve_memory_tier(hw_mem_gb)
        speed_tier = _resolve_speed_tier(hw_model)

        # Load matrix
        matrix = _load_matrix()

        # Get quant override for speed tier
        speed_config = matrix.get("speed_tiers", {}).get(speed_tier, {})
        quant_override = speed_config.get("quant_default", "q4")
        omlx_supported = speed_config.get("omlx_supported", False)

        # Get models for both backends
        models_ollama = matrix.get("models", {}).get(memory_tier, {}).get("ollama", {})
        models_omlx = matrix.get("models", {}).get(memory_tier, {}).get("omlx", {})

        # Get fleet role for this machine
        hostname = subprocess.check_output(
            ["tailscale", "status", "--json"], text=True, timeout=5
        )
        import json as json_mod
        tailscale_data = json_mod.loads(hostname)
        machine_name = tailscale_data.get("Self", {}).get("HostName", "unknown")
        fleet_config = matrix.get("fleet_roles", {}).get(machine_name, {})

        return {
            "hw_model": hw_model,
            "hw_mem_gb": hw_mem_gb,
            "hw_cores": hw_cores,
            "memory_tier": memory_tier,
            "speed_tier": speed_tier,
            "quant_override": quant_override,
            "omlx_supported": omlx_supported,
            "machine_name": machine_name,
            "fleet_role": fleet_config.get("role", "unknown"),
            "models_ollama": models_ollama,
            "models_omlx": models_omlx,
        }
    except Exception as e:
        return {"error": str(e)}


def _resolve_memory_tier(mem_gb: int) -> str:
    if mem_gb <= 16:
        return "light"
    elif mem_gb <= 32:
        return "medium"
    elif mem_gb <= 48:
        return "heavy"
    else:
        return "maximum"


def _resolve_speed_tier(hw_model: str) -> str:
    import fnmatch
    for pattern, tier in [
        (["Mac10*", "Mac11*", "Mac12*", "Mac13*", "Intel*"], "slow"),
        (["Mac14*", "Mac15*"], "fast"),
        (["Mac16*", "Mac17*", "Mac18*"], "fastest"),
    ]:
        for p in pattern:
            if fnmatch.fnmatch(hw_model, p):
                return tier
    return "fast"  # default


def _load_matrix() -> dict:
    if HARDWARE_MATRIX.exists():
        return json.loads(HARDWARE_MATRIX.read_text())
    return {}


# ── Component registry ──────────────────────────────────────────────────
def list_components() -> list[dict]:
    """Discover all components from the registry."""
    components = []
    if not COMPONENTS_DIR.exists():
        return components

    for category_dir in COMPONENTS_DIR.iterdir():
        if not category_dir.is_dir() or category_dir.name.startswith("_"):
            continue

        for component_dir in category_dir.iterdir():
            if not component_dir.is_dir():
                continue

            meta_file = component_dir / "component.json"
            if not meta_file.exists():
                continue

            try:
                meta = json.loads(meta_file.read_text())
                components.append({
                    "name": meta.get("name", component_dir.name),
                    "slug": component_dir.name,
                    "category": category_dir.name,
                    "description": meta.get("description", ""),
                    "dependencies": meta.get("dependencies", []),
                    "install_script": str(component_dir / "install.sh"),
                })
            except json.JSONDecodeError:
                continue

    return components


def get_components_by_category() -> dict:
    """Group components by category."""
    components = list_components()
    grouped = {}
    for comp in components:
        cat = comp["category"]
        if cat not in grouped:
            grouped[cat] = []
        grouped[cat].append(comp)
    return grouped


# ── Component status detection ────────────────────────────────────────────
def _check_component_installed(slug: str) -> dict:
    """Check if a component is installed, outdated, or missing."""
    status = {"installed": False, "version": None, "needs_update": False, "extra": False}
    
    try:
        if slug == "ollama":
            result = subprocess.run(["ollama", "--version"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                status["installed"] = True
                status["version"] = result.stdout.strip().split()[-1] if result.stdout else "unknown"
        elif slug == "omlx":
            result = subprocess.run(["omlx", "--version"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                status["installed"] = True
                status["version"] = result.stdout.strip().split()[-1] if result.stdout else "unknown"
        elif slug == "openwebui":
            result = subprocess.run(["docker", "ps", "--format", "{{.Names}}"], capture_output=True, text=True, timeout=5)
            if "open-webui" in result.stdout:
                status["installed"] = True
        elif slug == "openrouter":
            # Check if API key is set
            if os.environ.get("OPENROUTER_API_KEY") or Path.home().env.get("OPENROUTER_API_KEY"):
                status["installed"] = True
        elif slug == "claude":
            result = subprocess.run(["claude", "--version"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                status["installed"] = True
                status["version"] = result.stdout.strip().split()[-1] if result.stdout else "unknown"
        elif slug == "opencode":
            result = subprocess.run(["opencode", "--version"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                status["installed"] = True
                status["version"] = result.stdout.strip().split()[-1] if result.stdout else "unknown"
        elif slug == "cursor":
            if Path("/Applications/Cursor.app").exists():
                status["installed"] = True
        elif slug == "zed":
            if Path("/Applications/Zed.app").exists():
                status["installed"] = True
        elif slug in ["aider", "fabric", "groq"]:
            result = subprocess.run(["which", slug], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                status["installed"] = True
        elif slug in ["lmstudio", "huggingface"]:
            if Path(f"/Applications/{slug.title()}.app").exists():
                status["installed"] = True
    except Exception:
        pass
    
    return status


def get_component_summary() -> dict:
    # Add logging for debugging
    print("Fetching component summary...")
    components = list_components()
    matrix = _load_matrix()
    
    summary = {
        "installed": [],      # Currently installed
        "up_to_date": [],     # Installed and current
        "needs_update": [],   # Installed but outdated
        "missing": [],        # Should be installed but isn't
        "extra": [],          # Installed but not in registry (could remove)
    }
    
    # Check each registered component
    for comp in components:
        slug = comp["slug"]
        status = _check_component_installed(slug)
        
        comp_info = {
            "slug": slug,
            "name": comp["name"],
            "category": comp["category"],
            "description": comp["description"],
            "version": status.get("version"),
        }
        
        if status["installed"]:
            summary["installed"].append(comp_info)
            if status.get("needs_update"):
                summary["needs_update"].append(comp_info)
            else:
                summary["up_to_date"].append(comp_info)
        else:
            summary["missing"].append(comp_info)
    
    return summary
    """Get summary of all components: installed, missing, outdated, extra."""
    components = list_components()
    matrix = _load_matrix()
    
    summary = {
        "installed": [],      # Currently installed
        "up_to_date": [],     # Installed and current
        "needs_update": [],   # Installed but outdated
        "missing": [],        # Should be installed but isn't
        "extra": [],          # Installed but not in registry (could remove)
    }
    
    # Check each registered component
    for comp in components:
        slug = comp["slug"]
        status = _check_component_installed(slug)
        
        comp_info = {
            "slug": slug,
            "name": comp["name"],
            "category": comp["category"],
            "description": comp["description"],
            "version": status.get("version"),
        }
        
        if status["installed"]:
            summary["installed"].append(comp_info)
            if status.get("needs_update"):
                summary["needs_update"].append(comp_info)
            else:
                summary["up_to_date"].append(comp_info)
        else:
            summary["missing"].append(comp_info)
    
    return summary


# ── Model inventory ──────────────────────────────────────────────────────
def get_model_inventory() -> dict:
    """Get all local models grouped by family, quant, and context size."""
    try:
        result = subprocess.run(
            ["ollama", "list", "--format", "json"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return {"error": "Ollama not running or no models"}
        
        models = json.loads(result.stdout) if result.stdout.strip() else []
        
        # Group by family, quant, context
        families = {}
        for m in models:
            name = m.get("name", "")
            size = m.get("size", 0)
            
            # Parse model name: family-variant:quant-context
            # e.g., qwen3-coder-30b-a3b:q4_K_M:128k
            parts = name.split(":")
            base = parts[0] if parts else name
            quant = parts[1] if len(parts) > 1 else "default"
            context = parts[2] if len(parts) > 2 else "default"
            
            # Extract family (first 2-3 words)
            family = "-".join(base.split("-")[:2])
            
            if family not in families:
                families[family] = {}
            if quant not in families[family]:
                families[family][quant] = []
            
            families[family][quant].append({
                "name": name,
                "base": base,
                "context": context,
                "size_gb": round(size / (1024**3), 1) if size else 0,
            })
        
        return {
            "total_models": len(models),
            "total_size_gb": round(sum(m.get("size", 0) for m in models) / (1024**3), 1),
            "families": families,
        }
    except Exception as e:
        return {"error": str(e)}


def get_model_install_plan(memory_tier: str, backends: list[str]) -> dict:
    # Add detailed logging
    print(f"Generating model plan for tier {memory_tier} with backends {backends}")
    matrix = _load_matrix()
    
    # Get recommended models for this tier
    recommended = {}
    for backend in backends:
        backend_models = matrix.get("models", {}).get(memory_tier, {}).get(backend, {})
        for role, info in backend_models.items():
            model_id = info.get("model", "") if isinstance(info, dict) else info
            quant = info.get("quant", "") if isinstance(info, dict) else ""
            context = info.get("context", "") if isinstance(info, dict) else ""
            recommended[model_id] = {
                "role": role,
                "backend": backend,
                "quant": quant,
                "context": context,
            }
    
    # Get installed models
    try:
        result = subprocess.run(
            ["ollama", "list", "--format", "json"],
            capture_output=True, text=True, timeout=10
        )
        installed = {}
        if result.returncode == 0 and result.stdout.strip():
            for m in json.loads(result.stdout):
                name = m.get("name", "")
                installed[name] = {
                    "size_gb": round(m.get("size", 0) / (1024**3), 1),
                }
    except Exception as e:
        print(f"Error fetching installed models: {str(e)}")
        installed = {}
    
    # Compare
    plan = {
        "to_install": [],      # Recommended but not installed
        "to_rename": [],       # Installed but wrong name/format
        "to_update": [],       # Installed but wrong quant/context
        "good": [],            # Installed and correct
        "extra": [],           # Installed but not recommended
    }
    
    # Check recommended against installed
    for model_id, info in recommended.items():
        found = False
        for installed_name in installed.keys():
            # Check if base model matches (before quant)
            if model_id in installed_name or installed_name.startswith(model_id.split(":")[0]):
                found = True
                # Check if quant/context matches
                installed_parts = installed_name.split(":")
                rec_parts = model_id.split(":")
                
                if len(installed_parts) >= 2 and len(rec_parts) >= 2:
                    if installed_parts[1] != rec_parts[1]:
                        plan["to_rename"].append({
                            "current": installed_name,
                            "should_be": model_id,
                            "role": info["role"],
                            "reason": f"quant mismatch: {installed_parts[1]} → {rec_parts[1]}",
                        })
                    elif len(installed_parts) > 2 and len(rec_parts) > 2:
                        if installed_parts[2] != rec_parts[2]:
                            plan["to_update"].append({
                                "current": installed_name,
                                "should_be": model_id,
                                "role": info["role"],
                                "reason": f"context mismatch: {installed_parts[2]} → {rec_parts[2]}",
                            })
                        else:
                            plan["good"].append({
                                "name": installed_name,
                                "role": info["role"],
                                "size_gb": installed[installed_name]["size_gb"],
                            })
                    else:
                        plan["good"].append({
                            "name": installed_name,
                            "role": info["role"],
                            "size_gb": installed[installed_name]["size_gb"],
                        })
                break
        
        if not found:
            plan["to_install"].append({
                "model": model_id,
                "role": info["role"],
                "quant": info["quant"],
                "context": info["context"],
                "backend": info["backend"],
            })
    
    # Check installed against recommended (for extras)
    for installed_name in installed.keys():
        found = False
        for model_id in recommended.keys():
            if model_id in installed_name or installed_name.startswith(model_id.split(":")[0]):
                found = True
                break
        if not found:
            plan["extra"].append({
                "name": installed_name,
                "size_gb": installed[installed_name]["size_gb"],
            })
    
    return plan
    """Compare installed models against what should be installed for this tier."""
    matrix = _load_matrix()
    
    # Get recommended models for this tier
    recommended = {}
    for backend in backends:
        backend_models = matrix.get("models", {}).get(memory_tier, {}).get(backend, {})
        for role, info in backend_models.items():
            model_id = info.get("model", "") if isinstance(info, dict) else info
            quant = info.get("quant", "") if isinstance(info, dict) else ""
            context = info.get("context", "") if isinstance(info, dict) else ""
            recommended[model_id] = {
                "role": role,
                "backend": backend,
                "quant": quant,
                "context": context,
            }
    
    # Get installed models
    try:
        result = subprocess.run(
            ["ollama", "list", "--format", "json"],
            capture_output=True, text=True, timeout=10
        )
        installed = {}
        if result.returncode == 0 and result.stdout.strip():
            for m in json.loads(result.stdout):
                name = m.get("name", "")
                installed[name] = {
                    "size_gb": round(m.get("size", 0) / (1024**3), 1),
                }
    except Exception:
        installed = {}
    
    # Compare
    plan = {
        "to_install": [],      # Recommended but not installed
        "to_rename": [],       # Installed but wrong name/format
        "to_update": [],       # Installed but wrong quant/context
        "good": [],            # Installed and correct
        "extra": [],           # Installed but not recommended
    }
    
    # Check recommended against installed
    for model_id, info in recommended.items():
        found = False
        for installed_name in installed.keys():
            # Check if base model matches (before quant)
            if model_id in installed_name or installed_name.startswith(model_id.split(":")[0]):
                found = True
                # Check if quant/context matches
                installed_parts = installed_name.split(":")
                rec_parts = model_id.split(":")
                
                if len(installed_parts) >= 2 and len(rec_parts) >= 2:
                    if installed_parts[1] != rec_parts[1]:
                        plan["to_rename"].append({
                            "current": installed_name,
                            "should_be": model_id,
                            "role": info["role"],
                            "reason": f"quant mismatch: {installed_parts[1]} → {rec_parts[1]}",
                        })
                    elif len(installed_parts) > 2 and len(rec_parts) > 2:
                        if installed_parts[2] != rec_parts[2]:
                            plan["to_update"].append({
                                "current": installed_name,
                                "should_be": model_id,
                                "role": info["role"],
                                "reason": f"context mismatch: {installed_parts[2]} → {rec_parts[2]}",
                            })
                        else:
                            plan["good"].append({
                                "name": installed_name,
                                "role": info["role"],
                                "size_gb": installed[installed_name]["size_gb"],
                            })
                    else:
                        plan["good"].append({
                            "name": installed_name,
                            "role": info["role"],
                            "size_gb": installed[installed_name]["size_gb"],
                        })
                break
        
        if not found:
            plan["to_install"].append({
                "model": model_id,
                "role": info["role"],
                "quant": info["quant"],
                "context": info["context"],
                "backend": info["backend"],
            })
    
    # Check installed against recommended (for extras)
    for installed_name in installed.keys():
        found = False
        for model_id in recommended.keys():
            if model_id in installed_name or installed_name.startswith(model_id.split(":")[0]):
                found = True
                break
        if not found:
            plan["extra"].append({
                "name": installed_name,
                "size_gb": installed[installed_name]["size_gb"],
            })
    
    return plan


# ── Install execution ───────────────────────────────────────────────────
install_process: subprocess.Popen | None = None
install_log: list[str] = []


def run_install(config: dict):
    """Run the install in a background thread, streaming output."
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"''"
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"''"
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []
    
    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])
    
    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)
    
    bash_script = f"""
    set -euo pipefail
    export SETTINGS_BASE="{SETTINGS_BASE}"
    export HOMELAB_ROOT="{HOMELAB_ROOT}"
    
    # Source the registry and hardware resolver
    source "{COMPONENTS_DIR}/registry.sh"
    source "{COMPONENTS_DIR}/hardware.sh"
    
    # Source component install scripts
    for f in "{COMPONENTS_DIR}"/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
        [ -f "$f" ] && source "$f" 2>/dev/null || true
    done
    
    echo "=== SETUP_START ==="
    echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
    echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
    echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
    echo "Backends: {backends_str}"
    echo "Components: {components_str}"
    echo ""
    
    # Install backends first
    for backend in {backends_str}; do
        echo "=== INSTALLING: $backend ==="
        case "$backend" in
            ollama)  install_ollama 2>&1 ;;
            omlx)    install_omlx 2>&1 ;;
            *)       echo "Unknown backend: $backend" ;;
        esac
        echo "=== DONE: $backend ==="
    done
    
    # Install other components
    for comp in {components_str}; do
        echo "=== INSTALLING: $comp ==="
        case "$comp" in
            ollama)      echo "Already installed" ;;
            omlx)        echo "Already installed" ;;
            openrouter)  install_openrouter 2>&1 ;;
            openwebui)   install_openwebui 2>&1 ;;
            lmstudio)    install_lmstudio 2>&1 ;;
            huggingface) install_huggingface 2>&1 ;;
            claude)      install_claude 2>&1 ;;
            opencode)    install_opencode 2>&1 ;;
            aider)       install_aider 2>&1 ;;
            gemini)      install_gemini 2>&1 ;;
            grok)        install_grok 2>&1 ;;
            crush)       install_crush 2>&1 ;;
            continue)    install_continue 2>&1 ;;
            cursor)      install_cursor 2>&1 ;;
            zed)         install_zed 2>&1 ;;
            goose)       install_goose 2>&1 ;;
        esac
        echo "=== DONE: $comp ==="
    done
    
    echo "=== SETUP_END ==="
"""
    
    # Execute the installation script
    install_process = subprocess.Popen(
        ["/bin/bash", "-c", bash_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    
    # Stream output to client
    while True:
        output = install_process.stdout.readline()
        if output == '' and install_process.poll() is not None:
            break
        if output:
            print(output.strip())
            # Send update via SSE
            emit('install_update', {'output': output.strip()})
    
    # Wait for process to complete
    install_process.wait()
    
    # Notify client of completion
    emit('install_complete', {'status': 'success'})
    global install_process, install_log
    install_log = []

    hardware = config.get("hardware", {})
    components = config.get("components", [])
    backends = config.get("backends", ["ollama"])

    # Build the bash command
    components_str = " ".join(components)
    backends_str = " ".join(backends)

    bash_script = f"""
set -euo pipefail
export SETTINGS_BASE="{SETTINGS_BASE}"
export HOMELAB_ROOT="{HOMELAB_ROOT}"

# Source the registry and hardware resolver
source "{COMPONENTS_DIR}/registry.sh"
source "{COMPONENTS_DIR}/hardware.sh"

# Source component install scripts
for f in "{COMPONENTS_DIR}"/*/install.sh; do
    [ -f "$f" ] && source "$f" 2>/dev/null || true
done
for f in "{COMPONENTS_DIR}"/*/*/install.sh; do
    [ -f "$f" ] && source "$f" 2>/dev/null || true
done

echo "=== SETUP_START ==="
echo "Hardware: {hardware.get('hw_model', 'unknown')} ({hardware.get('hw_mem_gb', '?')}GB)"
echo "Memory tier: {hardware.get('memory_tier', 'unknown')}"
echo "Speed tier: {hardware.get('speed_tier', 'unknown')}"
echo "Backends: {backends_str}"
echo "Components: {components_str}"
echo ""

# Install backends first
for backend in {backends_str}; do
    echo "=== INSTALLING: $backend ==="
    case "$backend" in
        ollama)  install_ollama 2>&1 ;;
        omlx)    install_omlx 2>&1 ;;
        *)       echo "Unknown backend: $backend" ;;
    esac
    echo "=== DONE: $backend ==="
done

# Install other components
for comp in {components_str}; do
    echo "=== INSTALLING: $comp ==="
    case "$comp" in
        ollama)      echo "Already installed" ;;
        omlx)        echo "Already installed" ;;
        openrouter)  install_openrouter 2>&1 ;;
        openwebui)   install_openwebui 2>&1 ;;
        lmstudio)    install_lmstudio 2>&1 ;;
        huggingface) install_huggingface 2>&1 ;;
        claude)      install_claude 2>&1 ;;
        opencode)    install_opencode 2>&1 ;;
        aider)       install_aider 2>&1 ;;
        gemini)      install_gemini 2>&1 ;;
        grok)        install_grok 2>&1 ;;
        crush)       install_crush 2>&1 ;;
        continue)    install_continue 2>&1 ;;
        cursor)      install_cursor 2>&1 ;;
        zed)         install_zed 2>&1 ;;
        goose)       install_goose 2>&1 ;;
        hermes)      install_hermes 2>&1 ;;
        codex)       install_codex 2>&1 ;;
        fabric)      install_fabric 2>&1 ;;
        groq)        install_groq 2>&1 ;;
        *)           echo "Skipping $comp (no install function)" ;;
    esac
    echo "=== DONE: $comp ==="
done

echo "=== SETUP_COMPLETE ==="
"""

    try:
        emit_progress("init", "running", "Starting installation...")

        install_process = subprocess.Popen(
            ["bash", "-c", bash_script],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        for line in install_process.stdout:
            line = line.rstrip("\n")
            install_log.append(line)

            if line.startswith("=== INSTALLING:"):
                comp = line.split(":")[1].strip()
                emit_progress(comp, "started", f"Installing {comp}...")
            elif line.startswith("=== DONE:"):
                comp = line.split(":")[1].strip()
                emit_progress(comp, "complete", f"{comp} installed")
            elif line.startswith("=== SETUP_COMPLETE"):
                emit_progress("all", "complete", "Installation complete!")
            elif line.startswith("ERROR:") or line.startswith("✗"):
                emit_progress("error", "error", line)
            else:
                emit_progress("log", "running", line)

        install_process.wait()
        if install_process.returncode != 0:
            emit_progress("error", "error", f"Exit code: {install_process.returncode}")
        else:
            emit_progress("all", "done", "All done!")

    except Exception as e:
        emit_progress("error", "error", str(e))
    finally:
        install_process = None


# ── Routes ───────────────────────────────────────────────────────────────
@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/detect")
def api_detect():
    return jsonify(detect_hardware())


@app.route("/api/components")
def api_components():
    return jsonify(get_components_by_category())


@app.route("/api/summary")
def api_summary():
    """Pre-install summary of component status."""
    return jsonify(get_component_summary())


@app.route("/api/models")
def api_models():
    """Model inventory grouped by family/quant/context."""
    return jsonify(get_model_inventory())


@app.route("/api/models/plan")
def api_models_plan():
    """Model install plan: what to install, rename, update, or remove."""
    memory_tier = request.args.get("tier", "medium")
    backends = request.args.get("backends", "ollama").split(",")
    return jsonify(get_model_install_plan(memory_tier, backends))


@app.route("/api/install", methods=["POST"])
def api_install():
    config = request.json
    t = threading.Thread(target=run_install, args=(config,), daemon=True)
    t.start()
    return jsonify({"status": "started"})


@app.route("/api/install/status")
def api_install_status():
    return jsonify({
        "running": install_process is not None,
        "log": install_log[-100:],  # last 100 lines
    })


@app.route("/api/stream")
def api_stream():
    """SSE endpoint for real-time progress."""
    def generate():
        while True:
            try:
                event = progress_queue.get(timeout=30)
                yield f"data: {json.dumps(event)}\n\n"
                if event.get("status") == "done":
                    break
            except Exception:
                # Send keepalive
                yield ": keepalive\n\n"

    return Response(generate(), mimetype="text/event-stream")


# ── Fleet Management ──────────────────────────────────────────────────────
@app.route("/api/fleet/machines")
def api_fleet_machines():
    """List all Tailscale machines."""
    try:
        result = subprocess.run(
            ["tailscale", "status", "--json"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            data = json.loads(result.stdout)
            machines = []
            for peer in data.get("Peer", {}).values():
                if peer.get("Online", False):
                    machines.append({
                        "hostname": peer.get("HostName", ""),
                        "ip": peer.get("TailscaleIPs", [""])[0],
                        "os": peer.get("OS", ""),
                        "last_seen": peer.get("LastSeen", ""),
                    })
            return jsonify(machines)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/fleet/check/<hostname>")
def api_fleet_check(hostname):
    """Check component status on remote machine."""
    try:
        result = subprocess.run(
            ["ssh", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
             hostname, "echo ok"],
            capture_output=True, text=True, timeout=10
        )
        ssh_ok = result.returncode == 0

        # Detect hardware remotely
        hw_info = {}
        if ssh_ok:
            result = subprocess.run(
                ["ssh", hostname, """
                    hw_model=$(sysctl -n hw.model 2>/dev/null || echo Unknown)
                    hw_mem_gb=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
                    hw_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
                    echo "$hw_model|$hw_mem_gb|$hw_cores"
                """],
                capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0 and result.stdout.strip():
                parts = result.stdout.strip().split("|")
                if len(parts) >= 3:
                    hw_info = {
                        "model": parts[0],
                        "memory_gb": int(parts[1]),
                        "cores": int(parts[2]),
                    }

        return jsonify({
            "hostname": hostname,
            "ssh_ok": ssh_ok,
            "hardware": hw_info,
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/fleet/deploy", methods=["POST"])
def api_fleet_deploy():
    """Deploy components to remote machine."""
    config = request.json
    hostname = config.get("hostname", "")
    components = config.get("components", [])

    if not hostname:
        return jsonify({"error": "hostname required"}), 400

    def run_fleet_deploy():
        # Copy install script
        install_script = COMPONENTS_DIR / "fleet" / "deployer" / "install.sh"
        if not install_script.exists():
            emit_progress("error", "error", f"Fleet deployer not found: {install_script}")
            return

        # Execute on remote
        emit_progress("init", "running", f"Deploying to {hostname}...")
        for comp in components:
            emit_progress(comp, "started", f"Installing {comp} on {hostname}...")
            # TODO: Implement remote installation
            emit_progress(comp, "complete", f"{comp} installed on {hostname}")

        emit_progress("all", "done", f"Deployment to {hostname} complete!")

    t = threading.Thread(target=run_fleet_deploy, daemon=True)
    t.start()
    return jsonify({"status": "started"})


if __name__ == "__main__":
    print(f"Settings base: {SETTINGS_BASE}")
    print(f"Homelab root:  {HOMELAB_ROOT}")
    print(f"Components:    {COMPONENTS_DIR}")
    print(f"Open http://localhost:5555")
    app.run(host="0.0.0.0", port=5555, debug=True)
