# 03 — Acceptance Checklist

Manual verification, in order. Each item maps to a clause in spec §11. Run from a release build (`shards build --release --no-debug` → `./bin/idle_clicker`). The binding strategy is the hand-rolled `lib LibRaylib` FFI block from `02-implementation.md` — no `raylib-cr` or other shard is used.

## Pre-gate: toolchain installed

- [ ] `crystal --version` and `shards --version` both work (Homebrew install succeeded).
- [ ] `ls /opt/homebrew/lib/libraylib*` (or `/usr/local/lib/libraylib*` on Intel) shows the dylib.
- [ ] `shards build --release --no-debug` succeeds without `ld: library not found` errors.

If any of these fails, the rest of the list is moot — fix the toolchain first. The optional FFI smoke test in `01-setup-and-build.md` can confirm everything end-to-end before writing the full implementation.

## Window and chrome

- [ ] Window opens at exactly 800 × 600.
- [ ] Title bar reads `Idle Clicker`.
- [ ] Background is solid white (`RAYWHITE`).
- [ ] Closing the window via the OS close button exits cleanly — no stderr output, no Crystal exception, no leaked process. `echo $?` is `0`.

## Static layout

- [ ] Title text `Idle Clicker` is horizontally centered near the top in dark gray at y ≈ 30.
- [ ] Currency line `Currency: 0` is centered in black below the title at y ≈ 90.
- [ ] Passive readout `+0/sec` is centered in dark green below the currency line at y ≈ 140.
- [ ] Green click square is in the left half of the screen at `(80, 220, 240, 240)` with a 3px dark-green outline.
- [ ] Two upgrade panels stack on the right at `(400, 220, 320, 110)` and `(400, 350, 320, 110)` with 2px dark-gray outlines.

## Click button behavior

- [ ] Clicking the green square once with `click_power = 1` increments `Currency` from 0 to 1.
- [ ] Click button shows `CLICK` on top and `(+1)` below, both centered horizontally in the square and the pair vertically centered.
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
- [ ] Holding the mouse button down does not register repeated purchases (spec mandates `IsMouseButtonPressed`/`mouse_button_pressed?`, which fires once per press).

## Build hygiene

- [ ] `src/idle_clicker.cr` is a single file, ≤ ~250 lines (FFI block adds ~30 lines vs. sibling ports' ~200 budget).
- [ ] No `require` other than `lib_c` (the standard library is implicit and does not count). No `require "raylib-cr"`, no `require "cray"`.
- [ ] `grep -E 'load_texture|load_font|load_sound|load_image|draw_text_ex|draw_rectangle_rec|fade' src/idle_clicker.cr` returns nothing.
- [ ] `grep -E '\bfun\b' src/idle_clicker.cr` returns exactly the ~14 functions in spec §8 — no extra `fun` declarations.
- [ ] `shards build --release --no-debug` runs clean: no warnings on default flags. Linker resolves raylib against Homebrew's dylib (`otool -L bin/idle_clicker` shows `libraylib.dylib`).
- [ ] Resulting `bin/idle_clicker` launches with no extra files alongside it (no `assets/`, no font files).
- [ ] No `class`, `module`, or `record` defined in the source. The only `lib` block is `LibRaylib`; the only `struct`s are inside that `lib` block (`Color`, `Vector2`, `Rectangle`). Helpers are top-level `def`s.

## Crystal-specific guardrails

- [ ] The loop condition is `until LibRaylib.window_should_close` and the teardown is `LibRaylib.close_window` (different names — no `?` collision because we control the FFI bindings).
- [ ] `currency` is typed `Int64` (initialized `0_i64`). String interpolation produces e.g. `Currency: 1000000` correctly with no overflow concerns up to 9.2 × 10¹⁸.
- [ ] `next_cost(10)` returns `15` — quick interactive check via `crystal eval 'puts (10 * 3) / 2'`.
- [ ] Float32 literals (`3.0_f32`, `2.0_f32`) used for `draw_rectangle_lines_ex` thickness — no compile error about `Float64` not matching `Float32`.
- [ ] FFI block declares exactly the spec §8 functions, no more. Color constants (`RAYWHITE`, `BLACK`, …) are user-defined `LibRaylib::Color` values, not pulled from a shard.
- [ ] `MOUSE_BUTTON_LEFT = 0` constant exists and is passed to `is_mouse_button_pressed` (per spec §8 the older integer enum form is allowed).

## What this list explicitly does not test

- Save/load (not in spec).
- Animations or sound (not in spec).
- Keyboard input (not in spec).
- Resize behavior — the spec fixes window size and does not require resize handling.
- Behavior on non-macOS platforms — the deliverable lives in this repo; the implementer can verify Linux/Windows separately if they care.
