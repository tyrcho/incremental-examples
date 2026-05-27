#!/usr/bin/env bash
# Build the release binary, then run it.
set -euo pipefail

cd "$(dirname "$0")/.."

cargo build --release
exec ./target/release/idle_clicker "$@"
