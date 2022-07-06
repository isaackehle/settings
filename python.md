# Python and related tooling

```bash
brew install pyenv
```

Add pyenv to your config file (.zshrc or .bash_profile)

```bash
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc
```

Determine all versions of python available

```bash
pyenv install --list
```

Install a version and set it to global

```bash
pyenv install 3.10.5
pyenv global 3.10.5
```
