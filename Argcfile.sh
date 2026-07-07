#!/bin/bash
# @meta version 1.0.0
# @meta dotenv
set -euo pipefail

CONTAINER=traktor-nml-utils
VIRTUALENV_DIR=.venv

# @cmd Remove build artifacts, caches and the virtualenv
clean() {
  find . \( \
    -name "__pycache__" -o \
    -name "*.class" -o \
    -name "*.tmp" -o \
    -name "*.temp" -o \
    -name "*.swp" -o \
    -name "*.egg-info" -o \
    -name "*.eggs" -o \
    -name "*.pyc" -o \
    -name ".coverage" -o \
    -name ".DS_Store" -o \
    -name ".mypy_cache" -o \
    -name ".pytest_cache" -o \
    -name ".ruff_cache" -o \
    -name ".tox" -o \
    -name ".venv" -o \
    -name "dist" -o \
    -name "node_modules" \) \
    -prune -exec rm -rfv {} \;
}

# @cmd Install dev tooling (argc, direnv)
install() {
  install_argc
  if ! dpkg -s direnv >/dev/null 2>&1; then
    sudo apt-get install -y direnv
  fi
}

# @cmd Run the GitHub Actions workflow locally with act
act() {
  docker build -f Dockerfile -t ubuntu-builder .
  command act -P ubuntu-latest=ubuntu-builder
}

# @cmd Build the docker image
docker-build() {
  docker build -t "$CONTAINER" .
}

# @cmd Stop and remove the docker container
docker-clean() {
  docker stop "$CONTAINER" || true
  docker rm "$CONTAINER" || true
}

# @cmd Open a shell in the docker image
docker-shell() {
  docker run -it --rm "$CONTAINER" bash
}

# @cmd Run the tests in docker
docker-test() {
  docker run -it --rm "$CONTAINER" pytest
}

# @cmd Run lint, format check and type check in docker
docker-lint() {
  docker run -it --rm "$CONTAINER" ruff check
  docker run -it --rm "$CONTAINER" ruff format --check
  docker run -it --rm "$CONTAINER" mypy
}

# @cmd Create the virtualenv and install the project with dev dependencies
virtualenv-create() {
  python3 -m venv "$VIRTUALENV_DIR"
  "$VIRTUALENV_DIR/bin/pip" install --upgrade pip
  "$VIRTUALENV_DIR/bin/pip" install -e ".[dev]"
}

# @cmd Run the tests in the virtualenv
virtualenv-test() {
  "$VIRTUALENV_DIR/bin/python" -m pytest tests
}

# @cmd Run lint, format check and type check in the virtualenv
virtualenv-lint() {
  "$VIRTUALENV_DIR/bin/ruff" check
  "$VIRTUALENV_DIR/bin/ruff" format --check
  "$VIRTUALENV_DIR/bin/mypy"
}

# @cmd Import a Traktor collection file via the CLI
# @env TRAKTOR_DIR! Path to the Traktor data directory
virtualenv-test-import-file() {
  "$VIRTUALENV_DIR/bin/traktor-nml-utils" traktor-import "$TRAKTOR_DIR/collection.nml"
}

# @cmd Import a Traktor history directory via the CLI
# @env TRAKTOR_DIR! Path to the Traktor data directory
virtualenv-test-import-dir() {
  "$VIRTUALENV_DIR/bin/traktor-nml-utils" traktor-import "$TRAKTOR_DIR/History"
}

# @cmd Build the package and upload it to PyPI
pypi-upload() {
  rm -rf dist
  "$VIRTUALENV_DIR/bin/python" -m build
  "$VIRTUALENV_DIR/bin/twine" upload dist/*
}

# @cmd Generate Python dataclasses from the sample NML files
#
# xsdata infers the schema directly from the XML documents. The committed
# models in traktor_nml_utils/models/ are hand-tuned, so the output goes to
# build/generated/ for manual comparison instead of overwriting them.
generate-models() {
  rm -rf build/generated
  mkdir -p build/generated
  "$VIRTUALENV_DIR/bin/xsdata" generate xml_to_xsd/collection.nml --package build.generated.collection
  "$VIRTUALENV_DIR/bin/xsdata" generate xml_to_xsd/history.nml --package build.generated.history
  echo "Models written to build/generated/ - diff against traktor_nml_utils/models/ and merge manually."
}

# @cmd Bump the project version, commit and tag
# @arg part![patch|minor|major] Version part to bump
bumpversion() {
  "$VIRTUALENV_DIR/bin/bump-my-version" bump "$argc_part"
}

install_argc() {
  if ! command -v argc >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/sigoden/argc/main/install.sh | sudo sh -s -- --to /usr/local/bin
  fi
  if [ -d "/etc/bash_completion.d" ] && [ ! -f "/etc/bash_completion.d/argc" ]; then
    argc --argc-completions bash | sudo tee /etc/bash_completion.d/argc >/dev/null
    echo "Bash completion installed to /etc/bash_completion.d/argc. Reload shell to activate."
  fi
}

install_argc

eval "$(argc --argc-eval "$0" "$@")"
