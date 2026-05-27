# 02 — Implementation Walkthrough

Target: a single `main.odin`, ~120–180 lines, `package main`, `vendor:raylib` only. Spec section references in parentheses.

## Binding cheat sheet

`vendor:raylib` keeps the C names verbatim (PascalCase) and exposes them under whatever alias you give the import. By convention that's `rl`. The table below maps every spec §8 call to its Odin invocation — internalize this and the rest of the walkthrough won't need to re-quote.

| C / spec name | `vendor:raylib` call |
|---|---|
| `InitWindow` | `rl.InitWindow(w, h, title)` — title is `cstring` |
| `CloseWindow` | `rl.CloseWindow()` |
| `WindowShouldClose` | `rl.WindowShouldClose()` — returns `bool` |
| `SetTargetFPS` | `rl.SetTargetFPS(60)` |
| `BeginDrawing` | `rl.BeginDrawing()` |
| `EndDrawing` | `rl.EndDrawing()` |
| `ClearBackground` | `rl.ClearBackground(rl.RAYWHITE)` |
| `DrawRectangle` | `rl.DrawRectangle(x, y, w, h, color)` — coords are `c.int` |
| `DrawRectangleLinesEx` | `rl.DrawRectangleLinesEx(rect, line_thick, color)` — `line_thick` is `f32` |
| `DrawText` | `rl.DrawText(text, x, y, font_size, color)` — text is `cstring` |
| `MeasureText` | `rl.MeasureText(text, font_size)` — returns `c.int` |
| `GetMousePosition` | `rl.GetMousePosition()` — returns `rl.Vector2` |
| `IsMouseButtonPressed` | `rl.IsMouseButtonPressed(.LEFT)` |
| `GetFrameTime` | `rl.GetFrameTime()` — returns `f32` |
| `CheckCollisionPointRec` | `rl.CheckCollisionPointRec(point, rect)` |
| Colors | `rl.RAYWHITE`, `rl.BLACK`, `rl.DARKGRAY`, `rl.LIGHTGRAY`, `rl.GREEN`, `rl.DARKGREEN`, `rl.SKYBLUE`, `rl.RED` |
| `Rectangle` literal | `rl.Rectangle{x = 80, y = 220, width = 240, height = 240}` — fields are `f32` |
| `MOUSE_BUTTON_LEFT` | enum value `rl.MouseButton.LEFT`; implicit selector `.LEFT` works at the call site because the proc parameter type is `MouseButton` |

`rl.Rectangle` is `struct { x, y, width, height: f32 }`. `rl.Vector2` is `struct { x, y: f32 }`. Untyped integer literals coerce into the `f32` fields fine — no need to write `80.0`.

## File outline

```odin
package main

import rl "vendor:raylib"
import "core:fmt"

// 1. Constants (spec §4)
// 2. Helpers: next_cost, draw_centered_text, draw_upgrade_button
// 3. main: init, loop, close
```

No other imports needed. `core:fmt` is for `fmt.ctprintf` (cstring-returning printf into the temp allocator) — see "Dynamic strings" below.

## Constants block (spec §4)

Package-scope `::` constants. Integer constants are untyped by default; pass a type when the call site needs disambiguation.

```odin
WINDOW_W :: 800
WINDOW_H :: 600

TITLE_Y     :: 30
CURRENCY_Y  :: 90
PASSIVE_Y   :: 140

FONT_TITLE  :: 36
FONT_LARGE  :: 28
FONT_MEDIUM :: 20
FONT_SMALL  :: 18

CLICK_BUTTON    :: rl.Rectangle{x =  80, y = 220, width = 240, height = 240}
CLICK_UPGRADE   :: rl.Rectangle{x = 400, y = 220, width = 320, height = 110}
PASSIVE_UPGRADE :: rl.Rectangle{x = 400, y = 350, width = 320, height = 110}
```

`rl.Rectangle{...}` is a compile-time-constructible struct literal, so it works in a `::` constant. No `static const` workaround needed (cf. the C++ plan).

If a particular Odin version rejects the struct literal as not constant-evaluable ("expression is not constant"), fall back to `:=` at package scope:

```odin
CLICK_BUTTON    := rl.Rectangle{x =  80, y = 220, width = 240, height = 240}
```

These become package-level `var`s instead of true constants, but for this program the semantics are identical — nothing mutates them, and the call sites read them the same way. Prefer `::` if your Odin accepts it.

## State (spec §3)

Six locals at the top of `main`. The spec explicitly allows "just six locals in main" — take that option; no `State` struct.

```odin
currency:     i64 = 0
click_power:  i32 = 1
passive_rate: i32 = 0
click_cost:   i32 = 10
passive_cost: i32 = 25
accumulator:  f64 = 0.0
```

Explicit type annotations lock the widths from the spec. Odin's default `int` is machine-word; we want the exact widths (i64, i32, f64) the spec mandates so the cost-scaling sequence and currency display match the other implementations bit-for-bit.

## Helpers

### Cost scaling (spec §5)

```odin
next_cost :: proc(c: i32) -> i32 {
    return (c * 3) / 2
}
```

Odin's `/` on signed integers truncates toward zero — same semantics as C `/` and the spec §5 formula. Do not introduce an `f32` cast; spec §5 explicitly forbids it and the integer sequence (10 → 15 → 22 → 33 → 49 → …) is part of the contract.

### Centered text

Spec §7: use `MeasureText(text, fontSize)`, then `x = (container_w - text_w) / 2 + container_x`.

```odin
draw_centered_text :: proc(text: cstring, container_x, container_w, y, font: i32, color: rl.Color) {
    tw := rl.MeasureText(text, font)
    rl.DrawText(text, container_x + (container_w - tw) / 2, y, font, color)
}
```

`rl.MeasureText` returns `c.int` (typically i32). Mixing it with `i32` parameters in the arithmetic works directly. If the binding's exact return is `c.int` and the compiler complains about the mix, cast with `i32(...)` at the call site rather than weakening parameter types.

For the click button's two stacked centered lines (spec §7.5), compute the block height once and place the two lines so the pair is vertically centered:

- Block height = `FONT_TITLE + FONT_LARGE` (no inter-line padding called out in spec).
- `top_y = i32(CLICK_BUTTON.y) + (i32(CLICK_BUTTON.height) - block_h) / 2`
- Line 1 y = `top_y`; line 2 y = `top_y + FONT_TITLE`.

Cast `rl.Rectangle` field reads (`f32`) to `i32` with `i32(...)` at the call site. Do not cache an Int copy of geometry — the constants are already `f32` in `rl.Rectangle` form, and a parallel int snapshot would duplicate state.

### Upgrade button (spec §7.6 / §7.7, and §9.4 "required if it would otherwise duplicate ~10 lines")

The two upgrade buttons share layout — factor them out.

```odin
draw_upgrade_button :: proc(
    r: rl.Rectangle,
    title, level_line, effect_line, cost_line: cstring,
    affordable: bool,
) {
    fill := affordable ? rl.SKYBLUE : rl.LIGHTGRAY
    rl.DrawRectangle(i32(r.x), i32(r.y), i32(r.width), i32(r.height), fill)
    rl.DrawRectangleLinesEx(r, 2, rl.DARKGRAY)

    x := i32(r.x) + 12
    y := i32(r.y) + 4                                       // 4px top padding
    rl.DrawText(title,       x, y, FONT_MEDIUM, rl.BLACK);    y += FONT_MEDIUM + 4
    rl.DrawText(level_line,  x, y, FONT_SMALL,  rl.DARKGRAY); y += FONT_SMALL  + 4
    rl.DrawText(effect_line, x, y, FONT_SMALL,  rl.DARKGRAY); y += FONT_SMALL  + 4
    cost_color := affordable ? rl.BLACK : rl.RED
    rl.DrawText(cost_line,   x, y, FONT_SMALL,  cost_color)
}
```

The `2` literal in `DrawRectangleLinesEx(r, 2, rl.DARKGRAY)` is implicitly converted to `f32` because the parameter type is `f32`. Same for `3` at the click-button outline call site.

Build the four label strings at the call site with `fmt.ctprintf` (see next section). Two call sites, no duplication.

## Dynamic strings

Raylib takes `cstring`. Odin's `string` type is *not* null-terminated — it's a `{ptr, len}` pair — so you can't pass it straight in. Three idiomatic options; pick the simplest:

1. **`fmt.ctprintf`** — returns a `cstring` allocated in the temp allocator. Use this for every per-frame label:

   ```odin
   currency_label := fmt.ctprintf("Currency: %d", currency)
   draw_centered_text(currency_label, 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, rl.BLACK)
   ```

2. `strings.clone_to_cstring` against a `fmt.tprintf` result. More verbose, same outcome.

3. A fixed `[64]u8` buffer and `fmt.bprintf` plus `cstring(raw_data(buf[:]))`. Manual but allocation-free.

Use **option 1** throughout. It is the shortest path and matches the rest of the code's "let raylib own complexity" stance.

### Temp allocator hygiene

`ctprintf` allocates into `context.temp_allocator`. The temp allocator is *not* automatically reset between frames — it grows until you reset it. Add one line inside the loop:

```odin
for !rl.WindowShouldClose() {
    defer free_all(context.temp_allocator)   // first statement; runs at end of each iteration
    // ... rest of the frame ...
}
```

Without this, the temp allocator grows by a few hundred bytes per frame forever — invisible for short runs but a textbook leak. `defer free_all(context.temp_allocator)` placed as the first statement of the loop body releases every per-frame allocation cleanly at end-of-iteration.

## `main` walkthrough

Order matches spec §6 exactly.

```odin
main :: proc() {
    rl.InitWindow(WINDOW_W, WINDOW_H, "Idle Clicker")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    currency:     i64 = 0
    click_power:  i32 = 1
    passive_rate: i32 = 0
    click_cost:   i32 = 10
    passive_cost: i32 = 25
    accumulator:  f64 = 0.0

    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        dt := rl.GetFrameTime()

        // §6.2 passive income tick
        accumulator += f64(dt) * f64(passive_rate)
        for accumulator >= 1.0 {
            currency += 1
            accumulator -= 1.0
        }

        // §6.3 input
        mouse := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(.LEFT) {
            if rl.CheckCollisionPointRec(mouse, CLICK_BUTTON) {
                currency += i64(click_power)
            } else if rl.CheckCollisionPointRec(mouse, CLICK_UPGRADE) && currency >= i64(click_cost) {
                currency    -= i64(click_cost)
                click_power += 1
                click_cost   = next_cost(click_cost)
            } else if rl.CheckCollisionPointRec(mouse, PASSIVE_UPGRADE) && currency >= i64(passive_cost) {
                currency     -= i64(passive_cost)
                passive_rate += 1
                passive_cost  = next_cost(passive_cost)
            }
        }

        // §6.4 draw
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)

        draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, rl.DARKGRAY)
        draw_centered_text(fmt.ctprintf("Currency: %d", currency),
                           0, WINDOW_W, CURRENCY_Y, FONT_LARGE, rl.BLACK)
        draw_centered_text(fmt.ctprintf("+%d/sec", passive_rate),
                           0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, rl.DARKGREEN)

        // click button (§7.5)
        rl.DrawRectangle(i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.y),
                         i32(CLICK_BUTTON.width), i32(CLICK_BUTTON.height), rl.GREEN)
        rl.DrawRectangleLinesEx(CLICK_BUTTON, 3, rl.DARKGREEN)

        block_h := i32(FONT_TITLE + FONT_LARGE)
        top_y   := i32(CLICK_BUTTON.y) + (i32(CLICK_BUTTON.height) - block_h) / 2
        draw_centered_text("CLICK", i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.width),
                           top_y, FONT_TITLE, rl.BLACK)
        draw_centered_text(fmt.ctprintf("(+%d)", click_power),
                           i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.width),
                           top_y + FONT_TITLE, FONT_LARGE, rl.BLACK)

        // upgrade buttons (§7.6, §7.7)
        draw_upgrade_button(
            CLICK_UPGRADE, "Click Power",
            fmt.ctprintf("Level: %d", click_power),
            "+1 per click",
            fmt.ctprintf("Cost: %d", click_cost),
            currency >= i64(click_cost),
        )
        draw_upgrade_button(
            PASSIVE_UPGRADE, "Passive Income",
            fmt.ctprintf("Level: %d", passive_rate),
            "+1 per second",
            fmt.ctprintf("Cost: %d", passive_cost),
            currency >= i64(passive_cost),
        )

        rl.EndDrawing()
    }
}
```

`defer rl.CloseWindow()` at the top of `main` is the Odin idiom for the spec's "loop until `WindowShouldClose`, then `CloseWindow`" — it guarantees cleanup on any exit path and reads top-to-bottom in source.

## Subtleties to get right

- **Order of operations** — spec §6 mandates passive tick before input within the same frame. Don't fold them.
- **Accumulator semantics** — `passive_rate = 0` must produce zero ticks regardless of `dt`. The multiply by zero in the accumulator update handles it; no special case needed.
- **`f64(dt) * f64(passive_rate)`** — `GetFrameTime` returns `f32`; the spec wants accumulator math in `f64`. Cast both operands explicitly so the multiply happens in `f64`.
- **Integer cost formula** — `(c * 3) / 2` with `i32` operands truncates toward zero. Matches spec §5 sequences (10 → 15 → 22 → 33 → 49 → …). No `f32` cast.
- **`i64` widening at comparison sites** — `currency` is `i64`; `click_cost` / `passive_cost` are `i32`. Odin will not implicitly widen; write `currency >= i64(click_cost)` and `currency -= i64(click_cost)` explicitly. Same for `currency += i64(click_power)`.
- **`Rectangle` field casts** — `rl.Rectangle` fields are `f32`. `DrawRectangle` takes `c.int` / `i32`. Cast with `i32(r.x)` at the call site; do not cache parallel `i32` copies of geometry.
- **`cstring` vs `string`** — never pass a `string` to a raylib call. Use string literals (`"CLICK"` infers `cstring` when the parameter type is `cstring`) or `fmt.ctprintf` for dynamic strings.
- **Temp allocator** — `defer free_all(context.temp_allocator)` as the first statement of the loop body. Without it, every per-frame `ctprintf` leaks for the life of the process.
- **Implicit enum selector** — `.LEFT` works in `rl.IsMouseButtonPressed(.LEFT)` because the parameter type is `rl.MouseButton`. Equivalent to `rl.MouseButton.LEFT`; both are fine. The spec's "MOUSE_BUTTON_LEFT or MOUSE_LEFT_BUTTON" note is about C-side history; in Odin it is just `MouseButton.LEFT`.
- **Only the API in spec §8** — resist `rl.DrawRectangleRec`, `rl.Fade`, `rl.DrawTextEx`. They are not on the allowed list.
- **No assets** — `DrawText` uses the default font baked into raylib. Do not call `LoadFont`.
- **Click hits one thing per frame** — the `else if` chain in §6.3 is required; do not let a single click both spend currency and earn it.
- **No `using rl`** — keep the `rl.` qualifier on every call. Spec §9 wants the file legible at a glance; `using` muddies which symbols are raylib's.

## Line count target

Imports + constants + two helpers + `main` body ≈ 130–170 lines including blank lines. If the file exceeds ~200, look for accidental duplication (most likely: the upgrade-button block was inlined twice instead of factored).
