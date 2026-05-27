# 01 — Setup and Build

## Directory layout

```
incremental-examples/crystal/
├── shard.yml
├── README.md
└── src/
    └── idle_clicker.cr
```

Keep the project flat at the language root. Crystal/shards expects sources under `src/`; that's the only nesting we need (and is the same shape Rust and Nim use in their sibling language roots). No `spec/`, no `bin/` checked in (shards writes the binary into `bin/` on build — gitignored).

## Binding strategy: hand-rolled `lib LibRaylib`

This plan does NOT use the `raylib-cr` shard. Its README labels macOS support "Weak / Broken", and we commit up front to bypassing that risk via Crystal's native FFI:

1. Install raylib via Homebrew (`brew install raylib`) — produces `/opt/homebrew/lib/libraylib.dylib` on Apple Silicon (`/usr/local/lib/libraylib.dylib` on Intel).
2. Declare the ~14 raylib `fun`s we need inside `src/idle_clicker.cr` in a `lib LibRaylib` block annotated `@[Link("raylib")]`.
3. Call them directly: `LibRaylib.init_window(800, 600, "Idle Clicker")`, etc.

The full FFI declaration block lives in [`02-implementation.md`](./02-implementation.md#fffi-block). It is ~30 lines and stays inside the same source file — no module split.

This is the contingency #2 path from the prior version of this plan, promoted to the primary path so Crystal does not fail late and silently drop out of the cross-language ergonomics comparison.

## Install Crystal (macOS, this machine)

Crystal is not installed (`crystal --version` → command not found at plan-writing time). Use Homebrew:

```bash
brew install crystal
```

This installs `crystal` and `shards` (Crystal's package manager) at `/opt/homebrew/bin/`. Verify with `crystal --version` and `shards --version`.

## Install raylib (macOS, this machine)

```bash
brew install raylib
```

This produces:

- `/opt/homebrew/lib/libraylib.dylib` (the runtime library)
- `/opt/homebrew/include/raylib.h` (headers — we don't use them but they're harmless)

Crystal's linker will resolve `@[Link("raylib")]` against this `.dylib` automatically because `/opt/homebrew/lib` is on the macOS dynamic linker's default search path on Apple Silicon. No `pkg-config`, no `LIBRARY_PATH` exports.

If on Intel Macs, the library lands at `/usr/local/lib/libraylib.dylib` instead. Same auto-resolution applies.

If on Linux (Debian/Ubuntu): `sudo apt install libraylib-dev` produces `/usr/lib/x86_64-linux-gnu/libraylib.so` plus headers. `@[Link("raylib")]` resolves it.

## `shard.yml`

```yaml
name: idle_clicker
version: 0.1.0

targets:
  idle_clicker:
    main: src/idle_clicker.cr

# No dependencies — we hand-roll the raylib FFI inside src/idle_clicker.cr.
```

No `dependencies:` section. The `shard.yml` exists only so `shards build` recognizes the project and writes `bin/idle_clicker` to the right place. We could also just use `crystal build src/idle_clicker.cr -o bin/idle_clicker` directly; the shard.yml is the more idiomatic shape.

## Build and run commands

```bash
cd incremental-examples/crystal
shards build --release --no-debug
./bin/idle_clicker
```

`shards build --release --no-debug` is the spec §10 invocation. `--release` enables LLVM optimizations; `--no-debug` strips debug info to keep the binary lean — together they match the spec's "release-build the binary" acceptance criterion.

For dev iteration, `crystal run src/idle_clicker.cr` works and is faster to start than the full build cycle.

If the build fails with `ld: library not found for -lraylib`, raylib is not installed where the linker expects. Re-run `brew install raylib` and verify with `ls /opt/homebrew/lib/libraylib*`.

## Smoke test (optional — no longer a go/no-go gate)

Because we control the FFI block directly, there is no third-party shard that might be broken on macOS. The build either compiles and links against Homebrew's `libraylib.dylib` or it doesn't, and the error message in the "doesn't" case is a standard linker error with a one-line fix.

If you still want a smoke test before writing the full spec implementation, the minimal FFI exercise is:

```crystal
@[Link("raylib")]
lib LibRaylib
  struct Color
    r, g, b, a : UInt8
  end
  fun init_window = InitWindow(width : Int32, height : Int32, title : LibC::Char*)
  fun close_window = CloseWindow()
  fun window_should_close = WindowShouldClose : Bool
  fun begin_drawing = BeginDrawing()
  fun end_drawing = EndDrawing()
  fun clear_background = ClearBackground(color : Color)
  fun set_target_fps = SetTargetFPS(fps : Int32)
end

ray_white = LibRaylib::Color.new(r: 245_u8, g: 245_u8, b: 245_u8, a: 255_u8)
LibRaylib.init_window(800, 600, "smoke")
LibRaylib.set_target_fps(60)
until LibRaylib.window_should_close
  LibRaylib.begin_drawing
  LibRaylib.clear_background(ray_white)
  LibRaylib.end_drawing
end
LibRaylib.close_window
```

`shards build --release && ./bin/idle_clicker` → an empty white 800×600 window appears, closes cleanly on window-close. Then proceed to write the full implementation per [`02-implementation.md`](./02-implementation.md).

## README contents (for the deliverable, not this plan)

Single short file. Required per spec §10:

- One-paragraph description.
- Prereq line: `brew install crystal raylib` (single command works because both are Homebrew formulas).
- Build command (`shards build --release --no-debug`).
- Run command (`./bin/idle_clicker`).
- Controls: "Left-click the green square to earn currency; left-click an upgrade to buy it."
- One sentence noting that raylib is loaded dynamically via Homebrew's `libraylib.dylib` and the FFI declarations live inline in `src/idle_clicker.cr`.

No screenshots, no design notes, no roadmap.
