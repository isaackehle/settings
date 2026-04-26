---
tags: [development]
---

# <img src="https://github.com/apple.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Xcode

Apple's developer tools. The Command Line Tools are required for many brew packages and compilers.

## Installation

```shell
xcode-select --install
```

Accept the license:

```shell
sudo xcodebuild -license accept
```

Point Xcode to the correct developer directory if the full Xcode app is installed:

```shell
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Configuration

No basic configuration required.

## Start / Usage

```shell
xcodebuild -version
```

## References

- [Xcode on the Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
