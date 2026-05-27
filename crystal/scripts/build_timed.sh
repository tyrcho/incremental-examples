#!/usr/bin/env bash
# Build the release binary and report wall-clock build time in seconds (3 decimals).
set -euo pipefail

cd "$(dirname "$0")/.."

start=$(perl -MTime::HiRes=time -E 'printf("%.6f\n", time)')
shards build --release --no-debug
end=$(perl -MTime::HiRes=time -E 'printf("%.6f\n", time)')

perl -E "printf(\"%.3f\n\", $end - $start)"
