# Idle Clicker — Nim Implementation Plan

Plan to implement the language-agnostic idle clicker spec at
`/Users/punk1290/Downloads/idle_clicker_spec.md` in Nim, using
[`naylib`](https://github.com/planetis-m/naylib) — the actively maintained,
idiomatic Nim wrapper around raylib 5.x.

## TL;DR

- **One nimble project** in this directory (`incremental-examples/nim/`).
  Single `src/idle_clicker.nim`, one `idle_clicker.nimble`, one `README.md`.
  Target ~150 LOC.
- **No deviations from the spec.** Same window size, same constants, same
  cost formula, same frame-loop order, same drawing rules. The Nim file is
  a literal translation of §3–§7 into idiomatic naylib code.
- **State is six locals in `main`** (spec §3 / §9 allow this; struct would
  also be fine, but locals match the Crystal/Odin/C++/Rust ports more directly).
- **Integer cost math** stays integer: `proc nextCost(c: int32): int32 = (c * 3) div 2`.
  Nim's `div` is truncating integer division on signed integers — same
  semantics as C/Rust/Odin `/` on ints, so the cost sequence is bit-identical.
- **One drawing helper** — `drawUpgradeButton` — to avoid duplicating ~12
  lines twice (per spec §9, required when it would otherwise duplicate
  ~10 lines).
- **Accumulator is `float64`** per spec §3; `getFrameTime()` returns
  `float32`, so we widen at the multiply: `acc += float64(dt) * float64(passiveRate)`.
- **`naylib >= 5.0`** in the .nimble manifest (matches spec §10's intent
  of pulling current stable). Release builds via `nimble build -d:release`
  or `nim c -d:release src/idle_clicker.nim`.

## Files

| #  | File                                                                  | Topic |
|----|-----------------------------------------------------------------------|-------|
| 00 | [README.md](./README.md)                                              | This index |
| 01 | [01-overview.md](./01-overview.md)                                    | Goals, scope, non-goals, what we're NOT doing |
| 02 | [02-nim-binding-mapping.md](./02-nim-binding-mapping.md)              | How each spec primitive maps to naylib idioms (Color, Rectangle, MouseButton, drawing handle, measureText) |
| 03 | [03-implementation.md](./03-implementation.md)                        | Source file shape: constants, state, helpers, frame loop |
| 04 | [04-build-and-verify.md](./04-build-and-verify.md)                    | `idle_clicker.nimble`, `README.md`, build/run commands, acceptance walk-through |

## Decision log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Binding | `naylib` (Nim wrapper of raylib 5.x) | Actively maintained, idiomatic Nim, bundles raylib source so `nimble install` is self-contained — matches spec §10's "idiomatic build tooling" and "no external runtime deps" goals |
| State shape | Six locals in `main` | Spec §9 allows struct OR six locals; locals keep the file shortest and avoid an unnecessary `Game` type |
| Rectangles | `const CLICK_BUTTON = Rectangle(x: 80, y: 220, width: 240, height: 240)` | naylib's `Rectangle` is `(x, y, width, height: float32)`; const-initialized once |
| Integer division | `div` (not `/`) | In Nim, `/` on ints returns float. `div` is truncating signed integer division — matches spec §5's `(old_cost * 3) / 2` semantics |
| Color constants | `RayWhite`, `Black`, `DarkGray`, `LightGray`, `Green`, `DarkGreen`, `SkyBlue`, `Red` | naylib exposes raylib's color constants as top-level `Color` values |
| Window lifecycle | `initWindow(...)` at start, `closeWindow()` at end (no RAII) | naylib follows raylib's procedural lifecycle; one explicit `closeWindow` after the loop is idiomatic |
| String formatting | `strformat` (`fmt"..."` / `&"..."`) | Nim's standard interpolation library, in stdlib (`import std/strformat`) — no extra dep |
| Single source file | Yes, `src/idle_clicker.nim` only | Spec §9: "No modules, no multiple files." |
| Nim version | `>= 2.0` | Nim 2.x is current stable; ARC/ORC default makes raylib resource handling smooth |

## Deliverables

Files produced under `incremental-examples/nim/`:

- `src/idle_clicker.nim` — the entire game (single source file).
- `idle_clicker.nimble` — minimal manifest, `requires "nim >= 2.0"` and `requires "naylib >= 5.0"`.
- `README.md` — one paragraph, build/run commands, controls (left-click).

## Hard constraints (from spec)

- Only raylib (via naylib) for windowing/input/drawing.
- Only the raylib functions listed in spec §8.
- No image, font, or audio assets — default raylib font only.
- State is exactly the six primitives in spec §3; no `object` types beyond
  what naylib forces (Rectangle, Vector2, Color), no methods, no generics,
  no exceptions of our own.
- Cost scaling uses integer arithmetic only: `(old_cost * 3) div 2`.
- No save/load, animations, sound, extra upgrades, or prestige.

## Out of scope

Anything in the "Not add features beyond those specified" list from spec
§1: persistence, animation, audio, extra upgrade types, prestige, settings
menu, fullscreen toggle, keyboard input. Also out of scope: Nim-ecosystem
temptations like `import std/options`, `Result[T, E]`, custom `iterator`s,
or splitting the file into modules.
