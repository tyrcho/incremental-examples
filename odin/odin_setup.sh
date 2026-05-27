#!/usr/bin/env bash
# odin_setup.sh — idempotent setup for the Odin + vendor:raylib idle-clicker port.
# Installs: Homebrew, Odin (vendor:raylib ships with the distribution).
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

# 2. Odin (Homebrew formula sets ODIN_ROOT so `vendor:raylib` resolves automatically).
log "Odin"
if command -v odin >/dev/null 2>&1; then
  skip "already installed ($(odin version 2>&1 | head -n1))"
else
  brew install odin
fi

# No separate raylib install: `vendor:raylib` bundles prebuilt static libs for every
# supported host triple (macOS Intel + Apple Silicon, Linux, Windows). That's the
# Odin port's primary build-tooling advantage over the C++/Crystal ports.

ok "Odin toolchain ready. Build with: odin build . -o:speed -out:idle_clicker"
