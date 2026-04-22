---
tags: [setup]
---

# <img src="https://github.com/apple.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tweaks

macOS system enhancements, utilities, and productivity tools.

## Amphetamine

Prevents the Mac from sleeping. Available from the Mac App Store.

## Mouse & Input

### BetterTouchTool

Customize mouse buttons, gestures, and keyboard shortcuts.

```shell
brew install bettertouchtool
```

### SteerMouse

Advanced mouse driver with fine-grained configuration.

```shell
brew install --force steermouse
```

For scroll issues while middle-clicking: Wheel Mode → Ratchet, uncheck Smooth Scroll.

## CLI Tools

```shell
brew install tree pstree

brew install rename vim

brew install watch

```

## Network Drives

Prevent `.DS_Store` files from being written to network drives:

```shell
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```

## Cleanup & Performance

```shell
brew install ccleaner appcleaner
```

## Compression

```shell
brew install unrar the-unarchiver
```

## General Utilities

```shell
brew install alfred path-finder xquartz flux spectacle disk-inventory-x mounty controlplane
```

## Manual Installs

- Cisco AnyConnect
- [MenuMeters](https://ragingmenace.com/software/menumeters/)
- Microsoft Remote Desktop
- Microsoft Office
- Paragon NTFS

## Configuration

No basic configuration required.

## Start / Usage

Start: Open the app from Applications.
