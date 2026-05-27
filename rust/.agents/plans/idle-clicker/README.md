# Idle Clicker — Rust Implementation Plan

Plan to implement the language-agnostic idle clicker spec at
`/Users/punk1290/Downloads/idle_clicker_spec.md` in Rust, using the
[`raylib`](https://crates.io/crates/raylib) crate (raylib-rs, the safe Rust
binding to raylib 5.x).

## TL;DR

- **One Cargo binary crate** in this directory (`incremental-examples/rust/`).
  Single `src/main.rs`, one `Cargo.toml`, one `README.md`. Target ~150 LOC.
- **No deviations from the spec.** Same window size, same constants, same
  cost formula, same frame-loop order, same drawing rules. The Rust file is a
  literal translation of §3–§7 into idiomatic raylib-rs code.
- **State is six `let mut` locals in `main`** (per spec §3 / §9). No
  `struct Game`, no globals, no `Rc`/`RefCell`. This matches the
  C++/Crystal/Odin/Nim sibling ports so the ergonomics comparison is
  apples-to-apples — Rust isn't earning or paying for a `struct`
  decision the other ports didn't make.
- **Integer cost math** stays integer: `fn next_cost(c: i32) -> i32 { c * 3 / 2 }`.
  No `f32`/`f64` anywhere in the upgrade-cost path.
- **One drawing helper** — `draw_upgrade_button` — to avoid duplicating ~12
  lines twice (per §9 of the spec, this is required when it would otherwise
  duplicate ~10 lines).
- **Accumulator is `f64`** per spec §3; `get_frame_time()` returns `f32`,
  so we widen at the multiply: `acc += (dt as f64) * passive_rate as f64`.
  The integer-tick loop guarantees `Currency: N` advances by exactly `N`
  per real-world second when `passive_rate = N` (spec §11 acceptance).
- **`raylib = "5"`** in `Cargo.toml` (matches spec §10). Release builds via
  `cargo run --release`. No other deps.

## Files

| #  | File | Topic |
|----|------|-------|
| 00 | [README.md](./README.md) | This index |
| 01 | [01-overview.md](./01-overview.md) | Goals, scope, non-goals, what we're NOT doing |
| 02 | [02-rust-binding-mapping.md](./02-rust-binding-mapping.md) | How each spec primitive maps to raylib-rs idioms (Color, Rectangle, MouseButton, drawing handle, MeasureText) |
| 03 | [03-implementation.md](./03-implementation.md) | Source file shape: constants, state struct, helpers, frame loop |
| 04 | [04-build-and-verify.md](./04-build-and-verify.md) | `Cargo.toml`, `README.md`, build/run commands, acceptance walk-through |

## Decision log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Binding | `raylib = "5"` (raylib-rs) | Named in spec §10 ("Rust: Cargo.toml with raylib = '5'") |
| State shape | Six `let mut` locals in `main` | Spec §9 allows struct OR six locals; sibling ports all use locals, so this keeps the cross-language ergonomics comparison apples-to-apples. Helpers take what they need by value/`&str` rather than threading a `&mut Game`. |
| Rectangles | `const FOO_RECT: Rectangle = Rectangle { x: 80.0, y: 220.0, w: 240.0, h: 240.0 }` style | `raylib::Rectangle` uses `f32` fields; declaring them as consts avoids re-constructing per frame |
| Centering math | `let w = measure_text(text, size); let x = (WINDOW_W - w) / 2;` | `measure_text` is a free function in raylib-rs; no handle needed |
| Drawing handle lifetime | `let mut d = rl.begin_drawing(&thread);` per frame, in a scoped block so `d` drops (auto-`EndDrawing`) before the next loop step | RAII matches the binding's pattern; no manual `end_drawing` call |
| Color constants | `Color::RAYWHITE`, `Color::DARKGREEN`, etc. | All eight needed constants are exposed as `Color::*` associated constants in raylib-rs |
| Accumulator widening | `f64` field, widen `dt: f32` at the multiply | Spec §3 mandates 64-bit float for accumulator; `get_frame_time()` is `f32` |
| Single source file | Yes, `src/main.rs` only | Spec §9: "No modules, no multiple files." |
| Edition | `edition = "2021"` | Current stable Rust edition; nothing in the program needs 2024 features |

## Out of scope (per spec §1 and §11)

No save/load, no animations, no sound, no extra upgrades, no prestige. No
custom abstractions, no ECS, no traits, no `Option`/`Result` plumbing
beyond what raylib-rs's `init().build()` returns. No image, font, or audio
assets — default raylib font only.
