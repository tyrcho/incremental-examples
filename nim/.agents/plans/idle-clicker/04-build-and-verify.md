# 04 — Build, Run, and Verify

## Directory layout

```
incremental-examples/nim/
├── idle_clicker.nimble
├── README.md
└── src/
    └── idle_clicker.nim
```

Keep the project self-contained. nimble defaults to `src/` for the source
root when the `srcDir` is set in the manifest, which matches the layout
above.

## `idle_clicker.nimble`

Place at `incremental-examples/nim/idle_clicker.nimble`. Minimal, exactly
what spec §10 calls for:

```nim
# Package
version       = "0.1.0"
author        = "Birb Party"
description   = "Minimal idle clicker built with naylib (raylib)."
license       = "MIT"
srcDir        = "src"
bin           = @["idle_clicker"]

# Dependencies
requires "nim >= 2.0.0"
requires "naylib >= 5.0.0"
```

Nothing else. No dev-dependencies, no tasks, no `--threads:on`, no custom
build hooks. naylib's installation pulls and builds raylib's C sources
locally; the resulting binary is statically linked against raylib by
default — matching spec §11's "runs without external runtime
dependencies".

## Install dependencies

```bash
cd incremental-examples/nim
nimble install -d   # installs deps only, no build
```

First-time `naylib` install compiles raylib's C sources. On macOS this
requires Xcode command-line tools (typically already present in dev
environments). No Homebrew dependency.

If on Linux: the standard X11 / OpenGL headers (e.g.,
`libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev
libgl-dev`) need to be available for naylib's bundled raylib to build.
Distro package names vary; the naylib README has up-to-date instructions.

## Build commands

```bash
cd incremental-examples/nim
nimble build -d:release
./idle_clicker
```

Or, without nimble's binary-layout dance, directly via the Nim compiler:

```bash
nim c -d:release --outdir:. src/idle_clicker.nim
./idle_clicker
```

Both produce a release-optimized binary. The nimble path is preferred
because the `.nimble` manifest declares the binary name and links
naylib's compile-time settings correctly.

## `README.md`

Place at `incremental-examples/nim/README.md`. Spec §10: "one-paragraph
description, build command, run command, controls (just 'left-click')."

Contents (verbatim — short on purpose):

```markdown
# Idle Clicker (Nim + naylib)

A minimal idle clicker built with naylib, the Nim wrapper around raylib.
Click the green square to earn currency. Buy upgrades on the right to
increase your per-click yield or earn passive income per second. Costs
scale 1.5× per purchase.

## Build

    nimble install -d
    nimble build -d:release

(The first `nimble install` compiles naylib's bundled raylib C sources;
expect a couple of minutes. Subsequent builds are fast.)

## Run

    ./idle_clicker

## Controls

Left-click. That's all.
```

No additional sections (no "Architecture", no "Contributing"). Spec §1:
"Not add features beyond those specified."

## First-build notes

- naylib runs its raylib C-source compile during `nimble install`, not
  `nimble build`. If `nimble build` re-triggers raylib compilation,
  something is wrong with the cache; clear `~/.nimble/pkgs2/naylib-*`
  and reinstall.
- On macOS with Apple Silicon, naylib produces a universal-friendly
  arm64 binary by default. No special flags needed.
- ORC is Nim 2.x's default; you don't need to pass `--mm:orc`. If for
  some reason the build is on Nim 1.6.x, add `--mm:orc` (or `--mm:arc`)
  to the build command — refc would also work given the tiny string
  churn, but ORC matches the Nim 2.x baseline.

## Acceptance checklist

Manual verification, in order. Each item maps to a clause in spec §11.
Run from a release build (`nimble build -d:release` then
`./idle_clicker`).

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
      purchases (spec mandates `isMouseButtonPressed`, which fires
      once per press).

### Build hygiene

- [ ] `src/idle_clicker.nim` is a single file, ≤ ~200 lines.
- [ ] Only two `import`s: `raylib`, `std/strformat`. No `std/options`,
      no `std/sugar`, no `std/sequtils`.
- [ ] `grep -E 'loadTexture|loadFont|loadSound|loadImage|drawTextEx|Fade' src/idle_clicker.nim`
      returns nothing.
- [ ] `grep -E '\bobject\b|\bmethod\b|\btemplate\b|\bmacro\b' src/idle_clicker.nim`
      returns nothing of our own — `Rectangle`, `Color`, `Vector2`
      references are fine because they come from naylib.
- [ ] `nimble build -d:release` completes with no warnings other than
      naylib's own (which we don't suppress).
- [ ] Release-build runs without external runtime deps. On macOS,
      `otool -L ./idle_clicker` shows only system frameworks (Cocoa,
      OpenGL, IOKit, etc.) — no Homebrew or other third-party
      `.dylib`s. On Linux, `ldd ./idle_clicker` shows only system libs
      (libc, libm, libGL, libX11, …) — no `libraylib.so`, because
      raylib is statically linked.
- [ ] Resulting binary launches with no extra files alongside it (no
      `assets/`, no font files).

### Nim-specific gotchas to re-verify

These are easy to get wrong on the way in and are called out in
`03-implementation.md`. Worth a second pass during acceptance:

- [ ] State widths match spec §3 exactly: `currency: int64`,
      `clickPower / passiveRate / clickCost / passiveCost: int32`,
      `accumulator: float64`. Not `int` (which is machine-word).
- [ ] Accumulator update casts both operands to `float64`:
      `accumulator += float64(dt) * float64(passiveRate)`. Nim will
      not implicitly widen `float32` to `float64`.
- [ ] Currency / cost comparisons widen the `int32` cost to `int64`:
      `currency >= int64(clickCost)`. Likewise
      `currency -= int64(clickCost)` and `currency += int64(clickPower)`.
- [ ] Cost-scaling proc uses `div` (truncating integer division), not
      `/` (which would return a `float` in Nim): `(c * 3) div 2`.
- [ ] Float32 literals (`2.0'f32`, `3.0'f32`) used for
      `drawRectangleLinesEx` thickness — no compile error about
      `float` not matching `float32`.
- [ ] `MouseButton.Left` (modern naylib name). If the installed naylib
      only has `MouseButtonLeft` (unscoped), fall back to that —
      spec §8 allows the older name.

### Smoke test

A short automated smoke that the implementer can run after writing
the code:

```bash
nim check src/idle_clicker.nim    # type-check, no codegen
nimble build -d:release            # full build
./idle_clicker &
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

- **No unit tests.** Spec §9 forbids "abstractions"; there's nothing to
  unit-test except `nextCost`, which is one line. A `tests/` directory
  would itself violate "Single source file. No modules, no multiple
  files."
- **No CI integration.** This is one of five parallel single-file ports
  living under `incremental-examples/`; CI is not part of the spec.
- **No benchmarks.** 60 fps on a 200-line raylib program is
  uninteresting to measure.
- **No `nimble test`.** No `tests/` directory exists.

## Done criteria

The plan is complete when, in `incremental-examples/nim/`:

```
idle_clicker.nimble
README.md
src/
└── idle_clicker.nim
```

…exist, `nimble build -d:release` succeeds, the binary opens the
window, and all nine acceptance criteria in spec §11 pass on manual
review.
