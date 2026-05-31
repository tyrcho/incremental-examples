# Idle Clicker (Scala Native + raylib)

A minimal idle clicker built with Scala Native 0.5.x and raylib. Click the
green square to earn currency. Buy upgrades on the right to increase your
per-click yield or earn passive income per second. Costs scale 1.5× per
purchase.

## Prereqs

```bash
brew install raylib
```

Java 21+ and SBT are also required. Run `./setup.sh` to install everything
idempotently via SDKMAN.

## Build

    sbt nativeLink

(First build downloads the Scala Native toolchain and compiles; expect a
minute or two. Subsequent builds are fast.)

## Run

    ./target/scala-3.3.4/idle_clicker

Run from the `scala/` directory so the relative path to `../assets/` resolves.

## Controls

Left-click. That's all.

## Notes

Scala Native compiles Scala 3 to native code via LLVM — no JVM at runtime.
raylib is linked dynamically against Homebrew's `libraylib.dylib`.

The ~18 raylib functions used by the game are declared as a hand-rolled
`@link("raylib") @extern` block in `src/main/scala/game/Raylib.scala` — no
third-party raylib wrapper is used.

Scala Native 0.5.x has unreliable struct-by-value ABI on macOS ARM64. A thin
C shim (`src/main/resources/scala-native/glue.c`) bridges all struct
parameters and return values via pointers; Scala Native auto-compiles it as
part of the native link step.
