# 03 — Acceptance Checklist

Manual verification, in order. Each item maps to a clause in spec §11. Run against a release build (`odin build . -o:speed -out:idle_clicker` then `./idle_clicker`, or `odin run . -o:speed` for a one-shot).

## Window and chrome

- [ ] Window opens at exactly 800 × 600.
- [ ] Title bar reads `Idle Clicker`.
- [ ] Background is solid white (`RAYWHITE`).
- [ ] Closing the window via the OS close button exits cleanly — no stderr output, no crash, no leaked process.

## Static layout

- [ ] Title text `Idle Clicker` is horizontally centered near the top.
- [ ] Currency line `Currency: 0` is centered below the title.
- [ ] Passive readout `+0/sec` is centered in dark green below the currency line.
- [ ] Green click square is in the left half of the screen at `(80, 220, 240, 240)` with a darker 3px outline.
- [ ] Two upgrade panels stack on the right at `(400, 220, 320, 110)` and `(400, 350, 320, 110)` with 2px dark-gray outlines.

## Click button behavior

- [ ] Clicking the green square once with `click_power = 1` increments `Currency` from 0 to 1.
- [ ] Click button shows `CLICK` on top and `(+1)` below, both centered in the square.
- [ ] After buying click upgrade, the `(+N)` line updates to reflect the new `click_power` on the next frame.
- [ ] Clicks outside any of the three rectangles do nothing.

## Click upgrade

- [ ] At currency < 10, the click-upgrade fill is `LIGHTGRAY` and `Cost: 10` is red.
- [ ] Once currency ≥ 10, fill is `SKYBLUE` and `Cost: 10` is black.
- [ ] Purchasing deducts the current cost, increments `click_power` by 1, and updates `Cost:` to the next value in the sequence: 10 → 15 → 22 → 33 → 49 → 73 → 109 → 163 → 244.
- [ ] `Level:` line increments by 1 per purchase.

## Passive upgrade

- [ ] Identical affordability behavior against `passive_cost`.
- [ ] Purchase deducts cost, increments `passive_rate` by 1, scales cost: 25 → 37 → 55 → 82 → 123 → 184 → 276.
- [ ] After first purchase, `+1/sec` shows in the passive readout and `Currency` increases by exactly 1 per real-world second (no fractional display, no double-ticks).
- [ ] With `passive_rate = 10`, currency increments by exactly 10 per second. Measure over 10 seconds: gain should be 100 ± 1 (the ±1 is the in-flight accumulator at sample time).

## Negative / edge cases

- [ ] With `passive_rate = 0`, currency never auto-increments regardless of how long the window stays open.
- [ ] Attempting to buy when currency < cost has no effect — no deduction, no level-up, no crash.
- [ ] Holding the mouse button down does not register repeated purchases (spec mandates `IsMouseButtonPressed`, which fires once per press).

## Build hygiene

- [ ] `main.odin` is a single file, ≤ ~200 lines.
- [ ] Only two imports: `import rl "vendor:raylib"` and `import "core:fmt"`. No third-party Odin packages.
- [ ] `grep -E 'Load(Texture|Font|Sound|Image)|DrawTextEx|DrawRectangleRec|Fade' main.odin` returns nothing.
- [ ] `odin build . -o:speed` completes with no warnings.
- [ ] `defer free_all(context.temp_allocator)` is present as the first statement inside the main loop (catches the silent temp-allocator-growth leak).
- [ ] No `using rl` — every raylib call is `rl.<Name>(...)`.
- [ ] Resulting binary launches with no extra files alongside it (no `assets/`, no font files). The bundled `vendor:raylib` static library is linked into the binary at build time, so deployment is one file.
- [ ] `README.md` exists alongside `main.odin` and contains the four sections required by spec §10: description paragraph, build command, run command, controls.

## Odin-specific gotchas to re-verify

These are easy to get wrong on the way in and have all been called out in `02-implementation.md`. Worth a second pass during acceptance:

- [ ] State widths match spec §3 exactly: `currency: i64`, `click_power/passive_rate/click_cost/passive_cost: i32`, `accumulator: f64`. Not `int`, not `f32`.
- [ ] Accumulator update casts both operands to `f64`: `accumulator += f64(dt) * f64(passive_rate)`. Compiler will not implicitly widen `f32` to `f64`.
- [ ] Currency / cost comparisons widen the `i32` cost to `i64`: `currency >= i64(click_cost)`. Likewise `currency -= i64(click_cost)` and `currency += i64(click_power)`.
- [ ] Cost-scaling proc returns `i32` (not `int`) so the sequence is reproducible across host word sizes: `next_cost :: proc(c: i32) -> i32`.
- [ ] Dynamic strings are built with `fmt.ctprintf` and passed as `cstring`. No `strings.clone_to_cstring` plus manual `delete` (would work but is more code than needed).

## What I am explicitly not testing

- Save/load (not in spec).
- Animations or sound (not in spec).
- Keyboard input (not in spec).
- Resize behavior — the spec fixes window size and does not require resize handling.
- Cross-compilation (`-target:linux_amd64` etc.) — the deliverable is for the host triple. Cross-compilation works with `vendor:raylib` because every supported target ships a prebuilt static lib, but that is out of scope for acceptance.
