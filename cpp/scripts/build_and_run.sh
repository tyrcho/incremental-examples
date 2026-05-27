#!/usr/bin/env bash
# Build the idle_clicker binary, then run it.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

./build/idle_clicker
