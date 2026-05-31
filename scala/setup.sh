#!/usr/bin/env bash
# Idempotent macOS setup for Scala Native + raylib idle-clicker port.
# Installs: Xcode CLI tools, Homebrew, SDKMAN, Java 21 (Temurin), SBT, raylib.
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*" >&2; }
skip() { printf '\033[1;33m  –\033[0m %s (already installed)\n' "$*" >&2; }

# Xcode CLI tools (Clang/LLVM backend for Scala Native)
if ! xcode-select -p &>/dev/null; then
  log "Installing Xcode CLI tools..."
  xcode-select --install
else
  skip "Xcode CLI tools"
fi

# Homebrew
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  skip "Homebrew"
fi

# raylib
if brew list raylib &>/dev/null; then
  skip "raylib"
else
  log "Installing raylib..."
  brew install raylib
  ok "raylib"
fi

# SDKMAN
if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  skip "SDKMAN"
else
  log "Installing SDKMAN..."
  curl -s "https://get.sdkman.io" | bash
  ok "SDKMAN"
fi

# shellcheck disable=SC1091
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Java 21 Temurin (SBT runs on JVM; Scala Native output is still a native binary)
if sdk list java | grep -q "21.*tem.*installed"; then
  skip "Java 21 Temurin"
else
  log "Installing Java 21 Temurin..."
  sdk install java 21.0.7-tem
  ok "Java 21 Temurin"
fi

# SBT
if command -v sbt &>/dev/null; then
  skip "SBT"
else
  log "Installing SBT..."
  sdk install sbt
  ok "SBT"
fi

log "Setup complete. Build with: cd scala && sbt nativeLink"
