#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
sbt nativeLink
exec ./target/scala-3.3.4/idle_clicker
