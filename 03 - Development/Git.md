---
tags: [development]
---

# <img src="https://github.com/git.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Git

Version control system. The `gh` CLI and GUI tools make GitHub workflows faster.

## Installation

```shell
# GitHub CLI
brew install gh
gh auth login

# GUI tools
brew install github-desktop
brew install sourcetree
```

## Configuration

Set identity in `~/.gitconfig`:

```shell
git config --global user.name "Your Name"
git config --global user.email "youremail@yourdomain.com"
```

Set the default editor for Git commit messages in your shell profile:

```shell
# Choose one
export GIT_EDITOR="windsurf-fed --wait"

# Alternatives
# export GIT_EDITOR="code --wait"
# export GIT_EDITOR="hx"
```

If you want to use the `windsurf` command name, create a symlink to one app variant:

```shell
# Regular Windsurf
sudo rm -f /usr/local/bin/windsurf
sudo ln -s "/Applications/Windsurf.app/Contents/Resources/app/bin/windsurf" /usr/local/bin/windsurf

# Windsurf Fed
sudo rm -f /usr/local/bin/windsurf
sudo ln -s "/Applications/Windsurf - Fed.app/Contents/Resources/app/bin/windsurf-fed" /usr/local/bin/windsurf
```

Or set the editor directly in `~/.gitconfig`:

```ini
[core]
  editor = hx
```

### Aliases

Add to `~/.gitconfig` under `[alias]`:

```ini
[alias]
  hist  = log --graph --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)<%an>%Creset' --abbrev-commit
  s     = status
  co    = checkout
  d     = diff
  br    = branch
  last  = log -1 HEAD
  lo    = log --oneline -n 10
  ec    = config --global -e
  up    = !git pull --rebase --prune $@ && git submodule update --init --recursive
  cob   = checkout -b
  cm    = !git add -A && git commit -m
  save  = !git add -A && git commit -m 'SAVEPOINT'
  wip   = !git add -u && git commit -m "WIP"
  undo  = reset HEAD~1 --mixed
  amend = commit -a --amend
  cane  = commit --amend --no-edit
  wipe  = !git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard
  pr    = pull --rebase
  fp    = fetch --prune
  pf    = push --force
  bclean = "!f() { git branch --merged ${1-master} | grep -v \" ${1-master}$\" | xargs git branch -d; }; f"
  bdone  = "!f() { git checkout ${1-master} && git up && git bclean ${1-master}; }; f"
	rebase-new = "!f() { git rebase --onto \"$1\" HEAD~1 HEAD && git checkout -B \"$2\"; }; f"
```

## Start / Usage

```shell
git status
```

## References

- [gh CLI](https://cli.github.com/)
- [GitHub Flow aliases](https://haacked.com/archive/2014/07/28/github-flow-aliases/)
- [Git aliases guide](https://victorzhou.com/blog/git-aliases/)
