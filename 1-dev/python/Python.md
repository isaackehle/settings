---
tags: [languages]
---

# <img src="https://github.com/python.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Python

Python 3 managed via `pyenv` for version isolation.

## Installation

```shell
brew install pyenv
```

Add to `~/.zshrc`:

```shell
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
```

## Configuration

Install and set a Python version:

```shell

# This warning occurs when Python is built or installed without the necessary XZ/LZMA development headers on your system. Without these headers, Python skips compiling the _lzma C-extension, leading to an incomplete installation that cannot handle .xz or .lzma compression. 
brew install xz

pyenv install --list           # browse available versions
pyenv install 3.14.4
pyenv global 3.14.4            # set system default
pyenv local 3.11.9             # set per-project (writes .python-version)
pyenv version                  # confirm active version
```

## Start / Usage

Essential packages for every project:

```shell
pip install --upgrade pip
pip install pytest             # testing — see [[Pytest]]
pip install ruff               # linter + formatter
pip install mypy               # static type checker
pip install ipython            # better REPL
pip install notebook           # Jupyter
```

### Virtual Environments

```shell
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## References

- [pyenv](https://github.com/pyenv/pyenv)
- [Mypy](https://mypy.readthedocs.io/en/stable/)
- [Ruff](https://docs.astral.sh/ruff/)
- [xv](https://github.com/python/xv) - Image viewer and manipulator for X

