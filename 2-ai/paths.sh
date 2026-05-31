# shellcheck shell=bash
# ==============================================
# PATH DEFAULTS - Shared local AI paths
# ==============================================
# DATA FILE — sourced by install/deploy/runtime scripts, never executed directly.
#
# Purpose:
# - Centralize model, cache, manifest, and binary paths outside of machine-
#   specific profiles.
# - Keep scripts portable by referencing these variables instead of hardcoded paths.
# - Separate source artifacts (HF downloads) from derived artifacts (GGUF, manifests).
#
# Notes:
# - Profile-relative generated output still uses MACHINE_PROFILE, but the path
#   contract itself lives at the top-level AI layer.

AI_BASE="${SETTINGS_BASE}/2-ai"
PROFILE_DIR="${AI_BASE}/profiles/${MACHINE_PROFILE}"
PROFILE_GENERATED_DIR="${PROFILE_DIR}/generated"
PROFILE_MANIFEST_DIR="${PROFILE_DIR}/manifests"
PROFILE_TMP_DIR="${PROFILE_DIR}/tmp"

MODEL_STORE="${HOME}/Models"
HF_CACHE_DIR="${HOME}/.cache/huggingface"
HF_SRC_DIR="${MODEL_STORE}/hf"
GGUF_DIR="/usr/local/lib/llama-models"
MODEL_LOG_DIR="${MODEL_STORE}/logs"
MODEL_TMP_DIR="${MODEL_STORE}/tmp"

OLLAMA_MODEL_DIR="${HOME}/.ollama/models"
LLAMA_CPP_BUILD_DIR="${HOME}/code/llama.cpp"
LLAMA_CPP_BIN_DIR="${LLAMA_CPP_BUILD_DIR}/build/bin"

HF_MODEL_MANIFEST="${PROFILE_MANIFEST_DIR}/hf-models.tsv"
GGUF_MODEL_MANIFEST="${PROFILE_MANIFEST_DIR}/gguf-models.tsv"
MODEL_MAP_LLAMA_CPP="${PROFILE_GENERATED_DIR}/model-map-llama-cpp.md"
MODEL_MAP="${PROFILE_GENERATED_DIR}/model-map.md"
BENCHMARK_RESULTS_DIR="${PROFILE_GENERATED_DIR}/benchmarks"

HF_CLI_BIN="${HF_CLI_BIN:-hf}"
LLAMA_CONVERT_BIN="${LLAMA_CPP_BUILD_DIR}/convert_hf_to_gguf.py"
# Prefer Homebrew binaries if available (brew install llama.cpp),
# fall back to local build under LLAMA_CPP_BIN_DIR.
_llama_bin() { command -v "$1" 2>/dev/null || echo "${LLAMA_CPP_BIN_DIR}/$1"; }
LLAMA_QUANTIZE_BIN="${LLAMA_QUANTIZE_BIN:-$(_llama_bin llama-quantize)}"
LLAMA_CLI_BIN="${LLAMA_CLI_BIN:-$(_llama_bin llama-cli)}"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$(_llama_bin llama-server)}"
unset -f _llama_bin
OLLAMA_BIN="${OLLAMA_BIN:-ollama}"
VALIDATE_PROFILE_BIN="${AI_BASE}/validate-profile.sh"

ensure_profile_paths() {
    mkdir -p \
        "${PROFILE_GENERATED_DIR}" \
        "${PROFILE_MANIFEST_DIR}" \
        "${PROFILE_TMP_DIR}" \
        "${HF_SRC_DIR}" \
        "${GGUF_DIR}" \
        "${MODEL_LOG_DIR}" \
        "${MODEL_TMP_DIR}" \
        "${BENCHMARK_RESULTS_DIR}"
}
