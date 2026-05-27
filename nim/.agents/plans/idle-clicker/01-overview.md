# 01 — Overview

## Goal

Produce a Nim + naylib implementation of the idle clicker spec at
`/Users/punk1290/Downloads/idle_clicker_spec.md` that is **visually and
behaviorally identical** to the C++, Rust, Odin, and Crystal ports under
sibling directories of `incremental-examples/`.

Spec §1: "any of Rust (`raylib-rs`), C++ (raylib C API), Odin
(`vendor:raylib`), or Crystal (`raylib-cr` or equivalent) should produce a
visually and behaviorally identical program when following it." Nim joins
that set via naylib without changing the spec.

That property is the constraint that shapes every choice below. Where the
spec specifies a number, a color, a font size, a rect, or an ordering, the
Nim code adopts it literally.

## Scope

In scope:

1. `src/idle_clicker.nim` — the entire game in a single file, ~150 lines.
2. `idle_clicker.nimble` — one runtime dep: `naylib >= 5.0`.
3. `README.md` — one paragraph + build/run/controls.

Out of scope (explicit non-goals from spec §1, §11):

- Save/load, animations, sound, extra upgrades, prestige.
- Custom abstractions: no `object` types of our own, no methods, no
  generic procs, no closures-as-state, no `template`-based DSLs, no
  exception types beyond what naylib raises (none are expected).
- Multiple source files, modules, or imports beyond `raylib` and
  `std/strformat`.
- External assets — no image files, no fonts, no audio. Default raylib
  font only.
- Any raylib function not in spec §8's allow-list. The full Nim call
  list is in [02-nim-binding-mapping.md](./02-nim-binding-mapping.md#allowed-calls).

## Non-goals that Nim would normally tempt us with

The Nim ecosystem (and the language itself) encourages abstractions that
this spec explicitly forbids. The plan rejects all of these up front so
they don't sneak in during implementation:

- **No `object` types for state.** Spec §1: "Use only primitives for
  state". Six `var` locals in `main` is what the spec describes.
- **No `Option[T]` / `Result[T, E]`.** Nothing in the program has a
  failure path. naylib's `initWindow` is `void`-returning; no error
  branch to model.
- **No custom iterators, no `closure procs`, no `method`s.** Free
  `proc`s only.
- **No `template`s or `macro`s** for layout, draw, or input. They would
  obscure the literal translation of spec §6 and §7.
- **No `import system/widestrs`** or other Unicode juggling. The strings
  are pure ASCII labels; `string`-as-`cstring` via naylib's auto-conversion
  is all we need.
- **No `std/logging`.** No logging at all.
- **No procs on a `Game` type** (`proc tick(g: var Game; dt: float)`).
  The frame loop in `main` is straight-line code; introducing methods is
  abstraction-for-its-own-sake.

## What "behaviorally identical" actually means

Two implementations following the spec must agree on:

1. **The exact cost sequence.** `(c * 3) div 2` with truncating integer
   division produces the same numbers as `(c * 3) / 2` in C/Rust/Odin
   and `(c * 3) // 2` in Crystal. From 10: 10, 15, 22, 33, 49, 73, 109,
   163, 244. From 25: 25, 37, 55, 82, 123, 184, 276. The Nim impl must
   use `int32` and `div` (not `/`, which returns `float` in Nim) so
   this sequence is bit-identical.
2. **Per-second integer ticks of `currency`.** With `passive_rate = N`,
   the `Currency:` text advances by exactly `N` per real-world second.
   The `float64` accumulator + `while accumulator >= 1.0` loop in §6
   step 2 is what guarantees this; we copy it verbatim.
3. **Hit-test geometry.** `checkCollisionPointRec` is the raylib
   primitive in every binding; naylib forwards directly to it. Edge
   semantics (point-on-edge counts as inside) come from raylib's C
   implementation, not from any Nim layer.
4. **Drawing order and z-stacking.** Spec §7 lists draw calls 1–7 in a
   strict order; the Nim code calls them in that order. Button
   outlines (drawn after their fills) end up on top.

## What this plan does NOT decide

- The exact `naylib` patch version. Spec §10 says "current stable";
  `requires "naylib >= 5.0"` lets nimble resolve the latest 5.x. If a
  5.x patch changes a signature we touch (`drawRectangleLinesEx`
  thickness type, notably), [02-nim-binding-mapping.md](./02-nim-binding-mapping.md#known-version-skew)
  calls out the two known shapes and the implementer picks the one
  that compiles.
- Whether to render the click button's two-line label using two
  separate `drawText` calls or some pre-measured trick. The plan uses
  two `drawText` calls — spec §7.5 describes the label as "line 1 ...
  line 2", which two calls model directly.
- Whether to use `strformat`'s `&"..."` operator or the `fmt"..."`
  prefix. They are identical; the plan uses `&"..."` purely for
  byte-count.
- Whether to call `closeWindow()` explicitly after the loop or rely on
  process exit. The plan calls it explicitly to match the spec §6
  ordering ("Loop until `WindowShouldClose()` returns true, then
  `CloseWindow()`.").

## Nim-specific compile flags

- `-d:release` — turn off runtime checks and enable optimization. Spec
  §10 implies a release build.
- ORC (`--mm:orc`) is Nim 2.x's default GC; no explicit flag needed.
  naylib's `Color`, `Rectangle`, and `Vector2` are plain value types
  (no ref-counting), so GC pressure from the draw loop is effectively
  zero.
- Nothing else: no `-d:danger` (which would also disable `assert`),
  no profile flags, no `--passC`/`--passL` tweaks. nimble handles
  raylib linking via naylib's build hooks.
