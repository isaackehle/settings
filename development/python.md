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

```bash
brew install py2cairo
brew install pygobject3
```

Python

- [FastAPI (tiangolo.com)](https://fastapi.tiangolo.com/)
- [microsoft/ptvsd: Python debugger package for use with Visual Studio and Visual Studio Code. (github.com)](https://github.com/Microsoft/ptvsd)

```bash
pip3 install pipenv
/usr/local/bin/pipenv
```

Mypy

- [Introduction — Mypy 0.910 documentation](https://mypy.readthedocs.io/en/stable/introduction.html)
- [Type hints cheat sheet (Python 3) — Mypy 0.910 documentation](https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html)
