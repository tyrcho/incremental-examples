# 04 — Build, Run, and Verify

## `Cargo.toml`

Place at `incremental-examples/rust/Cargo.toml`:

```toml
[package]
name = "idle_clicker"
version = "0.1.0"
edition = "2021"

[dependencies]
raylib = "5"

[profile.release]
opt-level = 3
lto = "thin"
```

Spec §10 says `raylib = "5"` and `cargo run --release`. The
`[profile.release]` block is optional but matches the expectation that
the binary is release-built; `lto = "thin"` keeps link time modest.

Nothing else in `Cargo.toml`. No dev-dependencies (no test binaries),
no features, no build-script. The `raylib` crate's `build.rs` handles
fetching/compiling raylib's C source on first build, and produces a
statically-linked binary by default — matching spec §11's "runs
without external runtime dependencies".

## `README.md`

Place at `incremental-examples/rust/README.md`. Spec §10: "one-paragraph
description, build command, run command, controls (just 'left-click')."

Contents:

```markdown
# Idle Clicker (Rust + raylib)

A minimal idle clicker built with raylib-rs. Click the green square to
earn currency. Buy upgrades on the right to increase your per-click
yield or earn passive income per second. Costs scale 1.5× per purchase.

## Build

    cargo build --release

(First build compiles bundled raylib C sources; expect a couple of
minutes. Subsequent builds are fast.)

## Run

    cargo run --release

## Controls

Left-click. That's all.
```

No additional sections (no "Architecture", no "Contributing"). Spec §1:
"Not add features beyond those specified."

## First-build notes

The `raylib` crate's `build.rs` compiles raylib's C sources via
`cmake-rs`. On macOS this requires Xcode command-line tools (already
present in this dev env). No `pkg-config`, no Homebrew dependency.
First build is ~1–3 minutes; rebuilds are seconds.

If `cargo build --release` fails with a linker error about CoreVideo /
IOKit / Cocoa frameworks, that's a missing Xcode CLI tools install —
`xcode-select --install` and retry. (Not expected on this machine; this
is the standard recovery step.)

## Acceptance checklist

Manual verification, in order. Each item maps to a clause in spec §11.
Run from a release build (`cargo build --release` then
`./target/release/idle_clicker`, or `cargo run --release` for a one-shot).

### Window and chrome

- [ ] Window opens at exactly 800 × 600.
- [ ] Title bar reads `Idle Clicker`.
- [ ] Background is solid white (`RAYWHITE`).
- [ ] Closing the window via the OS close button exits cleanly — no
      stderr output, no panic, no leaked process. `echo $?` is `0`.

### Static layout

- [ ] Title text `Idle Clicker` is horizontally centered near the top
      in dark gray at y ≈ 30.
- [ ] Currency line `Currency: 0` is centered in black below the title
      at y ≈ 90.
- [ ] Passive readout `+0/sec` is centered in dark green below the
      currency line at y ≈ 140.
- [ ] Green click square is in the left half of the screen at
      `(80, 220, 240, 240)` with a 3px dark-green outline.
- [ ] Two upgrade panels stack on the right at `(400, 220, 320, 110)`
      and `(400, 350, 320, 110)` with 2px dark-gray outlines.

### Click button behavior

- [ ] Clicking the green square once with `click_power = 1` increments
      `Currency` from 0 to 1.
- [ ] Click button shows `CLICK` on top and `(+1)` below, both centered
      horizontally in the square and the pair vertically centered.
- [ ] After buying click upgrade, the `(+N)` line updates to reflect
      the new `click_power` on the next frame.
- [ ] Clicks outside any of the three rectangles do nothing.

### Click upgrade

- [ ] At currency < 10, the click-upgrade fill is `LIGHTGRAY` and
      `Cost: 10` is red.
- [ ] Once currency ≥ 10, fill is `SKYBLUE` and `Cost: 10` is black.
- [ ] Purchasing deducts the current cost, increments `click_power`
      by 1, and updates `Cost:` to the next value in the sequence:
      10 → 15 → 22 → 33 → 49 → 73 → 109 → 163 → 244.
- [ ] `Level:` line increments by 1 per purchase.

### Passive upgrade

- [ ] Identical affordability behavior against `passive_cost`.
- [ ] Purchase deducts cost, increments `passive_rate` by 1, scales
      cost: 25 → 37 → 55 → 82 → 123 → 184 → 276.
- [ ] After first purchase, `+1/sec` shows in the passive readout and
      `Currency` increases by exactly 1 per real-world second (no
      fractional display, no double-ticks).
- [ ] With `passive_rate = 10`, currency increments by exactly 10 per
      second. Measure over 10 seconds: gain should be 100 ± 1 (the ±1
      is the in-flight accumulator at sample time).

### Negative / edge cases

- [ ] With `passive_rate = 0`, currency never auto-increments
      regardless of how long the window stays open.
- [ ] Attempting to buy when currency < cost has no effect — no
      deduction, no level-up, no crash.
- [ ] Holding the mouse button down does not register repeated
      purchases (spec mandates `IsMouseButtonPressed`, which fires
      once per press).

### Build hygiene

- [ ] `src/main.rs` is a single file, ≤ ~200 lines.
- [ ] Only `use raylib::prelude::*;` — no third-party crates beyond
      `raylib` itself.
- [ ] `grep -E 'load_texture|load_font|load_sound|load_image|draw_text_ex|fade' src/main.rs`
      returns nothing.
- [ ] `cargo build --release` completes with no warnings.
- [ ] Release-build runs without external runtime deps. On macOS,
      `otool -L target/release/idle_clicker` shows only system
      frameworks (Cocoa, OpenGL, IOKit, etc.) — no Homebrew or other
      third-party `.dylib`s. On Linux, `ldd` shows only system libs.
- [ ] Resulting binary launches with no extra files alongside it
      (no `assets/`, no font files).

### Rust-specific gotchas to re-verify

These are easy to get wrong on the way in and are called out in
`03-implementation.md`. Worth a second pass during acceptance:

- [ ] State widths match spec §3 exactly: `currency: i64`,
      `click_power / passive_rate / click_cost / passive_cost: i32`,
      `accumulator: f64`. Not `i32` for currency, not `f32` for the
      accumulator.
- [ ] Accumulator update casts both operands to `f64`:
      `accumulator += (dt as f64) * (passive_rate as f64)`. Rust will
      not implicitly widen `f32` to `f64`.
- [ ] Currency / cost comparisons widen the `i32` cost to `i64`:
      `currency >= click_cost as i64`. Likewise
      `currency -= click_cost as i64` and `currency += click_power as i64`.
- [ ] Cost-scaling fn returns `i32` so the sequence is reproducible
      across host word sizes: `fn next_cost(c: i32) -> i32`.
- [ ] No `.unwrap()`, no `?`, no `panic!` in the source.
      `raylib::init().build()` is infallible in 5.x.
- [ ] Drawing handle (`d`) is scoped in a block so it drops before the
      next loop iteration (`EndDrawing` runs implicitly). All input
      reads happen on `rl` *before* `begin_drawing` to avoid the
      borrow-checker pulling `rl` out from under `d`.

### Smoke test

A short automated smoke that the implementer can run after writing
the code:

```bash
cargo check --release      # compiles, no link
cargo clippy -- -D warnings # catches obvious issues (optional)
cargo build --release       # full link
./target/release/idle_clicker &
PID=$!
sleep 2
kill $PID
wait $PID 2>/dev/null
```

If the binary launches and survives 2 seconds without crashing, the
init/draw loop is healthy. The interactive checks (Click button,
upgrade purchases, passive ticks) still require a human at the
keyboard.

## Out of scope for verification

- **No unit tests.** Spec §9 forbids "abstractions"; there's nothing
  to unit-test except `next_cost`, which is one line. A test file
  would itself violate "Single source file. No modules, no multiple
  files."
- **No CI integration.** This is one of five parallel single-file
  ports living under `incremental-examples/`; CI is not part of the
  spec.
- **No benchmarks.** 60 fps on a 200-line raylib program is
  uninteresting to measure.

## Done criteria

The plan is complete when, in `incremental-examples/rust/`:

```
Cargo.toml
README.md
src/
└── main.rs
```

…exist, `cargo build --release` succeeds, the binary opens the window,
and all nine acceptance criteria in spec §11 pass on manual review.
