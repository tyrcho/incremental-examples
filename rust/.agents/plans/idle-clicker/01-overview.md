# 01 — Overview

## Goal

Produce a Rust + raylib-rs implementation of the idle clicker spec at
`/Users/punk1290/Downloads/idle_clicker_spec.md` that is **visually and
behaviorally identical** to a C++, Odin, or Crystal implementation of the
same spec (spec §1: "any of Rust [...], C++ [...], Odin [...], or Crystal
[...] should produce a visually and behaviorally identical program when
following it").

That property is the constraint that shapes every choice below. Where the
spec specifies a number, a color, a font size, a rect, or an ordering, the
Rust code adopts it literally.

## Scope

In scope:

1. `src/main.rs` — the entire game in a single file, ~150 lines.
2. `Cargo.toml` — one dependency: `raylib = "5"`.
3. `README.md` — one paragraph + build/run/controls.

Out of scope (explicit non-goals from spec §1, §11):

- Save/load, animations, sound, extra upgrades, prestige.
- Custom abstractions: no ECS, no traits/interfaces, no generics, no
  `Option`/`Result` plumbing beyond what `raylib::init().build()` returns.
- Multiple source files, modules, or sub-crates.
- External assets — no image files, no fonts, no audio. Default raylib
  font only.
- Any raylib function not in the §8 allow-list. The full Rust call list is
  in [02-rust-binding-mapping.md](./02-rust-binding-mapping.md#allowed-calls).

## Non-goals that Rust would normally tempt us with

The Rust ecosystem encourages abstractions and error-types that this spec
explicitly forbids. The plan rejects all of these up front so they don't
sneak in during implementation:

- **No `thiserror` / `anyhow`.** raylib-rs's `init().build()` returns a
  `(RaylibHandle, RaylibThread)` directly. No error path to handle.
- **No `serde`, no save format.** Spec §1: "No save/load".
- **No `tracing` / `log`.** No logging at all.
- **No newtype wrappers** around `i32` (e.g., `struct ClickPower(i32)`).
  Spec §1: "Use only primitives for state".
- **No `From`/`Into` impls** for converting state into draw data.
- **No `struct Game` for state.** Spec §9 allows either a struct or six
  locals in `main`; the four sibling ports (C++, Crystal, Odin, Nim) all
  use locals, so this port uses locals too. That keeps the ergonomics
  comparison about the *language*, not about whether someone chose a
  struct in one port but not another.
- **No `impl Game { fn draw(&self, ...) }`** method-style organization.
  Free functions only — they take the data they need by value or `&str`.

## What "behaviorally identical" actually means

Two implementations following the spec must agree on:

1. **The exact cost sequence.** `(c * 3) / 2` with integer division
   truncates the same way in Rust, C++, Odin, and Crystal. From 10:
   10, 15, 22, 33, 49, 73, 109, 163, 244. From 25: 25, 37, 55, 82,
   123, 184, 276. The Rust impl must use `i32` and `/` (not `f32` and
   round) so this sequence is bit-identical.
2. **Per-second integer ticks of `currency`.** With `passive_rate = N`,
   the `Currency:` text advances by exactly `N` per real-world second.
   The `f64` accumulator + `while accumulator >= 1.0` loop in §6 step 2
   is what guarantees this; we copy it verbatim.
3. **Hit-test geometry.** `CheckCollisionPointRec` semantics
   (point inside-or-on-edge of a rect) are consistent across all
   raylib bindings; we use raylib-rs's `Rectangle::check_collision_point_rec`
   (a method, not a free function) so the geometry comes from raylib
   itself.
4. **Drawing order and z-stacking.** Spec §7 lists draw calls 1–7 in a
   strict order; the Rust code calls them in that order. The button
   outlines (drawn after their fills) are on top, matching the
   reference visuals.

## What this plan does NOT decide

- The exact `raylib` crate minor version. Spec §10 says
  `raylib = "5"` (compatible with any 5.x). The plan accepts whatever
  `cargo build` resolves at first build; if a 5.x minor changes a
  signature we care about (`draw_rectangle_lines_ex` thickness type,
  notably), [02-rust-binding-mapping.md](./02-rust-binding-mapping.md#known-version-skew)
  calls out the two known shapes and the implementer picks the one
  that compiles.
- Whether to render the click button's two-line label using two
  separate `draw_text` calls (one per line) or some pre-measured
  trick. The plan uses two `draw_text` calls — spec §7.5 describes
  the label as "line 1 ... line 2", which two calls model directly.
