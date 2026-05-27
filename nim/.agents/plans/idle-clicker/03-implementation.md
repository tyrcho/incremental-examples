# 03 — Implementation (`src/idle_clicker.nim`)

Single-file Nim source, ~150 lines. This document gives the concrete
shape of the file in skeleton form; the implementer fills in the literal
draw calls. Each section maps 1:1 to a spec section.

## File layout

```
src/idle_clicker.nim
├── import raylib
├── import std/strformat
├── const WINDOW_W, WINDOW_H, FONT_*, *_Y, *_COST_INIT
├── const CLICK_BUTTON, CLICK_UPGRADE, PASSIVE_UPGRADE   (Rectangle)
├── proc nextCost(c: int32): int32                       (helper, §5)
├── proc drawCenteredText(...)                           (helper, §7 centering)
├── proc drawUpgradeButton(...)                          (helper, §7.6/§7.7)
└── proc main()
    ├── initWindow + setTargetFps
    ├── six state vars
    ├── while not windowShouldClose():
    │     dt -> passive tick -> input -> draw
    └── closeWindow()
when isMainModule: main()
```

That's it. No `Game` object, no submodules, no methods.

## Constants (spec §4)

```nim
const
  WINDOW_W: int32 = 800
  WINDOW_H: int32 = 600

  TITLE_Y:    int32 = 30
  CURRENCY_Y: int32 = 90
  PASSIVE_Y:  int32 = 140

  FONT_TITLE:  int32 = 36
  FONT_LARGE:  int32 = 28
  FONT_MEDIUM: int32 = 20
  FONT_SMALL:  int32 = 18

  CLICK_COST_INIT:   int32 = 10
  PASSIVE_COST_INIT: int32 = 25

  CLICK_BUTTON    = Rectangle(x: 80,  y: 220, width: 240, height: 240)
  CLICK_UPGRADE   = Rectangle(x: 400, y: 220, width: 320, height: 110)
  PASSIVE_UPGRADE = Rectangle(x: 400, y: 350, width: 320, height: 110)
```

All integer constants are `int32` because that's what naylib's draw and
measure procs take. `Rectangle` literals coerce integer fields to
`float32` automatically.

## State (spec §3)

Six `var` locals at the top of `main`. Spec §9 explicitly permits this.

```nim
var
  currency:    int64   = 0
  clickPower:  int32   = 1
  passiveRate: int32   = 0
  clickCost:   int32   = CLICK_COST_INIT
  passiveCost: int32   = PASSIVE_COST_INIT
  accumulator: float64 = 0.0
```

Nim's camelCase convention (`clickPower`, not `click_power`) matches
nimble/stdlib style; spec §1 says "idiomatic naming conventions".

## Helper: `nextCost` (spec §5)

```nim
proc nextCost(c: int32): int32 =
  (c * 3) div 2
```

One line, integer arithmetic only. `div` is truncating signed integer
division. For `c = 10`: `30 div 2 = 15`. For `c = 15`: `45 div 2 = 22`.
Matches the spec sequence exactly (10 → 15 → 22 → 33 → 49 → 73 → 109 →
163 → 244).

## Helper: `drawCenteredText`

Parameterized container — `(containerX, containerW)` — so it works for
both the window-wide readouts (title / currency / passive) and the two
`CLICK_BUTTON`-local label lines. Matches the C++/Crystal/Odin/Rust
sibling helpers.

```nim
proc drawCenteredText(text: string;
                      containerX, containerW, y, fontSize: int32;
                      color: Color) =
  let w = measureText(text, fontSize)
  let x = containerX + (containerW - w) div 2
  drawText(text, x, y, fontSize, color)
```

Used five times: title, currency readout, passive readout (each with
`containerX = 0, containerW = WINDOW_W`), and twice for the click-button
label lines (with `containerX = int32(CLICK_BUTTON.x)`,
`containerW = int32(CLICK_BUTTON.width)`).

## Helper: `drawUpgradeButton` (spec §7.6, §7.7)

The two upgrade buttons differ only in rect, the four label strings, and
the affordability bool. Spec §9 mandates a helper here ("required if it
would otherwise duplicate ~10 lines").

```nim
proc drawUpgradeButton(
    rec: Rectangle;
    title, levelLine, effectLine, costLine: string;
    affordable: bool) =
  let fill = if affordable: SkyBlue else: LightGray
  drawRectangle(
    int32(rec.x), int32(rec.y),
    int32(rec.width), int32(rec.height),
    fill)
  drawRectangleLinesEx(rec, 2.0'f32, DarkGray)

  let x = int32(rec.x) + 12'i32
  var y = int32(rec.y) + 4'i32
  drawText(title,      x, y, FONT_MEDIUM, Black);            y += FONT_MEDIUM + 4
  drawText(levelLine,  x, y, FONT_SMALL,  DarkGray);         y += FONT_SMALL  + 4
  drawText(effectLine, x, y, FONT_SMALL,  DarkGray);         y += FONT_SMALL  + 4
  let costColor = if affordable: Black else: Red
  drawText(costLine,   x, y, FONT_SMALL,  costColor)
```

Notes:

- `2.0'f32` makes the literal `float32` to match `drawRectangleLinesEx`'s
  thickness param. Same for `3.0'f32` on the click button.
- Vertical stacking: `rec.y + 4` start, then four lines with `+4` after
  each (spec §7.6: "stacked top to bottom with 4px padding").
- Horizontal: `rec.x + 12` (spec §7.6: "left-aligned 12px from the left
  edge of the rect").
- Param names `title / levelLine / effectLine / costLine` match the
  C++/Crystal/Odin/Rust sibling helpers — keeps call-sites readable
  without counting positional args.
- The caller is responsible for formatting `"Level: <N>"` and
  `"Cost: <N>"` — the helper takes finished strings. Keeps the helper's
  signature simple.

## `main`

The full structure. Order matches spec §6 exactly.

```nim
proc main() =
  initWindow(WINDOW_W, WINDOW_H, "Idle Clicker")
  setTargetFps(60)

  var
    currency:    int64   = 0
    clickPower:  int32   = 1
    passiveRate: int32   = 0
    clickCost:   int32   = CLICK_COST_INIT
    passiveCost: int32   = PASSIVE_COST_INIT
    accumulator: float64 = 0.0

  while not windowShouldClose():
    # §6 step 1
    let dt = getFrameTime()

    # §6 step 2 — passive income tick
    accumulator += float64(dt) * float64(passiveRate)
    while accumulator >= 1.0:
      currency += 1
      accumulator -= 1.0

    # §6 step 3 — input
    let mouse = getMousePosition()
    if isMouseButtonPressed(MouseButton.Left):
      if checkCollisionPointRec(mouse, CLICK_BUTTON):
        currency += int64(clickPower)
      elif checkCollisionPointRec(mouse, CLICK_UPGRADE) and
           currency >= int64(clickCost):
        currency -= int64(clickCost)
        clickPower += 1
        clickCost = nextCost(clickCost)
      elif checkCollisionPointRec(mouse, PASSIVE_UPGRADE) and
           currency >= int64(passiveCost):
        currency -= int64(passiveCost)
        passiveRate += 1
        passiveCost = nextCost(passiveCost)

    # §6 step 4 — draw
    beginDrawing()
    clearBackground(RayWhite)

    # §7.2 title
    drawCenteredText("Idle Clicker",
                     0'i32, WINDOW_W, TITLE_Y, FONT_TITLE, DarkGray)

    # §7.3 currency
    drawCenteredText(&"Currency: {currency}",
                     0'i32, WINDOW_W, CURRENCY_Y, FONT_LARGE, Black)

    # §7.4 passive readout
    drawCenteredText(&"+{passiveRate}/sec",
                     0'i32, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DarkGreen)

    # §7.5 click button
    drawRectangle(
      int32(CLICK_BUTTON.x), int32(CLICK_BUTTON.y),
      int32(CLICK_BUTTON.width), int32(CLICK_BUTTON.height),
      Green)
    drawRectangleLinesEx(CLICK_BUTTON, 3.0'f32, DarkGreen)
    block:
      # two-line label, vertically centered in CLICK_BUTTON
      let totalH = FONT_TITLE + FONT_LARGE
      let topY = int32(CLICK_BUTTON.y) +
                 (int32(CLICK_BUTTON.height) - totalH) div 2
      let cx  = int32(CLICK_BUTTON.x)
      let cw  = int32(CLICK_BUTTON.width)
      drawCenteredText("CLICK",            cx, cw, topY,              FONT_TITLE, Black)
      drawCenteredText(&"(+{clickPower})", cx, cw, topY + FONT_TITLE, FONT_LARGE, Black)

    # §7.6 click upgrade
    let clickAffordable = currency >= int64(clickCost)
    drawUpgradeButton(
      CLICK_UPGRADE,
      "Click Power",
      &"Level: {clickPower}",
      "+1 per click",
      &"Cost: {clickCost}",
      clickAffordable)

    # §7.7 passive upgrade
    let passiveAffordable = currency >= int64(passiveCost)
    drawUpgradeButton(
      PASSIVE_UPGRADE,
      "Passive Income",
      &"Level: {passiveRate}",
      "+1 per second",
      &"Cost: {passiveCost}",
      passiveAffordable)

    endDrawing()

  closeWindow()

when isMainModule:
  main()
```

That's the whole program. About 110–130 lines depending on formatting.

## Subtleties to get right

- **Order of operations** — spec §6 mandates passive tick before input
  within the same frame. Don't fold them.
- **Accumulator semantics** — `passive_rate = 0` must produce zero ticks
  regardless of `dt`. The multiply by zero in the accumulator update
  handles this; no special case needed.
- **Integer cost formula** — use `div`, not `/`. Spec §5 forbids float
  promotion; the truncating sequence is part of the contract. In Nim,
  `(c * 3) / 2` would not even compile when assigned to `int32` — but
  it's the kind of mistake worth flagging.
- **`int64` ↔ `int32` casts** — Nim does not auto-widen. Cast `int32`
  values to `int64` at compare/assign sites that touch `currency`.
  Otherwise the compiler will refuse with a "type mismatch" error,
  which is the right behavior — fix it with `int64(...)`.
- **`float32` literals for raylib** — `drawRectangleLinesEx` thickness
  is `float32`; write `2.0'f32` and `3.0'f32` to avoid the default
  `float64` literal type.
- **Only the API in spec §8** — resist `drawing:` template,
  `drawRectangleRec`, `drawTextEx`, `Fade`, etc. They are not in the
  allow-list.
- **No assets** — `drawText` uses the default font baked into raylib.
  Do not `loadFont`.
- **`MouseButton.Left`** — modern naylib name. If the installed naylib
  is old enough to only have `MouseButtonLeft` (unscoped), fall back to
  that; spec §8 allows the older name.
- **Click hits one thing per frame** — the `elif` chain in §6 step 3 is
  required; do not let a single click both spend currency and earn it.
- **`block:` for the click-button label** — the inner `let`/`var`
  bindings shadow nothing important, but the block keeps them
  visually grouped and signals "this is the §7.5 stanza".

## Line count target

State + constants + three procs + `main` body ≈ 130 lines including
blank lines. If the file exceeds ~200 lines, look for accidental
duplication (most likely: the upgrade-button block was not factored).

## Behavioral checklist (cross-reference to spec §11)

| Acceptance criterion | Where it's implemented |
|---|---|
| Window 800×600 titled "Idle Clicker", solid white | `initWindow(WINDOW_W, WINDOW_H, "Idle Clicker")` + `clearBackground(RayWhite)` |
| Clicking green square: `currency += click_power` | `checkCollisionPointRec(mouse, CLICK_BUTTON)` branch |
| Click button label shows current `click_power` | `&"(+{clickPower})"` per frame |
| Upgrade buttons show level/effect/cost; cost red when broke; fill gray when broke | `drawUpgradeButton` + `affordable` flag |
| Buying click upgrade: deduct, +1 power, scale cost | Click-upgrade branch + `nextCost(clickCost)` |
| Buying passive upgrade: deduct, +1 rate, scale cost | Passive-upgrade branch + `nextCost(passiveCost)` |
| `passive_rate = N` ⇒ currency ticks +N per real-world second | `accumulator` loop in §6 step 2 |
| Clean exit, no panics/leaks | `closeWindow()` after the loop; ORC handles strformat allocations |
| Release-build runs without extra runtime deps | naylib statically links raylib at build time |
