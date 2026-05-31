#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
perl -MTime::HiRes=time -e '
  my $t0 = time;
  system("sbt nativeLink") == 0 or die "build failed\n";
  printf "build: %.2fs\n", time - $t0;
  system("./target/scala-3.3.4/idle_clicker");
'
