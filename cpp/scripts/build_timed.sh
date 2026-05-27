#!/usr/bin/env bash
# Build the idle_clicker binary and report the build duration in seconds (3 decimal places).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Nanosecond-resolution wall clock via Python — portable across macOS (BSD date lacks %N)
# and Linux. Falls back-free: Python 3 ships with both.
now_ns() { python3 -c 'import time; print(time.time_ns())'; }

start_ns=$(now_ns)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
end_ns=$(now_ns)

python3 -c "print(f'Build took {($end_ns - $start_ns) / 1e9:.3f} seconds')"
