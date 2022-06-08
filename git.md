# GIT

## CLI

```bash
brew install gh
gh auth login
```

## Set username and email in .gitconfig

```bash
git config --global user.name "Your Name"
git config --global user.email "youremail@yourdomain.com"
```

## aliases:

```bash
git config --global --add alias.hist "log --graph --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)<%an>%Creset' --abbrev-commit"
```

From [here](https://haacked.com/archive/2014/07/28/github-flow-aliases/) and [here](https://victorzhou.com/blog/git-aliases/)

```
[alias]
        hist = log --graph --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) %C(cyan)<%an>%Creset' --abbrev-commit
        s = status
        co = checkout
        d = diff
        br = branch
        last = log -1 HEAD
        ec = config --global -e
        up = !git pull --rebase --prune $@ && git submodule update --init --recursive
        cob = checkout -b
        cm = !git add -A && git commit -m
        save = !git add -A && git commit -m 'SAVEPOINT'
        wip = !git add -u && git commit -m "WIP"
        undo = reset HEAD~1 --mixed
        amend = commit -a --amend
        wipe = !git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard
        bclean = "!f() { git branch --merged ${1-master} | grep -v " ${1-master}$" | xargs git branch -d; }; f"
        bdone = "!f() { git checkout ${1-master} && git up && git bclean ${1-master}; }; f"
        cane = commit --amend --no-edit
        lo = log --oneline -n 10
        pr = pull --rebase
```
