# Terminal Sync & SSH Display Fixes

## The doubled-character problem

```
 s
s
sh ds9
sssh
sshh h
```

This is `STTY` corruption — the local terminal and remote shell are both echoing your
keystrokes. Usually happens after a broken SSH session, a tmux detach gone wrong, or
a `TERM` mismatch between client and server.

### Immediate fix (type blind if needed)

```bash
stty sane
```

or a full reset:

```bash
reset
```

If the terminal is so broken you can't type, close the tab and open a new one.

### Why it happens

| Cause | Symptom |
|---|---|
| Previous SSH session didn't close cleanly | Doubled echo on next login |
| `TERM` not recognized on remote machine | Garbled colors, cursor movement broken |
| Missing terminfo on remote (e.g. `xterm-ghostty` on DS9) | `tput` errors, prompt breaks |
| tmux on remote with wrong `TERM` | Everything doubled or invisible |
| Bluetooth keyboard packet loss (macOS) | Random repeated characters |

---

## Prevention: SSH config

Add to `~/.ssh/config` on all machines. Keeps `TERM` predictable and avoids
sending unknown terminal types that remote machines don't have terminfo for.

```
# ── Fleet machines ────────────────────────────────────────────────────────────
Host ds9
  HostName ds9.local
  User isaac
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
  SetEnv TERM=xterm-256color
  ServerAliveInterval 30
  ServerAliveCountMax 3

Host ds9-ts
  HostName 100.64.0.x          # fill in from: tailscale status
  User isaac
  IdentityFile ~/.ssh/id_ed25519
  SetEnv TERM=xterm-256color
  ServerAliveInterval 30
  ServerAliveCountMax 3

Host enterprise
  HostName enterprise.local
  User isaac
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
  SetEnv TERM=xterm-256color
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

`SetEnv TERM=xterm-256color` forces a safe, universally-supported terminal type
regardless of what your local terminal app calls itself (iTerm2 sends
`xterm-256color` anyway, but Ghostty sends `xterm-ghostty` which remotes don't have).

`ServerAliveInterval` / `ServerAliveCountMax` prevents the silent-drop that causes
the next session to have ghost echo.

---

## Prevention: install terminfo on remotes

If you use Ghostty locally, DS9 and enterprise need its terminfo or SSH will fall
back to a dumb terminal:

```bash
# On DS9 and enterprise (run from discovery):
ssh ds9 'infocmp xterm-ghostty' 2>/dev/null && echo "ok" || echo "missing"

# If missing, copy it over:
infocmp xterm-ghostty | ssh ds9 'mkdir -p ~/.terminfo && tic -x -'
infocmp xterm-ghostty | ssh enterprise 'mkdir -p ~/.terminfo && tic -x -'
```

---

## Syncing terminal settings across machines

The goal: same colors, same prompt rendering, same behavior everywhere.

### Shell config (already synced via settings repo)

Your `.zshrc` / `.zprofile` live in `isaackehle/settings` and get deployed to each
machine. Make sure each machine has the settings repo cloned and symlinked:

```bash
# Check
ls -la ~/.zshrc  # should be a symlink into ~/code/isaackehle/settings/
```

### STTY defaults (add to .zshrc / .zprofile)

```zsh
# Normalize terminal on every shell start
if [[ -t 0 ]]; then
  stty sane
  stty erase '^?' intr '^C' kill '^U' eof '^D' susp '^Z'
fi
```

### Consistent TERM in shell (add to .zshrc)

```zsh
# Force a safe TERM when SSHing in (remote doesn't know about xterm-ghostty)
if [[ -n "$SSH_CONNECTION" ]]; then
  export TERM=xterm-256color
fi
```

### tmux (if used): consistent TERM

In `~/.tmux.conf` on all machines:

```
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
```

---

## Quick reference: fix commands

| Problem | Command |
|---|---|
| Doubled characters | `stty sane` |
| Completely broken display | `reset` |
| Colors gone | `export TERM=xterm-256color` |
| Prompt not rendering | `source ~/.zshrc` |
| Check current STTY | `stty -a` |
| Check TERM | `echo $TERM` |
| Check terminfo exists | `tput colors` (should print `256`) |
