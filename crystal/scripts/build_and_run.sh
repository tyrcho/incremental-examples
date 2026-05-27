#!/usr/bin/env bash
# Build the release binary, then run it.
set -euo pipefail

cd "$(dirname "$0")/.."

shards build --release --no-debug
exec ./bin/idle_clicker
