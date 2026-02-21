---
tags: [languages]
---

# Java

JVM language used for enterprise backends, Android, and cross-platform tooling. Managed via SDKMAN.

## Installation

```shell
# SDKMAN — manages Java, Kotlin, Gradle, and other JVM SDKs
curl -s "https://get.sdkman.io" | bash

sdk install java
```

### Maven

```shell
brew install maven
```

## Configuration

SDKMAN installs to `~/.sdkman/`. List available Java versions:

```shell
sdk list java
```

Switch the active version:

```shell
sdk use java 21.0.2-tem
sdk default java 21.0.2-tem
```

## Concepts

### Garbage Collection

- Runs in its own thread
- Heap sizing flags: `-Xms256m` (initial), `-Xmx1g` (max)
- `Runtime.maxMemory()` / `Runtime.totalMemory()`

### JSON operators (PostgreSQL context)

- `->` returns a JSON field as JSON
- `->>` returns a JSON field as text

## References

- [SDKMAN](https://sdkman.io/)
- [Java SE Downloads — Oracle](https://www.oracle.com/java/technologies/downloads/)
- [Java Essential Training — LinkedIn Learning](https://www.linkedin.com/learning/java-8-essential-training)
- [Installing Java on macOS via Homebrew](https://www.chrisjmendez.com/2018/10/14/how-to-install-java-on-osx-using-homebrew/)
