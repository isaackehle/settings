---
tags: [databases]
---

# Apache HTTP Server

Open-source web server. On macOS, it can be installed via Homebrew.

## Installation

```shell
brew install httpd
```

Supporting libraries:

```shell
brew install apr apr-util
```

## Configuration

The main config file is at:

```
/opt/homebrew/etc/httpd/httpd.conf
```

Start/stop:

```shell
brew services start httpd
brew services stop httpd
```

## References

- [Apache HTTP Server Documentation](https://httpd.apache.org/docs/)
