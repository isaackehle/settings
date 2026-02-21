---
tags: [infrastructure]
---

# <img src="https://github.com/gradle.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Gradle

Build automation tool for JVM projects (Java, Kotlin, Android). Supports multi-project builds and incremental compilation.

## Installation

```shell
brew install gradle
```

Or manage via SDKMAN (preferred for JVM projects):

```shell
sdk install gradle
```

## Usage

```shell
# Run all tests
./gradlew test

# Build the project
./gradlew build

# List available tasks
./gradlew tasks
```

## References

- [Gradle Documentation](https://gradle.org/docs/)
- [Structuring multi-project builds](https://docs.gradle.org/current/userguide/multi_project_builds.html)
