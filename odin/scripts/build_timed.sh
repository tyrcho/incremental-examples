#!/usr/bin/env bash
# Build the idle-clicker release binary and report elapsed wall-clock time
# in seconds with three decimal places.
set -euo pipefail

cd "$(dirname "$0")/.."

start=$(python3 -c 'import time; print(time.time())')
odin build . -o:speed -out:idle_clicker
end=$(python3 -c 'import time; print(time.time())')

python3 -c "print(f'Build time: {$end - $start:.3f}s')"
