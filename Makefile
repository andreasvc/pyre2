PYTHON ?= python3

.PHONY: all build install test clean distclean

all: build

# Build a wheel through pip's PEP 517 interface. Build dependencies declared in
# pyproject.toml are installed in an isolated environment automatically.
build:
	$(PYTHON) -m pip wheel --no-deps --wheel-dir dist .

# Compile and install pyre2 into the active Python environment.
install:
	$(PYTHON) -m pip install .

test:
	$(PYTHON) -m pip install '.[test]'
	$(PYTHON) -m pytest

clean:
	rm -rf build pyre2.egg-info UNKNOWN.egg-info
	rm -f re2*.so src/re2*.so src/re2.cpp src/*.html

distclean: clean
	rm -rf .tox dist .pytest_cache tests/.pytest_cache
