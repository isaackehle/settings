# GitHub SSH Key Setup

Do this on each machine that needs to push to `isaackehle/homelab` or `isaackehle/settings`.
Each machine gets its own key — don't copy private keys between machines.

---

## 1. Check for an existing key

```bash
ls ~/.ssh/id_ed25519.pub 2>/dev/null && echo "key exists" || echo "no key"
```

If a key exists and you want to reuse it, skip to step 3.

---

## 2. Generate a new key

```bash
ssh-keygen -t ed25519 -C "isaac@kehle.org ($(scutil --get ComputerName))"
# Accept the default path (~/.ssh/id_ed25519)
# Set a passphrase (recommended) or leave empty
```

---

## 3. Add to macOS keychain (survives reboots)

```bash
# Add to ssh-agent + keychain so you don't re-enter the passphrase
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Create or edit `~/.ssh/config` to load it automatically:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

```bash
# Apply it now
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## 4. Add the public key to GitHub

```bash
# Copy to clipboard
cat ~/.ssh/id_ed25519.pub | pbcopy
```

Then:
1. Go to **github.com → Settings → SSH and GPG keys → New SSH key**
2. Title: name it after the machine (e.g. `discovery`, `DS9`, `enterprise`)
3. Key type: **Authentication Key**
4. Paste and save

---

## 5. Test

```bash
ssh -T git@github.com
# Expected: "Hi isaackehle! You've successfully authenticated..."
```

---

## 6. Set remote to SSH (if you cloned via HTTPS)

```bash
cd ~/code/isaackehle/homelab
git remote set-url origin git@github.com:isaackehle/homelab.git

cd ~/code/isaackehle/settings
git remote set-url origin git@github.com:isaackehle/settings.git
```

---

## Per-machine notes

| Machine    | When to set up | Notes |
|------------|---------------|-------|
| discovery  | Before running `homelab-migrate.sh` | Primary — needs push access |
| DS9        | After cloning homelab | Headless: run steps 1–5 over SSH into DS9 |
| enterprise | After cloning homelab | Normal laptop setup |
| DX1        | Optional | Rarely used for git work |

**DS9 headless setup** — SSH into DS9 from discovery, then run steps 1–5:

```bash
ssh isaac@ds9.local
# then follow steps 1–5 above inside that session
```

---

## Copying SSH keys between fleet machines

So you can SSH from one machine to another without a password. Run these from **discovery**.

### First-time (password auth must still work)

```bash
# Copy discovery's public key to each machine
ssh-copy-id isaac@ds9.local
ssh-copy-id isaac@enterprise.local
ssh-copy-id isaac@dx1.local
```

This appends `~/.ssh/id_ed25519.pub` to `~/.ssh/authorized_keys` on the target.
You'll be prompted for the target machine's login password once.

### Test passwordless access

```bash
ssh isaac@ds9.local "echo ok"
ssh isaac@enterprise.local "echo ok"
```

### Add SSH config aliases (optional but handy)

Append to `~/.ssh/config` on discovery:

```
Host ds9
  HostName ds9.local
  User isaac
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes

Host enterprise
  HostName enterprise.local
  User isaac
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
```

Then you can just `ssh ds9` or `ssh enterprise`.

### Over Tailscale (when not on the same LAN)

```bash
# Use Tailscale IPs instead of .local hostnames
ssh-copy-id isaac@100.64.0.x    # DS9's Tailscale IP
ssh isaac@100.64.0.x "echo ok"
```

Or after adding Tailscale hostnames to `~/.ssh/config`:

```
Host ds9-ts
  HostName 100.64.0.x   # fill in from: tailscale status
  User isaac
  IdentityFile ~/.ssh/id_ed25519
```

### Enable SSH on macOS targets (if not already on)

On each target machine (GUI or remote):

```bash
# Check current state
sudo systemsetup -getremotelogin

# Enable
sudo systemsetup -setremotelogin on

# Or via System Settings → General → Sharing → Remote Login
```
