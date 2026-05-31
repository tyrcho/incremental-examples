# Idle Clicker — Scala

Two targets: a native binary (Scala Native 0.5.x + raylib) and a browser build (Scala.js + Canvas2D).

One of several language ports in this repo — implements the same idle-clicker spec.
Click the green square to earn currency. Buy upgrades to increase per-click yield
or earn passive income per second. Costs scale 1.5× per purchase.

## Prereqs

```bash
brew install raylib
```

Java 21+ and SBT are also required. Run `./setup.sh` to install everything
idempotently via SDKMAN.

## Native build

    make build-native

(First build downloads the Scala Native toolchain and compiles; expect a
minute or two. Subsequent builds are fast.)

## Run native

    make run-native

Run from the `scala/` directory so the relative path to `../assets/` resolves.

## Browser build

    make build-js

Produces a JS bundle under `js/target/scala-3.3.4/idle-clicker-js-fastopt/`.

## Run browser

    make serve-js

Opens a local HTTP server at `http://localhost:8080`. A browser is required
(Canvas2D security policy prevents loading via `file://`).

## Controls

Left-click (or tap on mobile). That's all.

## Notes

**Native target:** Scala Native compiles Scala 3 to native code via LLVM — no JVM at runtime.
raylib is linked dynamically against Homebrew's `libraylib.dylib`. A thin C shim
(`native/src/main/resources/scala-native/glue.c`) bridges struct-by-value ABI gaps
on macOS ARM64.

**Browser target:** Scala.js compiles to JavaScript. Rendering uses Canvas2D;
input uses `mousedown`/`touchstart` DOM events. The sprite sheet loads asynchronously
before the animation frame loop starts.

**Architecture:** Hexagonal — `core/` holds pure domain logic and port traits
(`Renderer`, `Input`). The `native/` and `js/` modules each provide adapters
that implement those ports without any shared platform code.
