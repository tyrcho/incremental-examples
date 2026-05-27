# 03 — Acceptance Checklist

Manual verification, in order. Each item maps to a clause in spec §11. Run from a release build (`cmake --build build --config Release` or `-O2` with the `g++` line).

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

- [ ] `main.cpp` is a single file, ≤ ~200 lines.
- [ ] No `#include` of any third-party header other than `<raylib.h>` and the C++ standard library.
- [ ] `grep -E 'Load(Texture|Font|Sound|Image)|DrawTextEx|DrawRectangleRec|Fade' main.cpp` returns nothing.
- [ ] CMake configure + build runs clean with no warnings at default flags.
- [ ] Resulting binary launches with no extra files alongside it (no `assets/`, no font files).

## What I am explicitly not testing

- Save/load (not in spec).
- Animations or sound (not in spec).
- Keyboard input (not in spec).
- Resize behavior — the spec fixes window size and does not require resize handling.
