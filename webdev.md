# Development Tools

## Installations

- Tools

| Package                                   | Commands                                                      |
| ----------------------------------------- | ------------------------------------------------------------- |
| [sops](https://github.com/mozilla/sops)   | `brew install sops`                                           |
| [terraform](https://www.terraform.io/)    | `brew install terraform`                                      |
| [sdkman.io](https://sdkman.io)            | `curl -s "https://get.sdkman.io" \| bash`, `sdk install java` |
| [just](https://just.io)                   | `brew install just`                                           |
| [gradle](https://gradle.org)              | `brew install gradle`                                         |
| [gh](https://github.com)                  | `brew install gh`                                             |
| [volta](https://volta.sh)                 | `curl https://get.volta.sh \| bash`, `volta install node`     |
| [nvm](https://github.com/creationix/nvm)  | `brew install nvm`                                            |
| [launch darkly](https://launchdarkly.com) |                                                               |

## NVM Config

If `nvm` was used:

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

## List all global packages installed

```bash
npm ls -g --depth 0
```

## Angular 2+

```bash
npm install -g angular-cli@latest
npm install -g typescript@beta
npm install -g typescript@2.0
npm install -g nativescript
npm install -g lodash async moment csv-parse
npm install -g npm-check-updates
npm install -g babel-cli csv-parse fs grunt-cli gulp-cli karma-cli moment pug-cli
```

## Common Global Packages

```bash
npm install -g async babel-cli bower csv-parse eslint fs
npm install -g grunt-cli gulp-cli istanbul jspm karma-cli lebab less lodash mocha moment pug-cli rimraf
npm install -g nativescript nightwatch protractor typings webpack webpack-dev-server yo
```

## XCode

```bash
sudo xcodebuild -license
```

## Nativescript

- https://docs.nativescript.org/start/ns-setup-os-x

## References

- http://stackoverflow.com/questions/28017374/what-is-the-suggested-way-to-install-brew-node-js-io-js-nvm-npm-on-os-x
- http://stackoverflow.com/questions/11177954/how-do-i-completely-uninstall-node-js-and-reinstall-from-beginning-mac-os-x
  n
- http://marcgrabanski.com/setting-up-mac-osx-web-development/
