# Brew

[Homepage](http://brew.sh/)

Install via ruby:

```shell
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Other Base Stuff

- GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed, `sed`

  ```shell
  brew install coreutils moreutils findutils
  ```

## brew Installation

A nice way of installing GUI packages, along with [updating them](https://github.com/buo/homebrew-cask-upgrade).

```shell
brew install caskroom/cask/brew-cask
brew tap caskroom/versions
```

To Update Brew and Casks:

```shell
brew update
brew doctor
brew cleanup
brew prune
```
