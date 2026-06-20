# Network Responsiveness & Wake on Demand

Keeping fleet machines reachable over Tailscale and waking them when sleeping.

---

## Wake on LAN (WoL)

Lets a machine that is shut down or sleeping power on in response to a "magic packet" sent over the network.

### Enable on each machine

**macOS System Settings:**
```
System Settings → General → Sharing → (scroll down) → Allow network access to wake this Mac
```

Or via CLI:
```bash
sudo pmset -a womp 1        # enable WoL on ethernet
sudo pmset -a acwake 1      # wake on AC power connect (useful for DS9)
```

Verify:
```bash
pmset -g | grep -E "womp|acwake"
```

### Find the MAC address (needed to send the magic packet)

```bash
# On the target machine:
ifconfig en0 | grep ether     # Ethernet
ifconfig en1 | grep ether     # Wi-Fi (less reliable for WoL)
```

### Send a magic packet (from discovery or any machine on LAN)

```bash
brew install wakeonlan
wakeonlan <MAC_ADDRESS>

# Or with explicit broadcast:
wakeonlan -i 192.168.1.255 <MAC_ADDRESS>
```

**WoL only works on the local LAN** — the packet can't cross NAT. For remote wake, use Tailscale + a local helper (see below).

---

## Keeping macOS Awake for Network Requests

### Prevent sleep while on power

```bash
# Keep awake indefinitely (until you cancel with Ctrl-C):
caffeinate -s

# Keep awake for 8 hours:
caffeinate -t 28800

# Run a command and stay awake while it runs:
caffeinate -s <command>
```

### System Settings approach (persistent)

```
System Settings → Battery → Options → Prevent automatic sleeping on power adapter when display is off ✓
System Settings → Lock Screen → Turn display off on power adapter → Never (for always-on servers like DS9)
```

Via CLI (persistent across reboots):
```bash
sudo pmset -c sleep 0          # disable sleep on AC power
sudo pmset -c displaysleep 10  # display can sleep, system stays up
sudo pmset -c disksleep 0      # keep disks awake
```

Verify:
```bash
pmset -g
```

### DS9 recommended settings (headless always-on)

```bash
sudo pmset -c sleep 0
sudo pmset -c displaysleep 0
sudo pmset -c disksleep 0
sudo pmset -c womp 1
sudo pmset -c acwake 1
sudo pmset -c powernap 1       # allow background tasks while display off
```

---

## Remote Wake via Tailscale

WoL magic packets don't cross the internet, but you can route them through a relay:

### Option 1: SSH into a LAN machine first, then WoL

```bash
# From anywhere via Tailscale:
ssh discovery
wakeonlan <DS9_MAC>        # DS9 and discovery are on the same LAN
```

### Option 2: Tailscale + Home Assistant automation

If DS9 or enterprise are on the same LAN as a Home Assistant instance, use the `wake_on_lan` integration:

```yaml
# configuration.yaml
wake_on_lan:   # enable the integration

switch:
  - platform: wake_on_lan
    name: "DS9"
    mac: "AA:BB:CC:DD:EE:FF"
    host: ds9.local            # used to check if awake
    turn_off:
      service: shell_command.sleep_ds9

shell_command:
  sleep_ds9: "ssh isaac@ds9.local 'sudo pmset sleepnow'"
```

Then you can wake DS9 from the HA dashboard or via a Tailscale-accessible HA API call from anywhere.

### Option 3: Always-on machine as relay

Keep DS9 set to never sleep. Use DS9 as a jump host or relay for waking enterprise/DX1 via WoL, since DS9 is always reachable over Tailscale.

---

## SSH Keep-Alive (prevent dropped connections)

Already handled by `config/ssh_config` in this repo:

```
ServerAliveInterval 30
ServerAliveCountMax 3
```

This sends a keepalive every 30s and drops the connection after 3 missed responses (~90s) rather than hanging forever.

---

## Checking machine status

```bash
# Is it awake and on Tailscale?
tailscale ping ds9

# Full fleet status:
tailscale status

# Is llama-swap responding?
curl -sf http://ds9:10000/health && echo "up" || echo "down"
```

---

## Fleet wake policy

| Machine    | Sleep policy         | Rationale                                      |
|------------|---------------------|------------------------------------------------|
| discovery  | Never sleep (AC)    | Primary workstation + LLM gateway              |
| DS9        | Never sleep (AC)    | Headless always-on server                      |
| enterprise | Default macOS sleep | Laptop — battery matters; wake manually        |
| DX1        | Default macOS sleep | Rarely used; no local inference                |
