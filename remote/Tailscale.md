---
tags: [apps, networking, vpn]
---

# <img src="https://github.com/tailscale.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tailscale

Zero-config VPN based on WireGuard. Connects all your machines into a single private network using MagicDNS and 100.x.y.z IPs. Already running on the current machine (`discovery`).

## Installation

```shell
brew install --cask tailscale
```

On Linux (Synology, voyager, etc.): follow the [platform-specific install docs](https://tailscale.com/download). Most distros use the static binary or package manager.

## Configuration

```shell
# Start Tailscale and authenticate
tailscale up

# Or for the Mac app
open /Applications/Tailscale.app
```

To join a specific users' network:

```shell
tailscale up --accept-routes
```

## Current Network

| Node           | IP              | OS      | Status            |
| -------------- | --------------- | ------- | ----------------- |
| `discovery`    | 100.91.217.6    | macOS   | ✅ Connected      |
| `voyager`      | 100.67.2.89     | Linux   | ✅ Connected      |
| `ds9`          | —               | macOS   | ❌ Needs setup    |
| `enterprise`   | —               | macOS   | ❌ Needs setup    |
| `synology`     | —               | DSM     | ❌ Needs setup    |

## Adding a New Machine to Tailscale

### macOS (DS9 / Enterprise)

```shell
# 1. Install
brew install --cask tailscale

# 2. Start and authenticate
tailscale up

# This opens a browser window to authenticate via Tailscale SSO.
# After auth, the node appears in your tailnet with a 100.x.y.z IP.

# 3. Verify
tailscale status
tailscale ip -4
```

The CLI binary path for macOS is:
```shell
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
```

### Synology NAS (DSM)

1. Open **Package Center** → search for **Tailscale** → install
2. Open the Tailscale app from the DSM desktop
3. Click **Connect** — this opens a browser to authenticate
4. After authentication, the Synology node appears in your tailnet

**Alternative — via Docker:**
```shell
# SSH into Synology, then:
docker run -d \
  --name=tailscale \
  --restart=unless-stopped \
  -v /var/lib/tailscale:/var/lib/tailscale \
  -v /dev/net/tun:/dev/net/tun \
  --network=host \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --env TS_AUTHKEY=<your-auth-key> \
  --env TS_STATE_DIR=/var/lib/tailscale \
  --env TS_USERSPACE=false \
  tailscale/tailscale
```

## Adding Nextcloud to the Tailnet

Once the Synology NAS is on Tailscale, Nextcloud is reachable via the Synology's **Tailscale IP** instead of the local LAN IP:

```shell
# After Synology is on Tailscale, find its IP:
# From any node:
ping synology   # MagicDNS if configured
# or use the 100.x.y.z IP

# Nextcloud URL becomes:
http://100.x.y.z:8080/nextcloud  # or whatever port/location you set up

# Update your Nextcloud client config to use the Tailscale IP/domain
# instead of the local LAN IP. This way it works from any Tailscale node.
```

## Usage

```shell
# Show status
tailscale status

# Show IPs
tailscale ip -4
tailscale ip -6

# Check connectivity to another node
ping 100.x.y.z

# Enable MagicDNS (macOS)
# Settings → Tailscale → DNS → "Use Tailscale DNS"

# Serve a local service via Tailscale (e.g., Open WebUI)
tailscale serve --bg --https=443 http://127.0.0.1:8080

# Check serve status
tailscale serve status

# Expose to the public internet (use with caution)
tailscale funnel --bg --https=443 http://127.0.0.1:8080
```

## References

- [Tailscale Download](https://tailscale.com/download)
- [Tailscale Docs](https://tailscale.com/docs/)
- [tailscale serve](https://tailscale.com/docs/reference/tailscale-cli/serve)
- [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel)
- [Synology Package](https://www.synology.com/en-us/dsm/packages/Tailscale)
