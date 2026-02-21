---
tags: [terminal]
---

# SSH

Secure Shell for encrypted remote connections.

## Installation

```shell
brew install openssh openssl openssl@1.1 ssh-copy-id
```

## Configuration

Generate a new key pair:

```shell
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Copy your public key to a remote host:

```shell
ssh-copy-id user@hostname
```

Add an entry to `~/.ssh/config` for quick access:

```
Host myserver
  HostName example.com
  User myuser
  IdentityFile ~/.ssh/id_ed25519
```

## References

- [OpenSSH](https://www.openssh.com/)
- [GitHub: Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
