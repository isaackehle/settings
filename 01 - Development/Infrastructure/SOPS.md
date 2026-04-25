---
tags: [infrastructure]
---

# <img src="https://github.com/getsops.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> SOPS

Secrets Operations — encrypts values in YAML, JSON, ENV, and INI files using AWS KMS, GCP KMS, Azure Key Vault, or PGP. Used for storing secrets alongside Helm deployments.

## Installation

```shell
brew install sops
```

## Configuration

Set your preferred editor (used when running `sops <file>`):

```shell
export EDITOR='code -w'
```

Add to `~/.zshrc` to persist it.

## Usage

```shell
# Encrypt a file
sops --encrypt secrets.yaml > secrets.enc.yaml

# Edit encrypted file in-place
sops secrets.enc.yaml

# Decrypt to stdout
sops --decrypt secrets.enc.yaml
```

## References

- [SOPS on GitHub](https://github.com/getsops/sops)
