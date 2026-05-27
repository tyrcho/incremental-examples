#!/usr/bin/env bash
# Build the idle-clicker release binary, then run it.
set -euo pipefail

cd "$(dirname "$0")/.."

odin build . -o:speed -out:idle_clicker
exec ./idle_clicker
