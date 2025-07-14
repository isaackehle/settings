# FNM - Fast Node Manager

## Installation

Documentation is at [Schniz/fnm](https://github.com/Schniz/fnm)

```shell
brew install nvm
```

```shell
❯ eval "$(fnm env)"

❯ fnm --version
fnm 1.38.1

❯ fnm install

Installing Node v18.20.8 (arm64)
00:00:02 █████████████████████████████████████████████████████████████████████████████████████████████████████▍ 19.70 MiB/19.81 MiB (5.10 MiB/s, 0s)

❯ fnm use
Using Node v18.20.8

fnm completions --shell zsh
eval "$(fnm env --use-on-cd --shell zsh)"

```
