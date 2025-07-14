# NVM - Node Version Manager

## Installation

Documentation is at [creationix/nvm](https://github.com/creationix/nvm)

```shell
brew install nvm
```

```shell
mkdir ~/.nvm
nano ~/.bash_profile

export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

command -v nvm
nvm install node
nvm use node
nvm run node --version

nvm install --lts
```
