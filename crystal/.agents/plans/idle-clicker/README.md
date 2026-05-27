# Idle Clicker (Crystal / raylib) — Plan Index

Implementation plan for the spec at `~/Downloads/idle_clicker_spec.md`, targeting Crystal with **hand-rolled `lib LibRaylib` FFI bindings** against Homebrew's `libraylib.dylib`. No third-party Crystal shard wraps raylib for us.

## Why hand-rolled FFI

The candidate shard `raylib-cr` labels its macOS support **"Weak / Broken"** in its own README. Rather than gate the plan behind a smoke test that may push Crystal out of the cross-language comparison, this plan commits up front to the contingency path: declare the ~14 raylib functions we need in a `lib LibRaylib` block inside `src/idle_clicker.cr`, link Homebrew's dynamic raylib library with `@[Link("raylib")]`, and call those `fun`s directly.

This is an honest ergonomics signal for the comparison: "what does Crystal feel like when no maintained binding exists?" The Rust/C++/Odin/Nim ports all use first-class bindings; Crystal's port pays a ~30-line FFI tax up front. That trade-off is the data point.

## Goal

A ~150–230 line single-file Crystal program (the FFI block lifts the budget vs. the other ports by ~30 lines) that opens an 800×600 raylib window titled "Idle Clicker", lets the player accumulate currency by clicking a green square and buying two upgrades (click power, passive income). No external assets, no extra features beyond the spec.

## Plan documents

1. [`01-setup-and-build.md`](./01-setup-and-build.md) — Directory layout, Crystal + Homebrew raylib install, minimal `shard.yml`, build/run commands.
2. [`02-implementation.md`](./02-implementation.md) — Single-file `src/idle_clicker.cr` walkthrough mapped to spec §3–§7, including the full `lib LibRaylib` declaration block.
3. [`03-acceptance.md`](./03-acceptance.md) — Manual verification checklist matching spec §11.

## Deliverables

Files produced under `incremental-examples/crystal/`:

- `src/idle_clicker.cr` — the entire game (single source file, includes the `lib LibRaylib` FFI block).
- `shard.yml` — minimal manifest declaring the `idle_clicker` binary target. **No `raylib-cr` dependency** — we hand-roll the FFI.
- `README.md` — one paragraph, build/run commands, controls (left-click). Notes that raylib must be installed via `brew install raylib`.

The `shards build --release --no-debug` artifact lands at `bin/idle_clicker`.

## Hard constraints (from spec)

- Only raylib (via our hand-rolled `lib LibRaylib`) for windowing/input/drawing.
- Only the raylib functions listed in spec §8 — declared in `lib LibRaylib` with their snake_case Crystal aliases.
- No image, font, or audio assets — default raylib font only.
- State is exactly the six primitives in spec §3; six locals in `main` (matching the C++/Odin/Rust/Nim sibling ports).
- Cost scaling uses integer arithmetic only: `new_cost = (old_cost * 3) / 2`. In Crystal, `Int32 / Int32` truncates toward zero — same semantics as C/Rust/Odin `/` on ints and Nim's `div`.
- No save/load, animations, sound, extra upgrade types, or prestige.

## Out of scope

Anything in the spec §1 "Not add features beyond those specified" list: persistence, animation, audio, extra upgrade types, prestige, settings menu, fullscreen toggle, keyboard input. Also: no attempt to use `raylib-cr`, `cray`, or any other raylib Crystal shard — we made that choice in this plan and don't relitigate it at implementation time.

## Scope of this plan

This document set **plans** the implementation. It does NOT execute setup. Running `brew install crystal` and `brew install raylib` is the implementer's first step at execution time, not part of producing the plan.

## Tradeoffs vs. the sibling ports

- **Verbosity**: Crystal source file will be ~30 lines longer than C++/Odin/Rust/Nim because the FFI block lives inline. That is the cost of "no maintained binding".
- **Ergonomics signal**: When you compare Crystal's call sites to (say) Odin's, both look very similar — `LibRaylib.init_window(...)` vs. `rl.InitWindow(...)`. The Crystal *file overhead* is the differentiator, not per-call ergonomics.
- **Risk**: Crystal's macOS toolchain (compiler + Homebrew raylib + LLVM-linked binary) is well-trodden territory. The FFI fallback removes the shard-specific risk entirely.
