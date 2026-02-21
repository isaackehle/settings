---
tags: [security]
---

# Encryption

Cryptography and hashing tools.

## Installation

```shell
brew install mcrypt
brew install md5sha1sum
brew install mhash
```

## Usage

Generate an MD5 hash:

```shell
md5 filename
# or
echo -n "string" | md5
```

Generate a SHA256 hash:

```shell
shasum -a 256 filename
```

## References

- [OpenSSL](https://www.openssl.org/)
- [GnuPG](https://gnupg.org/)
