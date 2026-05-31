# Open WebUI as a Multi-Backend Frontend

Open WebUI on this Mac is the **single chat interface**; it routes to three
**independent** model backends you pick between per chat:

| Backend | Runs where | Reachable from container at | Auth |
|---|---|---|---|
| **llama-server router** | native on Mac, port **10000** | `http://host.docker.internal:10000/v1` | `sk-local` (any non-empty) |
| **Ollama** | native on Mac, port **11434** | `http://host.docker.internal:11434` | none |
| **OpenRouter** | cloud | `https://openrouter.ai/api/v1` | `OPENROUTER_API_KEY` |

Open WebUI runs in Docker under **Colima** (active context:
`unix:///Users/isaac/.colima/default/docker.sock`). Port 8080 on the Mac is the
Colima SSH forward fronting the container — that's why it's "ssh" in `lsof`.

Each backend is isolated: if llama-server is down, Ollama and OpenRouter still
work. The per-chat model dropdown shows models from all connected backends.

---

## 0. Prerequisites on the host

### llama-server router — port 10000
Started by the LaunchAgent (`org.kehle.llama-router.plist`). Verify:
```bash
curl -s http://127.0.0.1:10000/v1/models | jq '.data[].id'
# deepseek-r1-32b  qwen3-4b-it  qwen3-coder-30b
```

### Ollama — make it reachable from the container (IMPORTANT)
Native Ollama binds to `127.0.0.1:11434` by default, so a container **cannot**
reach it via `host.docker.internal`. Bind it to all interfaces:

```bash
# Tell the macOS Ollama app/service to listen on all interfaces
launchctl setenv OLLAMA_HOST "0.0.0.0:11434"
# If you run the app: quit & relaunch Ollama. If via `ollama serve`, restart it:
#   OLLAMA_HOST=0.0.0.0:11434 ollama serve
# Persist for your shell too:
echo 'export OLLAMA_HOST=0.0.0.0:11434' >> ~/.zshrc
```
Security note: `0.0.0.0` exposes Ollama to your LAN. Since you favor local-only,
prefer restricting access at the firewall (macOS Application Firewall / pf) or
bind to the Colima bridge IP instead of `0.0.0.0`, and reach it remotely only
over Tailscale. Confirm models later with `ollama list`.

### OpenRouter key
Lives in `~/.env.local` as `OPENROUTER_API_KEY`. We pass it into the container
at launch (below) so it isn't typed into the UI.

---

## 1. Recommended `docker run` (Colima) — passes the key in, adds host gateway

Stop/remove the old container first if you're replacing it:
```bash
export DOCKER_HOST="unix:///Users/isaac/.colima/default/docker.sock"
docker stop open-webui 2>/dev/null; docker rm open-webui 2>/dev/null
```

Launch with all three backends pre-wired:
```bash
export DOCKER_HOST="unix:///Users/isaac/.colima/default/docker.sock"
# Load the OpenRouter key from ~/.env.local into this shell
set -a; source ~/.env.local; set +a

docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  --add-host=host.docker.internal:host-gateway \
  -e ENABLE_OLLAMA_API=true \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e OPENAI_API_BASE_URLS="http://host.docker.internal:10000/v1;https://openrouter.ai/api/v1" \
  -e OPENAI_API_KEYS="sk-local;${OPENROUTER_API_KEY}" \
  -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:main
```

Key points:
- `OPENAI_API_BASE_URLS` / `OPENAI_API_KEYS` are **semicolon-separated lists** —
  index-aligned. Here index 0 = llama-server (`sk-local`), index 1 = OpenRouter.
- `--add-host=host.docker.internal:host-gateway` guarantees the hostname
  resolves to your Mac from inside the container (don't rely on it implicitly).
- Ollama gets its own native connection via `OLLAMA_BASE_URL`.
- The key is sourced from `~/.env.local` and never written to disk in the
  command. (It will be visible in `docker inspect`'s env — acceptable for a
  local box; if you want it out of inspect too, add it via the UI instead.)

If you'd rather not bake URLs into env, omit the `-e OPENAI_*`/`-e OLLAMA_*`
lines and add all three in the UI (next section) — the UI stores them in the
app DB.

---

## 2. Add/verify backends in the UI

Settings → Admin Settings → **Connections**.

### OpenAI-type connections (llama-server + OpenRouter)
- **llama-server**: Base URL `http://host.docker.internal:10000/v1`, key `sk-local`
- **OpenRouter**: Base URL `https://openrouter.ai/api/v1`, key = your real key

### Ollama connection
- Under the **Ollama** section: `http://host.docker.internal:11434`

Click the refresh/verify icon on each. Models from every connected backend then
appear together in the chat model dropdown.

---

## 3. Verify connectivity from inside the container

```bash
export DOCKER_HOST="unix:///Users/isaac/.colima/default/docker.sock"

# llama-server router
docker exec open-webui sh -c \
  'wget -qO- http://host.docker.internal:10000/v1/models' | head -c 300; echo

# Ollama (after OLLAMA_HOST=0.0.0.0)
docker exec open-webui sh -c \
  'wget -qO- http://host.docker.internal:11434/api/tags' | head -c 300; echo

# OpenRouter (cloud)
docker exec open-webui sh -c \
  'wget -qO- https://openrouter.ai/api/v1/models' | head -c 200; echo
```
Empty/refused on llama-server → router not running. Refused on Ollama → it's
still bound to 127.0.0.1 (set `OLLAMA_HOST=0.0.0.0:11434` and restart it).

---

## 4. Using the backends

- **Model dropdown** lists everything: `deepseek-r1-32b`, `qwen3-4b-it`,
  `qwen3-coder-30b` (llama-server), your pulled Ollama tags, and OpenRouter
  models (e.g. `anthropic/claude-...`, `google/gemini-...`).
- Pick a different backend's model per chat — fully independent.
- **Cold-load**: first hit to a llama-server model loads it (a few seconds for
  the 30B/32B; instant for 4B). With `--models-max 1` switching reloads; raise
  to 2 to keep the 4B warm alongside a big model (see tuning-guide.md §4).
- DeepSeek-R1 `<think>` blocks are auto-collapsed by recent Open WebUI.

### Optional: filter the OpenRouter model list
OpenRouter exposes hundreds of models. To limit which appear, set in the UI
(Connections → OpenRouter → advanced) or via env
`OPENAI_API_CONFIGS`, or just star your favorites in the model manager.

---

## 5. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| llama-server models missing | Router down, or wrong URL. From container use `host.docker.internal:10000`, not `127.0.0.1`. |
| Ollama connection fails | Ollama bound to 127.0.0.1. Set `OLLAMA_HOST=0.0.0.0:11434`, restart Ollama. |
| `host.docker.internal` won't resolve | Ensure `--add-host=host.docker.internal:host-gateway` on `docker run`; else use the Mac's LAN/Tailscale IP. |
| OpenRouter 401 | Key not passed. Check `${OPENROUTER_API_KEY}` was sourced, or paste key in UI. |
| Port 8080 "ssh" in lsof | Normal for Colima — it's the VM port-forward, not a problem. |
| Want localhost-only Open WebUI | Publish as `-p 127.0.0.1:8080:8080` and reach remotely via Tailscale. |

---

## Security posture (your network)

- **Bind tight, tunnel for remote.** Prefer `127.0.0.1`-only publishes for
  Open WebUI and the router; reach them from other devices over **Tailscale**,
  not by exposing `0.0.0.0` on the LAN.
- **Ollama on `0.0.0.0`** is the one unavoidable LAN exposure for this design.
  Constrain it with the macOS firewall / pf to the Colima bridge subnet only,
  or bind Ollama to the specific host-gateway IP rather than all interfaces.
- **OpenRouter key** stays in `~/.env.local`; sourced at container start. It is
  the one cloud dependency — everything else is local-control.

---

## 6. Tailscale: remote access, cross-Mac backends, and Funnel

This section makes the stack reachable over your tailnet and ready for the
**Mac mini** when it joins. macOS note: you have the **Tailscale.app** build
(`/Applications/Tailscale.app/Contents/MacOS/Tailscale`). For Serve/Funnel via
CLI you need the **App Store or Standalone** variant (the GUI-only build can't
share ports). Add the CLI to your shell:

```bash
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
# Resolve your tailnet identity (used throughout below):
tailscale status                     # shows this host's MagicDNS name + 100.x IP
THIS_TS_NAME=$(tailscale status --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')
echo "$THIS_TS_NAME"                  # e.g. discovery.<tailnet>.ts.net
```

Design reminder: llama-server (10000) and Ollama (11434) run on the **same Mac**
as the Open WebUI container, so the container always reaches them via
`host.docker.internal` — Tailscale is **not** in that path. Tailscale's jobs
here are (a) letting you reach the **web UI** remotely, and (b) letting Open
WebUI use a **different Mac's** backend.

---

### 6a. Remote access to the Open WebUI web UI (Serve — tailnet-only, recommended)

Expose the 8080 UI to your tailnet over HTTPS, without opening it on the LAN:

```bash
# Persist in the background; serves https://<this-host>.<tailnet>.ts.net -> 127.0.0.1:8080
tailscale serve --bg --https=443 http://127.0.0.1:8080
tailscale serve status            # confirm the mapping
```

Then from any tailnet device (phone, laptop): open
`https://discovery.<tailnet>.ts.net`. You get a real HTTPS cert, tailnet-only
access, and Tailscale identity headers — far safer than `-p 0.0.0.0:8080`.

Pair this with a localhost-only container publish so 8080 is never on the LAN:

```bash
# in your docker run:  -p 127.0.0.1:8080:8080
```

To remove: `tailscale serve --https=443 off`  (or `tailscale serve reset`).

---

### 6b. Cross-Mac backends (the Mac mini, once on the tailnet)

When the mini joins, you can run a backend on one Mac and consume it from Open
WebUI on the other. Two pieces:

**On the backend host (e.g. the mini running Ollama or llama-server):**
Tailscale gives every node a stable `100.x.y.z` IP and MagicDNS name. Bind the
service so the tailnet can reach it, but NOT the wider LAN:

```bash
# Ollama: bind to the Tailscale IP only (not 0.0.0.0)
MINI_TS_IP=$(tailscale ip -4)
OLLAMA_HOST="${MINI_TS_IP}:11434" ollama serve
#   …or for llama-server router on the mini:
#   llama-server --models-preset /usr/local/lib/llama-models/models.ini --host "$MINI_TS_IP" --port 10000
```

**In Open WebUI (on the M5 Max), add the mini as extra connections** — by
MagicDNS name so it survives IP changes:

| Backend on mini | Open WebUI connection type | Base URL |
|---|---|---|
| Ollama | Ollama | `http://mini.<tailnet>.ts.net:11434` |
| llama-server | OpenAI | `http://mini.<tailnet>.ts.net:10000/v1`  (key `sk-local`) |

Now one Open WebUI lists models from **both** Macs plus OpenRouter, each picked
per chat. Same idea in reverse if the mini runs its own Open WebUI.

Security: prefer binding cross-Mac backends to the **Tailscale interface IP**
(above) rather than `0.0.0.0`, and lock them down with an ACL (§6d) so only
your devices — or a tagged group — can reach the LLM ports across the tailnet.

---

### 6c. Tailscale Funnel — PUBLIC internet exposure (use with caution)

Funnel publishes a service to the **entire public internet** over HTTPS. Only
do this for the **Open WebUI app** (which has its own login), NEVER for the raw
llama-server or Ollama APIs — those have no authentication.

Hard constraints (from Tailscale):
- Funnel listens on **only ports 443, 8443, or 10000**.
- **Port-number collision warning:** your llama-server router uses **10000**.
  Do not `funnel 10000` — that would expose the unauthenticated model API. Use
  **443** for the Open WebUI Funnel.
- Requires MagicDNS + HTTPS certs + a `funnel` nodeAttr in your ACL policy
  (the CLI prompts to add it on first run), and the App Store/Standalone build.
- A port is either Serve (private) or Funnel (public) — last command wins.

Expose ONLY the authenticated Open WebUI UI:

```bash
# Public HTTPS on 443 -> the Open WebUI container on 127.0.0.1:8080
tailscale funnel --bg --https=443 http://127.0.0.1:8080
tailscale funnel status
# Reachable at: https://discovery.<tailnet>.ts.net  (public)
```

Before enabling Funnel, harden Open WebUI:
- Enforce sign-up disabled + strong admin password (`ENABLE_SIGNUP=false`).
- Consider `WEBUI_AUTH=true` (default) and a strong `WEBUI_SECRET_KEY`.
- Ideally keep an auth proxy / SSO in front. Funnel traffic carries **no**
  Tailscale identity headers — anyone with the URL hits your login page.

Disable: `tailscale funnel --https=443 off`.

---

### 6d. ACL hardening (defense in depth)

In the Tailscale admin console policy file, restrict who can reach the LLM
ports across the tailnet. Example: tag the Macs and allow only your user group
to reach the model ports.

```jsonc
// tailnet policy (Access controls). Adjust users/tags to your tailnet.
{
  "tagOwners": { "tag:llm-host": ["autogroup:admin"] },
  "acls": [
    // Your devices may reach Open WebUI, llama-server, Ollama on the LLM hosts
    {
      "action": "accept",
      "src":    ["autogroup:member"],
      "dst":    ["tag:llm-host:8080", "tag:llm-host:10000", "tag:llm-host:11434"]
    }
  ],
  // Only enable Funnel for the specific node(s) you intend to expose publicly
  "nodeAttrs": [
    { "target": ["tag:llm-host"], "attr": ["funnel"] }
  ]
}
```

Tag the Macs with `tag:llm-host` (admin console → Machines → edit tags, or
`tailscale up --advertise-tags=tag:llm-host`). With this in place, even on
`0.0.0.0` binds the tailnet ACL gates access to your devices only.

---

### 6e. Quick decision guide

| Goal | Use | Port |
|---|---|---|
| Reach Open WebUI from my phone on the tailnet | Serve | 443 |
| Open WebUI on M5 Max uses the mini's models | Cross-Mac backend + MagicDNS | 11434 / 10000 |
| Share Open WebUI with someone NOT on my tailnet | Funnel (UI only, hardened) | 443 |
| Never do this | Funnel the raw model API | ~~10000~~ |

Sources: [tailscale serve](https://tailscale.com/docs/reference/tailscale-cli/serve),
[Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel),
[Funnel examples](https://tailscale.com/docs/reference/examples/funnel).
