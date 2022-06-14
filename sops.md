# Sops

SOPS is used for encrypting environment resources for HELM deployments. An example resource file can be seen here. This will store such info as the database login/password, api keys, etc.

Documentation is [here](https://github.com/mozilla/sops)

```bash
brew install sops
```

After make sure your profile contains the following:

```bash
export EDITOR='code -w'
```
