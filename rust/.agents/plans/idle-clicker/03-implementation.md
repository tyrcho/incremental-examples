# 03 — Implementation (`src/main.rs`)

Single-file Rust source, ~150 lines. This document gives the concrete
shape of the file in skeleton form; the implementer fills in the literal
draw calls. Each section maps 1:1 to a spec section.

## File layout

```
src/main.rs
├── use raylib::prelude::*;
├── const WINDOW_W, WINDOW_H, FONT_*, *_Y, CLICK_COST_INIT, PASSIVE_COST_INIT
├── const CLICK_BUTTON, CLICK_UPGRADE, PASSIVE_UPGRADE   (Rectangle)
├── fn next_cost(c: i32) -> i32              (helper, §5)
├── fn draw_centered_text(...)               (helper, §7 centering)
├── fn draw_upgrade_button(...)              (helper, §7.6/§7.7)
└── fn main() { init -> 6 locals -> loop -> done }
```

That's it. No `struct Game`, no submodules, no separate types — state is six `let mut` locals in `main`, matching the sibling ports.

## Constants (spec §4)

```rust
const WINDOW_W: i32 = 800;
const WINDOW_H: i32 = 600;

const TITLE_Y: i32      = 30;
const CURRENCY_Y: i32   = 90;
const PASSIVE_Y: i32    = 140;

const FONT_TITLE: i32   = 36;
const FONT_LARGE: i32   = 28;
const FONT_MEDIUM: i32  = 20;
const FONT_SMALL: i32   = 18;

const CLICK_COST_INIT: i32   = 10;
const PASSIVE_COST_INIT: i32 = 25;

const CLICK_BUTTON: Rectangle = Rectangle {
    x: 80.0, y: 220.0, width: 240.0, height: 240.0,
};
const CLICK_UPGRADE: Rectangle = Rectangle {
    x: 400.0, y: 220.0, width: 320.0, height: 110.0,
};
const PASSIVE_UPGRADE: Rectangle = Rectangle {
    x: 400.0, y: 350.0, width: 320.0, height: 110.0,
};
```

All `i32` for everything that interacts with raylib's drawing/measure
calls (which take `i32`); `Rectangle` fields are `f32` because that's
what raylib-rs requires.

## State (spec §3)

Six `let mut` locals at the top of `main`. The spec explicitly permits
"just six locals in `main`", and every sibling port (C++, Crystal, Odin,
Nim) uses this shape — so Rust does too, to keep the cross-language
comparison apples-to-apples.

```rust
let mut currency:     i64 = 0;
let mut click_power:  i32 = 1;
let mut passive_rate: i32 = 0;
let mut click_cost:   i32 = CLICK_COST_INIT;
let mut passive_cost: i32 = PASSIVE_COST_INIT;
let mut accumulator:  f64 = 0.0;
```

Explicit type annotations lock the widths from spec §3 (`i64`, `i32`,
`f64`) so the cost-scaling sequence and currency display match the
other ports bit-for-bit. No `struct Game`, no `impl`, no `new()`.

## Helper: `next_cost` (spec §5)

```rust
fn next_cost(c: i32) -> i32 {
    c * 3 / 2
}
```

One line, integer arithmetic only. Don't change the operator order:
`c * 3 / 2` truncates the same way as the spec's `(old_cost * 3) / 2`.

For `c = 10`: `30 / 2 = 15`. For `c = 15`: `45 / 2 = 22`. Matches the
spec sequence exactly.

(Note: overflow at `i32::MAX` is not a practical concern — even at
1 click/sec it takes ~10^9 clicks to approach `i32::MAX`. The spec
doesn't address overflow and no implementation in any of the five
languages does either.)

## Helper: `draw_centered_text`

Parameterized container — `(container_x, container_w)` — so it works
for both the window-wide readouts (title / currency / passive) and the
two `CLICK_BUTTON`-local label lines. Matches the C++/Crystal/Odin/Nim
sibling helpers.

```rust
fn draw_centered_text(
    d: &mut RaylibDrawHandle,
    text: &str,
    container_x: i32,
    container_w: i32,
    y: i32,
    size: i32,
    color: Color,
) {
    let w = measure_text(text, size);
    let x = container_x + (container_w - w) / 2;
    d.draw_text(text, x, y, size, color);
}
```

Used five times: title, currency readout, passive readout (each with
`container_x = 0, container_w = WINDOW_W`), and twice for the
click-button label lines (with `container_x = CLICK_BUTTON.x as i32`,
`container_w = CLICK_BUTTON.width as i32`).

## Helper: `draw_upgrade_button` (spec §7.6, §7.7)

The two upgrade buttons differ only in rect, the four label strings,
the affordability bool, and which cost to display. Spec §9 mandates a
helper here ("required if it would otherwise duplicate ~10 lines").

```rust
fn draw_upgrade_button(
    d: &mut RaylibDrawHandle,
    rect: Rectangle,
    title: &str,        // e.g. "Click Power"
    level_line: &str,   // e.g. "Level: 1"
    effect_line: &str,  // e.g. "+1 per click"
    cost_line: &str,    // e.g. "Cost: 10"
    affordable: bool,
) {
    let fill = if affordable { Color::SKYBLUE } else { Color::LIGHTGRAY };
    d.draw_rectangle(
        rect.x as i32, rect.y as i32,
        rect.width as i32, rect.height as i32,
        fill);
    d.draw_rectangle_lines_ex(rect, 2.0, Color::DARKGRAY);

    let x_text = rect.x as i32 + 12;
    let mut y = rect.y as i32 + 4;

    d.draw_text(title,       x_text, y, FONT_MEDIUM, Color::BLACK);
    y += FONT_MEDIUM + 4;
    d.draw_text(level_line,  x_text, y, FONT_SMALL,  Color::DARKGRAY);
    y += FONT_SMALL + 4;
    d.draw_text(effect_line, x_text, y, FONT_SMALL,  Color::DARKGRAY);
    y += FONT_SMALL + 4;
    let cost_color = if affordable { Color::BLACK } else { Color::RED };
    d.draw_text(cost_line,   x_text, y, FONT_SMALL,  cost_color);
}
```

Notes:

- The `2.0` thickness on `draw_rectangle_lines_ex` may need to be `2`
  on older raylib-rs versions. See
  [02-rust-binding-mapping.md § Known version skew](./02-rust-binding-mapping.md#known-version-skew).
- The vertical stacking is `rect.y + 4` start, then four lines with 4px
  padding after each. Spec §7.6: "stacked top to bottom with 4px
  padding".
- `x_text` is `rect.x + 12` per spec §7.6: "left-aligned 12px from the
  left edge of the rect".
- Param names `title / level_line / effect_line / cost_line` match the
  C++/Crystal/Odin/Nim sibling helpers — keeps call-sites readable
  without counting positional args.

The caller is responsible for formatting `"Level: <N>"` and
`"Cost: <N>"`; the helper just takes finished strings. This keeps the
helper's signature simple and avoids passing in `click_power` /
`click_cost` separately.

## `main`

The full structure:

```rust
fn main() {
    let (mut rl, thread) = raylib::init()
        .size(WINDOW_W, WINDOW_H)
        .title("Idle Clicker")
        .build();
    rl.set_target_fps(60);

    let mut currency:     i64 = 0;
    let mut click_power:  i32 = 1;
    let mut passive_rate: i32 = 0;
    let mut click_cost:   i32 = CLICK_COST_INIT;
    let mut passive_cost: i32 = PASSIVE_COST_INIT;
    let mut accumulator:  f64 = 0.0;

    while !rl.window_should_close() {
        // §6 step 1
        let dt = rl.get_frame_time();

        // §6 step 2 — passive income tick
        accumulator += (dt as f64) * (passive_rate as f64);
        while accumulator >= 1.0 {
            currency += 1;
            accumulator -= 1.0;
        }

        // §6 step 3 — input
        let mouse = rl.get_mouse_position();
        if rl.is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT) {
            if CLICK_BUTTON.check_collision_point_rec(mouse) {
                currency += click_power as i64;
            } else if CLICK_UPGRADE.check_collision_point_rec(mouse)
                && currency >= click_cost as i64
            {
                currency -= click_cost as i64;
                click_power += 1;
                click_cost = next_cost(click_cost);
            } else if PASSIVE_UPGRADE.check_collision_point_rec(mouse)
                && currency >= passive_cost as i64
            {
                currency -= passive_cost as i64;
                passive_rate += 1;
                passive_cost = next_cost(passive_cost);
            }
        }

        // §6 step 4 — draw
        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::RAYWHITE);

        // §7.2 title
        draw_centered_text(&mut d, "Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, Color::DARKGRAY);

        // §7.3 currency
        let currency_text = format!("Currency: {}", currency);
        draw_centered_text(&mut d, &currency_text, 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, Color::BLACK);

        // §7.4 passive readout
        let passive_text = format!("+{}/sec", passive_rate);
        draw_centered_text(&mut d, &passive_text, 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, Color::DARKGREEN);

        // §7.5 click button
        d.draw_rectangle(
            CLICK_BUTTON.x as i32, CLICK_BUTTON.y as i32,
            CLICK_BUTTON.width as i32, CLICK_BUTTON.height as i32,
            Color::GREEN);
        d.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0, Color::DARKGREEN);
        {
            // two-line label, vertically centered in CLICK_BUTTON
            let line2 = format!("(+{})", click_power);
            let total_h = FONT_TITLE + FONT_LARGE;
            let cy = CLICK_BUTTON.y as i32 + (CLICK_BUTTON.height as i32 - total_h) / 2;
            let cx = CLICK_BUTTON.x as i32;
            let cw = CLICK_BUTTON.width as i32;
            draw_centered_text(&mut d, "CLICK",  cx, cw, cy,              FONT_TITLE, Color::BLACK);
            draw_centered_text(&mut d, &line2,   cx, cw, cy + FONT_TITLE, FONT_LARGE, Color::BLACK);
        }

        // §7.6 click upgrade
        let click_affordable = currency >= click_cost as i64;
        let click_lvl    = format!("Level: {}", click_power);
        let click_cost_s = format!("Cost: {}",  click_cost);
        draw_upgrade_button(
            &mut d, CLICK_UPGRADE,
            "Click Power", &click_lvl, "+1 per click", &click_cost_s,
            click_affordable,
        );

        // §7.7 passive upgrade
        let passive_affordable = currency >= passive_cost as i64;
        let passive_lvl    = format!("Level: {}", passive_rate);
        let passive_cost_s = format!("Cost: {}",  passive_cost);
        draw_upgrade_button(
            &mut d, PASSIVE_UPGRADE,
            "Passive Income", &passive_lvl, "+1 per second", &passive_cost_s,
            passive_affordable,
        );

        // `d` drops here -> EndDrawing
    }
    // `rl` drops here -> CloseWindow (implicit)
}
```

That's the whole program. About 110–130 lines depending on formatting.

## Borrow-checker notes

- `rl.get_frame_time()`, `rl.get_mouse_position()`,
  `rl.is_mouse_button_pressed(...)`, and `rl.set_target_fps(...)` all
  take `&mut self` on `RaylibHandle`. Calling them sequentially in
  `main` is fine because each call ends before the next.
- `rl.begin_drawing(&thread)` returns a `RaylibDrawHandle<'_>` that
  borrows `rl` mutably for the lifetime of `d`. While `d` is alive
  you cannot call any `rl.*` method. The implementation does all
  input reads BEFORE `begin_drawing`, which avoids that conflict.
- `format!` allocates on each frame for the dynamic strings
  (`currency_text`, `passive_text`, `click_lvl`, `click_cost_s`,
  `passive_lvl`, `passive_cost_s`, and `line2` inside the click button).
  At 60 fps that's ~420 small short-lived allocations per second;
  trivial. Don't optimize this — spec §1 forbids "abstractions" and
  reaching for a reusable buffer would be one.

## Behavioral checklist (cross-reference to spec §11)

| Acceptance criterion | Where it's implemented |
|---|---|
| Window 800×600 titled "Idle Clicker", solid white | `init().size(800,600).title("Idle Clicker")` + `clear_background(RAYWHITE)` |
| Clicking green square: `currency += click_power` | `CLICK_BUTTON.check_collision_point_rec(mouse)` branch |
| Click button label shows current `click_power` | `format!("(+{})", click_power)` per frame |
| Upgrade buttons show level/effect/cost; cost red when broke; fill gray when broke | `draw_upgrade_button` + `affordable` flag |
| Buying click upgrade: deduct, +1 power, scale cost | Click-upgrade branch + `next_cost(click_cost)` |
| Buying passive upgrade: deduct, +1 rate, scale cost | Passive-upgrade branch + `next_cost(passive_cost)` |
| `passive_rate = N` ⇒ currency ticks +N per real-world second | `accumulator` loop in §6 step 2 |
| Clean exit, no panics/leaks | No `.unwrap()`, no `panic!`, `rl` drops cleanly |
| Release-build runs without extra runtime deps | `cargo run --release`; raylib linked at build time |
