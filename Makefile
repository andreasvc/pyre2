PYTHON ?= python3

PYTHON_TAG := $(shell $(PYTHON) -c "import sys; print(sys.implementation.cache_tag)")
WHEEL_DIR := build/make/$(PYTHON_TAG)
WHEEL_STAMP := $(WHEEL_DIR)/.built
BUILD_SOURCES := \
	pyproject.toml setup.py setup.cfg CMakeLists.txt \
	$(wildcard src/*.pyx src/*.pxi src/*.h) \
	src/CMakeLists.txt

.PHONY: all build install test lint clean distclean

all: build

# Build a wheel through pip's PEP 517 interface. Build dependencies declared in
# pyproject.toml are installed in an isolated environment automatically.
build: $(WHEEL_STAMP)

$(WHEEL_STAMP): $(BUILD_SOURCES)
	rm -rf "$(WHEEL_DIR)"
	mkdir -p "$(WHEEL_DIR)" dist
	$(PYTHON) -m pip wheel --no-deps --wheel-dir "$(WHEEL_DIR)" .
	cp "$(WHEEL_DIR)"/*.whl dist/
	touch "$@"

# Compile and install pyre2 into the active Python environment.
install:
	$(PYTHON) -m pip install .

test: $(WHEEL_STAMP)
	set -- "$(WHEEL_DIR)"/*.whl; \
		test "$$#" -eq 1; \
		$(PYTHON) -m pip install "$${1}[test]"
	$(PYTHON) -m pytest

lint:
	cython-lint src/

clean:
	rm -rf build pyre2.egg-info UNKNOWN.egg-info
	rm -f re2*.so src/re2*.so src/re2.cpp src/*.html

distclean: clean
	rm -rf .tox dist .pytest_cache tests/.pytest_cache
