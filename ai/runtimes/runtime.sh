# shellcheck shell=bash
# ==============================================
# RUNTIME DEFAULTS - Shared local AI runtime
# ==============================================
# DATA FILE — sourced by install/deploy/runtime scripts, never executed directly.
#
# Purpose:
# - Centralize llama.cpp runtime defaults outside of machine-specific profiles.
# - Keep performance tuning in one place instead of scattering flags across scripts.
# - Allow profiles to focus on model selection and role mapping, while this file
#   defines shared launch behavior for local runtimes.
#
# Notes:
# - These are conservative starting defaults for Apple Silicon + Metal.
# - Profile-specific overrides can be added later if needed.

PRIMARY_LOCAL_RUNTIME="llama.cpp"
SECONDARY_LOCAL_RUNTIME="ollama"
PREFERRED_LLAMA_CPP_BINARY="llama-server"
PREFERRED_LLAMA_CPP_CLI="llama-cli"
LLAMA_CPP_BACKEND="metal"

LLAMA_CPP_THREADS=10
LLAMA_CPP_THREADS_BATCH=10
LLAMA_CPP_GPU_LAYERS=999
LLAMA_CPP_BATCH=1024
LLAMA_CPP_UBATCH=512
LLAMA_CPP_FLASH_ATTN=1
LLAMA_CPP_CONT_BATCHING=1

LLAMA_CPP_TEMP=0.2
LLAMA_CPP_TOP_P=0.95
LLAMA_CPP_TOP_K=40
LLAMA_CPP_MIN_P=0.05
LLAMA_CPP_REPEAT_PENALTY=1.05

LLAMA_CPP_CTX_DEFAULT=8192
LLAMA_CPP_CTX_LARGE=32768
LLAMA_CPP_CTX_XL=131072

declare -A ROLE_CTX_DEFAULTS=(
    ["fast"]="32768"
    ["general"]="65536"
    ["coder"]="65536"
    ["heavy"]="65536"
    ["reasoning"]="65536"
    ["embedding"]="8192"
)

declare -A ROLE_BATCH_DEFAULTS=(
    ["fast"]="1024"
    ["general"]="1024"
    ["coder"]="1024"
    ["heavy"]="512"
    ["reasoning"]="512"
    ["embedding"]="1024"
)

declare -A ROLE_UBATCH_DEFAULTS=(
    ["fast"]="512"
    ["general"]="512"
    ["coder"]="512"
    ["heavy"]="256"
    ["reasoning"]="256"
    ["embedding"]="512"
)

LLAMA_SERVER_HOST="127.0.0.1"
LLAMA_SERVER_PORT_BASE=8010
LLAMA_SERVER_PARALLEL=2
LLAMA_SERVER_TIMEOUT=600
LLAMA_SERVER_METRICS=1

declare -A ROLE_PORTS=(
    ["fast"]="8011"
    ["general"]="8012"
    ["coder"]="8013"
    ["heavy"]="8014"
    ["reasoning"]="8015"
    ["embedding"]="8016"
)

ENABLE_OLLAMA_IMPORTS=1
ENABLE_OPENAI_COMPAT_SERVER=1
ENABLE_BENCHMARK_LOGGING=1
ENABLE_PROMPT_CACHE=1
ENABLE_PROFILE_VALIDATION=1

BENCHMARK_WARMUP_RUNS=1
BENCHMARK_MEASURE_RUNS=3
BENCHMARK_DEFAULT_PROMPT_TOKENS=512
BENCHMARK_DEFAULT_GEN_TOKENS=512
