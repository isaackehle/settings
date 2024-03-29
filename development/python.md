# Python and related tooling

https://opensource.com/article/19/5/python-3-default-mac

```shell
brew install pyenv
```

Add pyenv to your config file (.zshrc or .bash_profile)

```shell
echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init --path)"\nfi' >> ~/.zshrc
```

Determine all versions of python available

```shell
pyenv install --list
```

Install a version and set it to global

```shell
pyenv install 3.10.6
pyenv global 3.10.6

echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.zshrc

```

```shell
brew install py2cairo
brew install pygobject3
```

```shell
pip install termcolors
pip install notebook
pip install --upgrade pip
```

Python

- [FastAPI (tiangolo.com)](https://fastapi.tiangolo.com/)
- [microsoft/ptvsd: Python debugger package for use with Visual Studio and Visual Studio Code. (github.com)](https://github.com/Microsoft/ptvsd)

```shell
pip3 install pipenv
/usr/local/bin/pipenv
```

Mypy

- [Introduction — Mypy 0.910 documentation](https://mypy.readthedocs.io/en/stable/introduction.html)
- [Type hints cheat sheet (Python 3) — Mypy 0.910 documentation](https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html)
