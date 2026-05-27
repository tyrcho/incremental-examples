#!/usr/bin/env bash
# cpp_setup.sh — idempotent setup for the C++ raylib idle-clicker port.
# Installs: Xcode CLI tools, Homebrew, CMake, pkg-config, raylib.
# Re-runs are no-ops if everything is already present.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
skip() { printf '\033[1;33m  --\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script targets macOS. Adapt the Homebrew calls for your OS." >&2
  exit 1
fi

# 1. Xcode Command Line Tools (provides clang/clang++).
log "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "already installed at $(xcode-select -p)"
else
  log "triggering xcode-select --install (a GUI dialog will appear; finish it then re-run this script)"
  xcode-select --install || true
  exit 1
fi

# 2. Homebrew.
log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "already installed ($(brew --prefix))"
else
  log "installing Homebrew (will prompt for sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. CMake.
log "CMake"
if command -v cmake >/dev/null 2>&1; then
  skip "already installed ($(cmake --version | head -n1))"
else
  brew install cmake
fi

# 4. pkg-config (for the alternative g++ build line in the README).
log "pkg-config"
if command -v pkg-config >/dev/null 2>&1; then
  skip "already installed"
else
  brew install pkg-config
fi

# 5. raylib (system library; CMake find_package + the g++ fallback both want this).
log "raylib"
if brew list raylib >/dev/null 2>&1; then
  skip "already installed ($(brew list --versions raylib))"
else
  brew install raylib
fi

ok "C++ toolchain ready. Build with: cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build"
