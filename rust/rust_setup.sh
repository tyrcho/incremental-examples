#!/usr/bin/env bash
# rust_setup.sh — idempotent setup for the Rust + raylib-rs idle-clicker port.
# Installs: Xcode CLI tools (linker, Cocoa/OpenGL/IOKit frameworks),
#           Homebrew, CMake (raylib-rs's build.rs uses cmake-rs),
#           rustup + stable Rust toolchain (cargo).
# Re-runs are no-ops if everything is already present.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
skip() { printf '\033[1;33m  --\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script targets macOS. Adapt the Homebrew calls for your OS." >&2
  exit 1
fi

# 1. Xcode Command Line Tools (linker + Cocoa/OpenGL/IOKit frameworks for raylib).
log "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "already installed at $(xcode-select -p)"
else
  log "triggering xcode-select --install (a GUI dialog will appear; finish it then re-run this script)"
  xcode-select --install || true
  exit 1
fi

# 2. Homebrew (for cmake).
log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "already installed ($(brew --prefix))"
else
  log "installing Homebrew (will prompt for sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. CMake (raylib crate's build.rs invokes cmake-rs, which needs the cmake binary).
log "CMake"
if command -v cmake >/dev/null 2>&1; then
  skip "already installed ($(cmake --version | head -n1))"
else
  brew install cmake
fi

# 4. rustup + stable Rust toolchain (cargo comes with it).
log "rustup + cargo (stable)"
if command -v cargo >/dev/null 2>&1 && command -v rustup >/dev/null 2>&1; then
  skip "already installed ($(rustc --version))"
else
  log "installing rustup to \$HOME/.cargo (no sudo needed)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --default-toolchain stable --profile minimal
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi

# raylib's C source is fetched and compiled by the `raylib` crate's build.rs on
# first `cargo build`; no system raylib install needed.

ok "Rust toolchain ready. Build with: cargo build --release"
ok "If cargo isn't on PATH yet in this shell, run: source \$HOME/.cargo/env"
