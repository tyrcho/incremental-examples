#!/usr/bin/env bash
# crystal_setup.sh — idempotent setup for the Crystal raylib idle-clicker port.
# Installs: Homebrew, Crystal (includes Shards), raylib (FFI link target).
# Re-runs are no-ops if everything is already present.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
skip() { printf '\033[1;33m  --\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script targets macOS. Adapt the Homebrew calls for your OS." >&2
  exit 1
fi

# 1. Homebrew.
log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "already installed ($(brew --prefix))"
else
  log "installing Homebrew (will prompt for sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 2. Crystal (bottles ship with shards bundled).
log "Crystal"
if command -v crystal >/dev/null 2>&1; then
  skip "already installed ($(crystal --version | head -n1))"
else
  brew install crystal
fi

# 3. Shards (bundled with the Homebrew crystal formula, but check explicitly).
log "Shards"
if command -v shards >/dev/null 2>&1; then
  skip "already installed ($(shards --version))"
else
  brew install shards
fi

# 4. raylib (the plan hand-rolls a `lib LibRaylib` FFI block against the Homebrew dylib).
log "raylib"
if brew list raylib >/dev/null 2>&1; then
  skip "already installed ($(brew list --versions raylib))"
else
  brew install raylib
fi

ok "Crystal toolchain ready. Build with: shards build --release --no-debug"
