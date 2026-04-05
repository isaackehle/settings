---
tags: [languages, python, testing]
---

# <img src="https://github.com/pytest-dev.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Pytest

Python testing framework. Simple to start, powerful for large projects.

## Installation

```shell
pip install pytest pytest-cov
```

Or add to `pyproject.toml`:

```toml
[project.optional-dependencies]
dev = ["pytest", "pytest-cov"]
```

## Configuration

`pytest.ini` or `pyproject.toml` (preferred):

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-v --tb=short"
```

## Start / Usage

```shell
pytest                        # run all tests
pytest tests/test_foo.py      # run one file
pytest -k "test_login"        # run tests matching name
pytest -x                     # stop on first failure
pytest -v                     # verbose output
pytest --tb=short             # shorter tracebacks
pytest --cov=src --cov-report=term-missing   # coverage report
```

## Writing Tests

```python
# tests/test_example.py

def add(a, b):
    return a + b

def test_add():
    assert add(1, 2) == 3

def test_add_negative():
    assert add(-1, 1) == 0
```

### Fixtures

```python
import pytest

@pytest.fixture
def db():
    conn = connect_db()
    yield conn
    conn.close()

def test_query(db):
    result = db.query("SELECT 1")
    assert result == 1
```

### Parametrize

```python
@pytest.mark.parametrize("a,b,expected", [
    (1, 2, 3),
    (0, 0, 0),
    (-1, 1, 0),
])
def test_add(a, b, expected):
    assert add(a, b) == expected
```

### Expected Exceptions

```python
def test_divide_by_zero():
    with pytest.raises(ZeroDivisionError):
        1 / 0
```

## Useful Plugins

| Plugin | Install | Purpose |
| --- | --- | --- |
| `pytest-cov` | `pip install pytest-cov` | Coverage reports |
| `pytest-xdist` | `pip install pytest-xdist` | Parallel test runs (`-n auto`) |
| `pytest-mock` | `pip install pytest-mock` | `mocker` fixture for mocking |
| `pytest-asyncio` | `pip install pytest-asyncio` | Async test support |

## Project Layout

```text
my-project/
├── src/
│   └── mypackage/
│       └── __init__.py
├── tests/
│   ├── conftest.py       # shared fixtures
│   └── test_mypackage.py
├── pyproject.toml
└── .python-version       # set by pyenv local
```

## References

- [pytest docs](https://docs.pytest.org/)
- [pytest-cov](https://pytest-cov.readthedocs.io/)
- [[Python]] — Python setup with pyenv
