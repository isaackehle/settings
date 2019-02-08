## Brew
[Homepage](http://brew.sh/)

Install via ruby:
```bash
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Other Base Stuff

* GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed, `sed`
  ```bash
  brew install coreutils moreutils findutils
  brew install homebrew/dupes/grep
  brew install homebrew/dupes/screen
  brew install gnu-sed --with-default-names
  ```
