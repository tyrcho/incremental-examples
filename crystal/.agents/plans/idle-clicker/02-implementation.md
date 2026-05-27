# 02 — Implementation Walkthrough

Target: a single `src/idle_clicker.cr`, ~180–230 lines (the FFI block adds ~30 lines vs. the sibling ports), Crystal 1.x, **hand-rolled `lib LibRaylib` FFI** against Homebrew's `libraylib.dylib`. Spec section references in parentheses.

## File outline

```crystal
require "lib_c"             # for LibC::Char*

# 1. lib LibRaylib { ... }  — FFI declarations (see "FFI block" below)
# 2. Color constants        — RAYWHITE, BLACK, … as user-defined LibRaylib::Color values
# 3. Geometry constants     — WINDOW_W, FONT_*, *_Y, rects
# 4. Helpers                — next_cost, draw_centered_text, draw_upgrade_button
# 5. Main flow              — top-level (no `def main` — Crystal runs top-level code)
```

Crystal does not require a `main` function; top-level code runs at program start. Group state and the loop at the bottom of the file under a `# --- main ---` comment for readability.

## FFI block

This block lives at the very top of `src/idle_clicker.cr` (after `require "lib_c"`). It is the entire surface area of raylib we touch.

```crystal
@[Link("raylib")]
lib LibRaylib
  struct Color
    r, g, b, a : UInt8
  end

  struct Vector2
    x, y : Float32
  end

  struct Rectangle
    x, y, width, height : Float32
  end

  # Window lifecycle
  fun init_window         = InitWindow(width : Int32, height : Int32, title : LibC::Char*)
  fun close_window        = CloseWindow
  fun window_should_close = WindowShouldClose : Bool
  fun set_target_fps      = SetTargetFPS(fps : Int32)

  # Drawing pair
  fun begin_drawing       = BeginDrawing
  fun end_drawing         = EndDrawing
  fun clear_background    = ClearBackground(color : Color)

  # Shapes & text
  fun draw_rectangle           = DrawRectangle(x : Int32, y : Int32, w : Int32, h : Int32, color : Color)
  fun draw_rectangle_lines_ex  = DrawRectangleLinesEx(rec : Rectangle, line_thick : Float32, color : Color)
  fun draw_text                = DrawText(text : LibC::Char*, x : Int32, y : Int32, font_size : Int32, color : Color)
  fun measure_text             = MeasureText(text : LibC::Char*, font_size : Int32) : Int32

  # Input
  fun get_mouse_position       = GetMousePosition : Vector2
  fun is_mouse_button_pressed  = IsMouseButtonPressed(button : Int32) : Bool
  fun get_frame_time           = GetFrameTime : Float32

  # Collision
  fun check_collision_point_rec = CheckCollisionPointRec(point : Vector2, rec : Rectangle) : Bool
end

MOUSE_BUTTON_LEFT = 0   # raylib's MouseButton::LEFT enum value
```

Notes:

- `@[Link("raylib")]` tells Crystal's linker to add `-lraylib` to the final `cc` invocation. On macOS Homebrew, that resolves to `/opt/homebrew/lib/libraylib.dylib` automatically.
- `fun crystal_name = CName(...)` declares the C function once with both names — call sites use the Crystal snake_case alias.
- raylib's `Color`, `Vector2`, `Rectangle` structs are reproduced field-for-field so Crystal can pass them by value across the FFI boundary.
- `MOUSE_BUTTON_LEFT = 0` — raylib's `MouseButton` enum has `LEFT = 0`. Spec §8 allows the integer.

## Color constants (spec §8)

raylib's named colors are `#define`s in the C header, so they don't come across the FFI. Declare the eight we need as Crystal constants:

```crystal
RAYWHITE   = LibRaylib::Color.new(r: 245_u8, g: 245_u8, b: 245_u8, a: 255_u8)
BLACK      = LibRaylib::Color.new(r:   0_u8, g:   0_u8, b:   0_u8, a: 255_u8)
DARKGRAY   = LibRaylib::Color.new(r:  80_u8, g:  80_u8, b:  80_u8, a: 255_u8)
LIGHTGRAY  = LibRaylib::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8)
GREEN      = LibRaylib::Color.new(r:   0_u8, g: 228_u8, b:  48_u8, a: 255_u8)
DARKGREEN  = LibRaylib::Color.new(r:   0_u8, g: 117_u8, b:  44_u8, a: 255_u8)
SKYBLUE    = LibRaylib::Color.new(r: 102_u8, g: 191_u8, b: 255_u8, a: 255_u8)
RED        = LibRaylib::Color.new(r: 230_u8, g:  41_u8, b:  55_u8, a: 255_u8)
```

The RGBA values are taken from raylib's `raylib.h` `#define` block — bit-identical to what the C++/Odin/Rust/Nim ports get from their bindings' named constants. If a future raylib release adjusts a color, these would drift; that risk is tiny and out of scope for this spec.

## Geometry constants (spec §4)

```crystal
WINDOW_W = 800
WINDOW_H = 600

TITLE_Y     =  30
CURRENCY_Y =  90
PASSIVE_Y  = 140

FONT_TITLE  = 36
FONT_LARGE  = 28
FONT_MEDIUM = 20
FONT_SMALL  = 18

CLICK_BUTTON    = LibRaylib::Rectangle.new(x:  80.0_f32, y: 220.0_f32, width: 240.0_f32, height: 240.0_f32)
CLICK_UPGRADE   = LibRaylib::Rectangle.new(x: 400.0_f32, y: 220.0_f32, width: 320.0_f32, height: 110.0_f32)
PASSIVE_UPGRADE = LibRaylib::Rectangle.new(x: 400.0_f32, y: 350.0_f32, width: 320.0_f32, height: 110.0_f32)
```

Crystal's `Int32` default is what we want for geometry constants. `Rectangle` fields are `Float32` (matching raylib's C struct), so use `_f32` literal suffixes.

## State (spec §3)

Six locals declared right before the loop. Matches C++/Odin/Rust/Nim sibling ports.

```crystal
currency     = 0_i64        # 64-bit signed
click_power  = 1            # Int32 by default
passive_rate = 0
click_cost   = 10
passive_cost = 25
accumulator  = 0.0          # Float64 by default
```

`_i64` suffix forces `Int64` for currency (spec §3). The Float64 default matches the spec's "64-bit float (double)" requirement.

## Helpers

### Cost scaling (spec §5)

```crystal
def next_cost(c : Int32) : Int32
  (c * 3) / 2
end
```

**Crystal integer division note:** `Int32 / Int32` in Crystal truncates toward zero — same semantics as C `/` and the spec §5 formula. Do not introduce a `.to_f` cast "for safety"; spec §5 explicitly forbids float promotion and the integer sequence (10 → 15 → 22 → 33 → 49 → …) is part of the contract. Do not reach for `//` either — Crystal uses `//` for floor division, which differs from truncation for negatives.

### Centered text

Parameterized container — `(container_x, container_w)` — so it works for both the window-wide readouts and the two `CLICK_BUTTON`-local label lines. Matches the C++/Odin/Rust/Nim sibling helpers.

```crystal
def draw_centered_text(text : String, container_x : Int32, container_w : Int32,
                       y : Int32, font : Int32, color : LibRaylib::Color)
  tw = LibRaylib.measure_text(text, font)
  LibRaylib.draw_text(text, container_x + (container_w - tw) / 2, y, font, color)
end
```

Crystal strings auto-coerce to `LibC::Char*` at the FFI boundary — no manual `.to_unsafe` needed.

Used five times: title, currency readout, passive readout (each with `container_x = 0, container_w = WINDOW_W`), and twice for the click-button label lines (with `container_x = CLICK_BUTTON.x.to_i`, `container_w = CLICK_BUTTON.width.to_i`).

### Upgrade button (spec §7.6 / §7.7, and §9.4 "required if it would otherwise duplicate ~10 lines")

The two upgrade buttons share layout — factor them out. Param names `title / level_line / effect_line / cost_line` match the C++/Odin/Rust/Nim sibling helpers.

```crystal
def draw_upgrade_button(r : LibRaylib::Rectangle, title : String,
                        level_line : String, effect_line : String,
                        cost_line : String, affordable : Bool)
  fill = affordable ? SKYBLUE : LIGHTGRAY
  LibRaylib.draw_rectangle(r.x.to_i, r.y.to_i, r.width.to_i, r.height.to_i, fill)
  LibRaylib.draw_rectangle_lines_ex(r, 2.0_f32, DARKGRAY)

  x = r.x.to_i + 12
  y = r.y.to_i + 4                                                # 4px top padding
  LibRaylib.draw_text(title,       x, y, FONT_MEDIUM, BLACK);             y += FONT_MEDIUM + 4
  LibRaylib.draw_text(level_line,  x, y, FONT_SMALL,  DARKGRAY);          y += FONT_SMALL  + 4
  LibRaylib.draw_text(effect_line, x, y, FONT_SMALL,  DARKGRAY);          y += FONT_SMALL  + 4
  LibRaylib.draw_text(cost_line,   x, y, FONT_SMALL,  affordable ? BLACK : RED)
end
```

`2.0_f32` is required — `draw_rectangle_lines_ex` takes `Float32`, and a bare `2.0` (Float64) would type-error at the FFI call. Same for `3.0_f32` at the click button outline below.

## Main flow

Order matches spec §6 exactly. This is the bottom of the file.

```crystal
LibRaylib.init_window(WINDOW_W, WINDOW_H, "Idle Clicker")
LibRaylib.set_target_fps(60)

currency     = 0_i64
click_power  = 1
passive_rate = 0
click_cost   = 10
passive_cost = 25
accumulator  = 0.0

until LibRaylib.window_should_close
  dt = LibRaylib.get_frame_time

  # §6.2 passive income tick
  accumulator += dt.to_f64 * passive_rate.to_f64
  while accumulator >= 1.0
    currency += 1
    accumulator -= 1.0
  end

  # §6.3 input
  mouse = LibRaylib.get_mouse_position
  if LibRaylib.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    if LibRaylib.check_collision_point_rec(mouse, CLICK_BUTTON)
      currency += click_power
    elsif LibRaylib.check_collision_point_rec(mouse, CLICK_UPGRADE) && currency >= click_cost
      currency    -= click_cost
      click_power += 1
      click_cost   = next_cost(click_cost)
    elsif LibRaylib.check_collision_point_rec(mouse, PASSIVE_UPGRADE) && currency >= passive_cost
      currency     -= passive_cost
      passive_rate += 1
      passive_cost  = next_cost(passive_cost)
    end
  end

  # §6.4 draw
  LibRaylib.begin_drawing
  LibRaylib.clear_background(RAYWHITE)

  draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY)
  draw_centered_text("Currency: #{currency}", 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK)
  draw_centered_text("+#{passive_rate}/sec",  0, WINDOW_W, PASSIVE_Y,  FONT_MEDIUM, DARKGREEN)

  # click button (§7.5)
  LibRaylib.draw_rectangle(CLICK_BUTTON.x.to_i, CLICK_BUTTON.y.to_i,
                           CLICK_BUTTON.width.to_i, CLICK_BUTTON.height.to_i, GREEN)
  LibRaylib.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0_f32, DARKGREEN)

  block_h = FONT_TITLE + FONT_LARGE
  top_y   = CLICK_BUTTON.y.to_i + (CLICK_BUTTON.height.to_i - block_h) / 2
  cx      = CLICK_BUTTON.x.to_i
  cw      = CLICK_BUTTON.width.to_i
  draw_centered_text("CLICK",            cx, cw, top_y,              FONT_TITLE, BLACK)
  draw_centered_text("(+#{click_power})", cx, cw, top_y + FONT_TITLE, FONT_LARGE, BLACK)

  # upgrade buttons (§7.6, §7.7)
  draw_upgrade_button(CLICK_UPGRADE, "Click Power",
                      "Level: #{click_power}", "+1 per click", "Cost: #{click_cost}",
                      currency >= click_cost)
  draw_upgrade_button(PASSIVE_UPGRADE, "Passive Income",
                      "Level: #{passive_rate}", "+1 per second", "Cost: #{passive_cost}",
                      currency >= passive_cost)

  LibRaylib.end_drawing
end

LibRaylib.close_window
```

## Subtleties to get right

- **No name collision** — by hand-rolling the FFI we control the Crystal-side names. We picked `window_should_close` for the predicate and `close_window` for the action, distinct identifiers, so the `raylib-cr` `close_window?` / `close_window` collision problem does not exist here.
- **Order of operations** — spec §6 mandates passive tick before input within the same frame. Don't fold them.
- **Accumulator semantics** — `passive_rate = 0` must produce zero ticks regardless of `dt`. The multiply by zero handles it; no special case needed.
- **`dt.to_f64`** — `get_frame_time` returns `Float32`; multiplying against `passive_rate.to_f64` keeps the accumulator math in `Float64` per spec §3.
- **Integer cost formula** — `(c * 3) / 2` in Crystal with `Int32` operands truncates toward zero. Matches spec §5 sequences exactly. No `.to_f`, no `//` rewrite.
- **Float32 literals for raylib** — `draw_rectangle_lines_ex`'s thickness arg is `Float32`. Write `3.0_f32`, not `3.0` — the latter is Float64 and will fail to compile across the FFI boundary.
- **`Rectangle` field casts** — `LibRaylib::Rectangle` fields are `Float32`. `draw_rectangle` takes `Int32`. Cast with `.to_i` at every call site; don't cache parallel Int32 copies of geometry.
- **Mouse button** — `MOUSE_BUTTON_LEFT = 0` is the raylib enum value. Pass the constant for legibility rather than the literal `0`.
- **Only the API in spec §8** — the FFI block declares exactly those functions. Adding `draw_rectangle_rec`, `fade`, `draw_text_ex`, etc. would require new `fun` lines and is forbidden by the spec.
- **No assets** — `draw_text` uses the default font baked into raylib. Do not declare `LoadFont` in the FFI block.
- **Click hits one thing per frame** — the `elsif` chain in §6.3 is required; do not let a single click both spend currency and earn it.
- **No `def main`** — Crystal runs top-level code. Wrapping it in a `def main; ...; end` and calling `main` works but is non-idiomatic.
- **Don't introduce a `struct State`** — six locals matches the sibling ports and is what the spec describes.

## Line count target

FFI block (~35 lines) + color consts (~10) + geometry consts (~15) + three helpers (~25) + main flow (~50) ≈ 180–200 lines. The FFI block is the load-bearing budget item versus the sibling ports' ~150-line targets. If the file exceeds 250 lines, look for accidental duplication in the helpers or stray `fun` declarations beyond spec §8.
