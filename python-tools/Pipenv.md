---
tags: [languages, python, tooling]
---

# <img src="https://github.com/python.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Pipenv

Virtual environment and dependency manager for Python. Combines `pip` and `venv` into one workflow using a `Pipfile`.

## Installation

```shell
brew install pipenv
```

Or via pip:

```shell
pip install --user pipenv
```

## Configuration

### Initialize a project

```shell
pipenv --python 3.13          # create env pinned to a version
pipenv install                # install from existing Pipfile
```

### Add dependencies

```shell
pipenv install requests        # runtime dependency
pipenv install --dev pytest pytest-cov   # dev-only dependencies
```

This writes to `Pipfile` and locks versions in `Pipfile.lock`.

### Pipfile example

```toml
[[source]]
url = "https://pypi.org/simple"
verify_ssl = true
name = "pypi"

[packages]
requests = "*"

[dev-packages]
pytest = "*"
pytest-cov = "*"

[requires]
python_version = "3.13"
```

## Start / Usage

```shell
pipenv shell                  # activate the virtualenv
pipenv run pytest             # run pytest without activating shell
pipenv run pytest -v          # verbose output
pipenv run pytest --cov=src   # with coverage
pipenv sync --dev             # install all deps from lock file (CI-friendly)
```

### pytest configuration

Add to `pyproject.toml` (or `pytest.ini`) in the project root — pipenv picks it up automatically:

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

### Useful commands

```shell
pipenv graph                  # show dependency tree
pipenv check                  # audit for known vulnerabilities
pipenv lock                   # regenerate Pipfile.lock
pipenv --venv                 # print path to the virtualenv
pipenv --rm                   # delete the virtualenv
```

## Project Layout

```text
my-project/
├── src/
│   └── mypackage/
│       └── __init__.py
├── tests/
│   ├── conftest.py
│   └── test_mypackage.py
├── Pipfile
├── Pipfile.lock
└── pyproject.toml
```

## References

- [pipenv docs](https://pipenv.pypa.io/en/latest/)
- [[Python]] — Python setup with pyenv
- [[Pytest]] — writing and running tests
