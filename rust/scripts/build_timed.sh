#!/usr/bin/env bash
# Time a release build and report elapsed seconds with millisecond precision.
set -euo pipefail

cd "$(dirname "$0")/.."

# Use Python for monotonic clock — `date +%s.%N` is GNU-only and macOS `date`
# lacks sub-second precision via %N.
start=$(python3 -c 'import time; print(time.monotonic())')
cargo build --release
end=$(python3 -c 'import time; print(time.monotonic())')

python3 -c "print(f'{${end} - ${start}:.3f}s')"
