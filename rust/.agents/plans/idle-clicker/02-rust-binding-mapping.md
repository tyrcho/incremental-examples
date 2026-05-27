# 02 — Rust Binding Mapping (raylib-rs)

How each item in spec §8 ("Allowed raylib API surface") and the primitives
referenced elsewhere in the spec map to the `raylib` Rust crate.

The binding is `raylib = "5"` from crates.io (raylib-rs). It exposes a safe
wrapper over raylib 5.x. The prelude (`use raylib::prelude::*;`) brings in
the types and color constants we need.

## Imports

A single `use raylib::prelude::*;` at the top of `src/main.rs` covers
everything below: `RaylibHandle`, `RaylibThread`, `RaylibDraw`, `Color`,
`Rectangle`, `Vector2`, `MouseButton`, and the free `measure_text` function.

```rust
use raylib::prelude::*;
```

No other imports.

## Window lifecycle

| Spec call | raylib-rs equivalent |
|-----------|----------------------|
| `InitWindow(800, 600, "Idle Clicker")` | `let (mut rl, thread) = raylib::init().size(800, 600).title("Idle Clicker").build();` |
| `SetTargetFPS(60)` | `rl.set_target_fps(60);` |
| `WindowShouldClose()` | `rl.window_should_close()` |
| `CloseWindow()` | Implicit — `RaylibHandle` drops at end of `main` and closes the window. No explicit call. |

The builder returns `(RaylibHandle, RaylibThread)` infallibly. Older
binding versions returned a `Result`; raylib-rs 5.x's `build()` is
infallible, so no `unwrap`/`?` is needed.

## Drawing handle (RAII)

raylib-rs models `BeginDrawing` / `EndDrawing` as a scoped handle:

```rust
{
    let mut d = rl.begin_drawing(&thread);
    d.clear_background(Color::RAYWHITE);
    // ... all DrawX calls go through `d`
}
// `d` is dropped here, which calls EndDrawing.
```

The block scope is what gives us automatic `EndDrawing`. Don't call
`end_drawing()` manually — there isn't one to call.

Every draw call in spec §7 is a method on `d`:

| Spec call | raylib-rs (on `d: RaylibDrawHandle`) |
|-----------|--------------------------------------|
| `ClearBackground(RAYWHITE)` | `d.clear_background(Color::RAYWHITE);` |
| `DrawRectangle(x, y, w, h, color)` | `d.draw_rectangle(x, y, w, h, color);` (all `i32` coords) |
| `DrawRectangleLinesEx(rect, thick, color)` | `d.draw_rectangle_lines_ex(rect, thick, color);` |
| `DrawText(text, x, y, size, color)` | `d.draw_text(text, x, y, size, color);` |

For filled rectangles, use `d.draw_rectangle(x, y, w, h, color)` with the
`Rectangle`'s `f32` fields cast to `i32` at the call site — `x as i32`,
`width as i32`, etc. raylib-rs also exposes `d.draw_rectangle_rec(rect, color)`
which takes a `Rectangle` directly and would avoid the casts, but spec §8
lists `DrawRectangle` (the int-coords variant) as the canonical primitive and
the C++/Crystal/Nim/Odin sibling ports all use it; this port matches them so
the cross-language ergonomics comparison stays apples-to-apples.

## Color constants (spec §8)

All eight needed colors are `Color` associated constants in raylib-rs:

```
Color::RAYWHITE   Color::BLACK     Color::DARKGRAY   Color::LIGHTGRAY
Color::GREEN      Color::DARKGREEN Color::SKYBLUE    Color::RED
```

Pass them by value (they're `Copy`).

## Rectangle

`raylib::core::math::Rectangle` (re-exported by the prelude) is:

```rust
pub struct Rectangle {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}
```

Fields are `f32`. The spec's pixel-integer rects are declared as `const`s
using `f32` literals:

```rust
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

`Rectangle` literally constructs in a `const` context because its fields
are public `f32`s.

## Hit-test

Spec §6 step 3: "Use `CheckCollisionPointRec` for the rectangle
hit-tests." raylib-rs exposes this as a method on `Rectangle`:

```rust
let mouse: Vector2 = rl.get_mouse_position();
if CLICK_BUTTON.check_collision_point_rec(mouse) { /* ... */ }
```

(`check_collision_point_rec` takes anything `Into<Vector2>`; `Vector2`
satisfies that trivially.)

## Mouse input

| Spec | raylib-rs |
|------|-----------|
| `GetMousePosition()` | `rl.get_mouse_position() -> Vector2` |
| `IsMouseButtonPressed(MOUSE_BUTTON_LEFT)` | `rl.is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT)` |
| `GetFrameTime()` | `rl.get_frame_time() -> f32` |

Note that input is read on `rl` (the `RaylibHandle`), NOT inside the
`begin_drawing` block. Read input first, mutate state, *then* begin
drawing. This matches the spec §6 order (1: dt, 2: passive tick, 3: input,
4: draw).

## MeasureText

Spec §7 says: "For horizontal centering of any text, use
`MeasureText(text, fontSize)`." raylib-rs exposes this as a top-level
free function:

```rust
use raylib::prelude::*;
let w: i32 = measure_text("Idle Clicker", FONT_TITLE);
let x = (WINDOW_W - w) / 2; // both i32
```

It does NOT need the handle (default font metrics are static), so we can
call it during the input phase if we precompute, or inline at the draw
site. The plan inlines at the draw site; centering is local to each text
draw.

## Frame time widening to f64

`get_frame_time()` returns `f32`. The accumulator is `f64` per spec §3.
The widening happens at the multiply:

```rust
let dt: f32 = rl.get_frame_time();
accumulator += (dt as f64) * (passive_rate as f64);
while accumulator >= 1.0 {
    currency += 1;
    accumulator -= 1.0;
}
```

Order matters: cast both operands to `f64` before multiplying. (For
`passive_rate <= 25` and `dt < 1.0`, `f32` multiplication wouldn't lose
precision anyway, but the spec is explicit about the accumulator type, so
we honor it.)

## Allowed calls

Full Rust call list, in the order they appear in the source:

```
raylib::init().size(...).title(...).build()
RaylibHandle::set_target_fps(60)
RaylibHandle::window_should_close()
RaylibHandle::get_frame_time()
RaylibHandle::get_mouse_position()
RaylibHandle::is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT)
Rectangle::check_collision_point_rec(Vector2)
RaylibHandle::begin_drawing(&RaylibThread) -> RaylibDrawHandle
RaylibDrawHandle::clear_background(Color)
RaylibDrawHandle::draw_rectangle(i32, i32, i32, i32, Color)
RaylibDrawHandle::draw_rectangle_lines_ex(Rectangle, f32 or i32, Color)
RaylibDrawHandle::draw_text(&str, i32, i32, i32, Color)
raylib::text::measure_text(&str, i32) -> i32   // via prelude
```

That's every raylib symbol the program touches. Anything outside this
list is out of scope.

## Known version skew

raylib-rs has shifted a couple of signatures inside the 5.x series that
we touch:

- **`draw_rectangle_lines_ex` thickness:** older 5.x took `i32`;
  newer 5.x takes `f32`. If the implementer hits a type error, change
  the literal: `3` → `3.0` (or vice versa) and `2` → `2.0`. No other
  code change needed.
- **`check_collision_point_rec` method vs free function:** the plan
  writes this as a method — `CLICK_BUTTON.check_collision_point_rec(mouse)`.
  raylib-rs reliably exposes the free function
  `check_collision_point_rec(point: Vector2, rec: Rectangle) -> bool`
  via the prelude. If the inherent method isn't available on the
  installed version, swap call sites to the free-function form:
  `check_collision_point_rec(mouse, CLICK_BUTTON)`. Argument order is
  `(point, rec)`, mirroring the C signature `CheckCollisionPointRec(point, rec)`.

If a future raylib-rs renames `MouseButton::MOUSE_BUTTON_LEFT` to
`MouseButton::Left`, the fix is one identifier in one place.

## What we deliberately don't use

These are in `raylib::prelude::*` but NOT in the spec's allow-list and
the implementation must NOT reach for them even when convenient:

- `DrawTextEx` — would let us pass a custom font. Spec §1 forbids
  external assets and §8 lists only `DrawText`.
- `GuiButton` / raygui anything — spec §1 says raylib only, no other
  UI libraries.
- `draw_rectangle_rec` — raylib-rs exposes both `draw_rectangle(x, y, w, h, …)`
  and `draw_rectangle_rec(rect, color)`. Spec §8 only lists
  `DrawRectangle` (the int-coords variant); use that with `as i32` casts
  from the `Rectangle`'s `f32` fields, matching the sibling ports.
- `DrawRectangleRounded`, `DrawRectangleGradient`, etc. — not in §8.
- `IsMouseButtonDown` / `IsMouseButtonReleased` — we use *Pressed*
  (edge-triggered) per spec §6 step 3.
- `GetMouseDelta`, scroll wheel, keyboard input.
- `Vector2` math helpers — we read position once and pass it to
  `check_collision_point_rec`; no arithmetic needed.
