#!/bin/bash

# 1. Fetch and install Astral's uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Refresh the shell to load uv into your PATH
source ~/.bashrc

# 2. Scaffold the isolated MendelCode environment
cd ~
uv venv mendel-env

# 3. Activate it and inject the custom PyHailoRT wheel
source mendel-env/bin/activate
uv pip install ~/hailort/hailort/libhailort/bindings/python/platform/dist/*.whl
