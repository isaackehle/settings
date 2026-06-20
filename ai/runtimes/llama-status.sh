#!/usr/bin/env bash
# llama-status — quick diagnostic for llama-server router + Hermes
set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          🦙  Inference Server Status             ║"
echo "╚══════════════════════════════════════════════════╝"

# ── llama-server router ──
ROUTER_PID=$(pgrep -f "llama-server.*models-preset" 2>/dev/null || true)
if [ -n "$ROUTER_PID" ]; then
    ROUTER_UPTIME=$(ps -o etime= -p "$ROUTER_PID" 2>/dev/null | xargs)
    printf "${GREEN}✓${NC} llama-server router  PID %s  up %s\n" "$ROUTER_PID" "$ROUTER_UPTIME"
else
    printf "${RED}✗${NC} llama-server router  NOT RUNNING\n"
fi

# ── Model child process (currently loaded) ──
MODEL_PID=$(pgrep -f "llama-server.*--alias.*--model" 2>/dev/null || true)
if [ -n "$MODEL_PID" ]; then
    MODEL_ALIAS=$(ps -o args= -p "$MODEL_PID" 2>/dev/null | sed -n 's/.*--alias \([^ ]*\).*/\1/p')
    MODEL_MEM=$(ps -o rss= -p "$MODEL_PID" 2>/dev/null | awk '{printf "%.1f GB", $1/1048576}')
    MODEL_CPU=$(ps -o pcpu= -p "$MODEL_PID" 2>/dev/null | xargs)
    printf "${GREEN}◈${NC} loaded model:      ${CYAN}%s${NC}  %s  CPU %s%%\n" "$MODEL_ALIAS" "$MODEL_MEM" "$MODEL_CPU"
else
    printf "${YELLOW}○${NC} no model loaded (idle)\n"
fi

# ── Port check ──
if lsof -i :10000 -P 2>/dev/null | grep -q LISTEN; then
    printf "${GREEN}✓${NC} port :10000        listening\n"
else
    printf "${RED}✗${NC} port :10000        NOT LISTENING\n"
fi

# ── Ollama ──
if pgrep -x ollama >/dev/null 2>&1; then
    printf "${YELLOW}⚠${NC} Ollama            STILL RUNNING (was supposed to be killed)\n"
else
    printf "${GREEN}✓${NC} Ollama            dead\n"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          🤖  Hermes Status                       ║"
echo "╚══════════════════════════════════════════════════╝"

# ── Hermes process ──
HERMES_PID=$(pgrep -f "hermes-agent/venv/bin/hermes" 2>/dev/null || true)
if [ -n "$HERMES_PID" ]; then
    HERMES_CPU=$(ps -o pcpu= -p "$HERMES_PID" 2>/dev/null | xargs)
    printf "${GREEN}✓${NC} Hermes running    PID %s  CPU %s%%\n" "$HERMES_PID" "$HERMES_CPU"
else
    printf "${YELLOW}○${NC} Hermes            not currently running (daemon may be idle)\n"
fi

# ── Hermes config model setting ──
if [ -f ~/.hermes/config.yaml ]; then
    HERMES_MODEL=$(grep -A1 '^model:' ~/.hermes/config.yaml | grep 'default:' | sed 's/.*default: *//')
    HERMES_PROVIDER=$(grep '^  provider:' ~/.hermes/config.yaml 2>/dev/null | head -1 | sed 's/.*provider: *//')
    HERMES_URL=$(grep 'base_url:' ~/.hermes/config.yaml | head -1 | sed 's/.*base_url: *//')
    printf "${GREEN}✓${NC} model:  ${CYAN}%s${NC}\n" "$HERMES_MODEL"
    printf "${GREEN}✓${NC} route:  %s → %s\n" "$HERMES_PROVIDER" "$HERMES_URL"
else
    printf "${RED}✗${NC} no ~/.hermes/config.yaml\n"
fi

# ── Hermes config version ──
CFG_VER=$(grep '_config_version' ~/.hermes/config.yaml 2>/dev/null | sed 's/.*: //')
printf "${YELLOW}i${NC} config version    %s (latest: 29)\n" "$CFG_VER"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          📡  Router API Check                     ║"
echo "╚══════════════════════════════════════════════════╝"

# ── Simple API health check ──
API_RESP=$(python3 -c "
import urllib.request, json
try:
    req = urllib.request.Request('http://localhost:10000/v1/models', method='GET')
    resp = urllib.request.urlopen(req, timeout=3)
    data = json.loads(resp.read())
    models = [m['id'] for m in data['data'] if ':' not in m['id']]
    print(f'ok|{len(models)}')
except Exception as e:
    print(f'err|{e}')
" 2>/dev/null)

API_STATUS="${API_RESP%%|*}"
API_COUNT="${API_RESP##*|}"

if [ "$API_STATUS" = "ok" ]; then
    printf "${GREEN}✓${NC} API responds       %s model aliases registered on :10000\n" "$API_COUNT"
else
    printf "${RED}✗${NC} API unreachable    ${API_RESP#err|}\n"
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║          📋  Quick Logs                           ║"
echo "╚══════════════════════════════════════════════════╝"
echo "  Router out:  tail -50 ~/Library/Logs/llama-router/llama-router.out.log"
echo "  Router err:  tail -50 ~/Library/Logs/llama-router/llama-router.err.log"
echo "  Hermes:      tail -50 ~/.hermes/logs/gateway.log"
echo "  Hermes diag: hermes doctor"
echo ""
