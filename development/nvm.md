# NVM - Node Version Manager

## Installation

Documentation is [here](https://github.com/creationix/nvm)

```bash
brew install nvm
```

## NVM Config

```bash
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
