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

## Usage

List available versions:

```shell
pyenv install --list
```

Install and set a global version:

```shell
pyenv install 3.12.0
pyenv global 3.12.0
```

Common pip packages:

```shell
pip install --upgrade pip
pip install pipenv
pip install notebook       # Jupyter
```

## References

- [pyenv on GitHub](https://github.com/pyenv/pyenv)
- [FastAPI](https://fastapi.tiangolo.com/)
- [Mypy — static type checker](https://mypy.readthedocs.io/)
- [Setting Python 3 as default on macOS](https://opensource.com/article/19/5/python-3-default-mac)
