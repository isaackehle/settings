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
