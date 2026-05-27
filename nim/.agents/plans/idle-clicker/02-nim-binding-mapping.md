# 02 — Nim Binding Mapping (naylib)

How each item in spec §8 ("Allowed raylib API surface") and the primitives
referenced elsewhere in the spec map to the `naylib` Nim package.

The binding is `naylib >= 5.0` from nimble.directory (naylib). It exposes
a thin, idiomatic Nim wrapper over raylib 5.x. Function names are
camelCase versions of raylib's `PascalCase` C names (`InitWindow` →
`initWindow`); types are `PascalCase`; enums are scoped (e.g.,
`MouseButton.Left`).

## Imports

Two imports cover everything:

```nim
import raylib
import std/strformat
```

`raylib` is naylib's main module. `std/strformat` is stdlib and provides
`&"Currency: {currency}"` interpolation. Nothing else.

## Window lifecycle

| Spec call | naylib equivalent |
|-----------|-------------------|
| `InitWindow(800, 600, "Idle Clicker")` | `initWindow(800, 600, "Idle Clicker")` |
| `SetTargetFPS(60)` | `setTargetFps(60)` |
| `WindowShouldClose()` | `windowShouldClose()` |
| `CloseWindow()` | `closeWindow()` |

naylib does NOT use RAII / `defer`-by-default for `closeWindow`. The
implementer can either:

- call `closeWindow()` explicitly after the `while` loop (the plan picks
  this — matches spec §6's "Loop until ..., then `CloseWindow()`"); or
- wrap the call site in `defer: closeWindow()` immediately after
  `initWindow` — also fine.

Both are idiomatic Nim. Pick one; don't mix.

## Drawing pair

raylib's `BeginDrawing` / `EndDrawing` map to naylib's `beginDrawing()` /
`endDrawing()` procs. naylib also exposes a `drawing:` template that
auto-pairs them, but the spec's §6 step 4 wording ("wrapped in
`BeginDrawing()` / `EndDrawing()`") matches direct calls more literally,
and the C++/Odin/Crystal ports use direct calls. The plan picks direct
calls for parity:

```nim
beginDrawing()
clearBackground(RayWhite)
# ... all drawX calls ...
endDrawing()
```

| Spec call | naylib equivalent |
|-----------|-------------------|
| `BeginDrawing()` | `beginDrawing()` |
| `EndDrawing()` | `endDrawing()` |
| `ClearBackground(RAYWHITE)` | `clearBackground(RayWhite)` |
| `DrawRectangle(x, y, w, h, color)` | `drawRectangle(x, y, w, h, color)` |
| `DrawRectangleLinesEx(rect, thick, color)` | `drawRectangleLinesEx(rect, thick, color)` |
| `DrawText(text, x, y, size, color)` | `drawText(text, x, y, size, color)` |
| `MeasureText(text, size)` | `measureText(text, size)` |

`drawText` accepts a Nim `string` and converts to `cstring` internally; no
manual conversion needed.

## Color constants (spec §8)

All eight needed colors are top-level `Color` constants in naylib:

```
RayWhite   Black     DarkGray   LightGray
Green      DarkGreen SkyBlue    Red
```

(naylib follows raylib's color-constant naming with PascalCase: `RayWhite`,
not `RAYWHITE`; `DarkGreen`, not `DARKGREEN`. These are `const Color`
values exported by the `raylib` module.)

## Rectangle

naylib's `Rectangle` is:

```nim
type
  Rectangle* = object
    x*, y*, width*, height*: float32
```

Fields are `float32`. The spec's pixel-integer rects are declared as
top-level `const`s using float literals (Nim allows `80` to coerce to
`float32` in an object constructor, but explicit `.0` is clearer):

```nim
const
  CLICK_BUTTON    = Rectangle(x: 80,  y: 220, width: 240, height: 240)
  CLICK_UPGRADE   = Rectangle(x: 400, y: 220, width: 320, height: 110)
  PASSIVE_UPGRADE = Rectangle(x: 400, y: 350, width: 320, height: 110)
```

These are `const` because all fields are compile-time integer literals
that coerce to `float32`. They're constructed once at compile time and
reused every frame.

## Hit-test

Spec §6 step 3: "Use `CheckCollisionPointRec` for the rectangle
hit-tests." naylib exposes this as a free proc:

```nim
let mouse = getMousePosition()              # Vector2
if checkCollisionPointRec(mouse, CLICK_BUTTON):
  currency += clickPower
```

Argument order is `(point, rec)`, matching the C signature
`CheckCollisionPointRec(Vector2 point, Rectangle rec)`.

## Mouse input

| Spec | naylib |
|------|--------|
| `GetMousePosition()` | `getMousePosition(): Vector2` |
| `IsMouseButtonPressed(MOUSE_BUTTON_LEFT)` | `isMouseButtonPressed(MouseButton.Left)` |
| `GetFrameTime()` | `getFrameTime(): float32` |

naylib's `MouseButton` is a scoped enum: `MouseButton.Left`,
`MouseButton.Right`, `MouseButton.Middle`. The plan uses the dotted form
for clarity; the unscoped `Left` would only work if the call site
disambiguated.

## measureText

Spec §7 says: "use `MeasureText(text, fontSize)`." naylib exposes it as a
top-level free proc:

```nim
let w: int32 = measureText("Idle Clicker", FONT_TITLE)
let x = (WINDOW_W - w) div 2   # both int32, integer division
```

Default-font metrics are static, so no handle is needed. The plan inlines
the centering math inside a small `drawCenteredText` helper (see
[03-implementation.md](./03-implementation.md)) so the five call sites
stay one line each.

## Frame time widening to float64

`getFrameTime()` returns `float32`. The accumulator is `float64` per
spec §3. The widening happens at the multiply:

```nim
let dt = getFrameTime()                                  # float32
accumulator += float64(dt) * float64(passiveRate)        # float64
while accumulator >= 1.0:
  currency += 1
  accumulator -= 1.0
```

Order matters: cast both operands to `float64` before multiplying. (For
realistic `passive_rate` values and `dt < 1.0`, `float32` multiplication
wouldn't lose precision anyway, but the spec is explicit about the
accumulator type, so we honor it.)

## Integer division

Nim's `/` operator on `int` types returns `float`. The spec mandates
truncating integer division:

```nim
proc nextCost(c: int32): int32 = (c * 3) div 2
```

`div` is the integer-division operator. For signed integers it truncates
toward zero, matching C's `/`, Rust's `/` on ints, and Odin's `/` on
ints. Crystal uses `//` for the same operation. All five ports produce
the same sequence.

DO NOT write `(c * 3) / 2` — that would return a `float`, and either
compile-error (if assigned to `int32`) or require an explicit cast that
silently rounds.

## Type sizes

Spec §3 mandates specific widths:

| Spec name      | Spec type        | Nim type  |
|----------------|------------------|-----------|
| `currency`     | int64 signed     | `int64`   |
| `click_power`  | int32 signed     | `int32`   |
| `passive_rate` | int32 signed     | `int32`   |
| `click_cost`   | int32 signed     | `int32`   |
| `passive_cost` | int32 signed     | `int32`   |
| `accumulator`  | float64 (double) | `float64` |

When using `int32` values in expressions with `int64`, Nim will not
auto-widen; cast explicitly at the comparison/assignment site:

```nim
if currency >= int64(clickCost):
  currency -= int64(clickCost)
  clickPower += 1
  clickCost = nextCost(clickCost)
```

Same pattern for the passive branch.

## Allowed calls

Full Nim call list, in the order they appear in the source:

```
initWindow(width: int32, height: int32, title: string)
setTargetFps(fps: int32)
windowShouldClose(): bool
getFrameTime(): float32
getMousePosition(): Vector2
isMouseButtonPressed(MouseButton.Left): bool
checkCollisionPointRec(point: Vector2, rec: Rectangle): bool
beginDrawing()
clearBackground(color: Color)
drawRectangle(x, y, width, height: int32, color: Color)
drawRectangleLinesEx(rec: Rectangle, lineThick: float32, color: Color)
drawText(text: string, x, y, fontSize: int32, color: Color)
measureText(text: string, fontSize: int32): int32
endDrawing()
closeWindow()
```

That's every raylib symbol the program touches. Anything outside this
list is out of scope.

## Known version skew

naylib's API is stable within the 5.x series, but two pieces have shifted
across releases worth flagging:

- **`drawRectangleLinesEx` thickness type:** newer naylib takes
  `float32`; some older versions took `int32`. If the implementer hits a
  type error, change the literal: `3.0'f32` → `3'i32` (or vice versa)
  and `2.0'f32` → `2'i32`. No other code change needed.
- **MouseButton scoping:** newer naylib scopes the enum
  (`MouseButton.Left`); some pre-5.0 releases exported `MouseButtonLeft`
  as a flat constant. If the dotted form fails to compile, fall back to
  `MouseButtonLeft`. Spec §8 explicitly allows the older naming.

If a future naylib renames any of these procs (unlikely — the wrapper
mirrors raylib's stable C names), the fix is one identifier in one
place.

## What we deliberately don't use

These are exposed by naylib but NOT in spec §8 and the implementation
must NOT reach for them even when convenient:

- `drawTextEx` — would let us pass a custom font. Spec §1 forbids
  external assets and §8 lists only `drawText`.
- `drawing:` template — would auto-pair `beginDrawing`/`endDrawing`.
  Nice ergonomics, but the spec calls out the explicit pair.
- `drawRectangleRec` — naylib exposes both `drawRectangle(x, y, w, h, …)`
  and `drawRectangleRec(rect, color)`. Spec §8 only lists
  `DrawRectangle` (the int-coords variant). The plan uses `drawRectangle`
  with integer coords cast from the rect's `float32` fields.
- `drawRectangleLines` (without `Ex`) — spec §8 allows it as a fallback,
  but newer naylib has `drawRectangleLinesEx` and the spec prefers `Ex`
  for thickness control. Use `Ex`.
- `isMouseButtonDown` / `isMouseButtonReleased` — we use *Pressed*
  (edge-triggered) per spec §6 step 3.
- `getMouseDelta`, scroll-wheel procs, keyboard procs.
- Any `Vector2` math helpers — we read the position once and pass it to
  `checkCollisionPointRec`; no arithmetic needed.
- `loadFont`, `loadTexture`, `loadSound`, `loadImage`, etc. — no assets.
- raygui (`import rlgl` / `import raygui`) — spec §1: raylib only.

## What naylib gives us for free

A few naylib conveniences that the spec implicitly allows (they are
adapters around the §8 calls, not new functionality):

- **Implicit `string` → `cstring`.** Nim `string`s are auto-converted at
  the FFI boundary; no `cstring(...)` casts needed.
- **`Color` is a value type with `(r, g, b, a: uint8)` fields**, but we
  only ever use the eight named constants — never construct one.
- **ARC/ORC memory management** for the (small) string allocations from
  `strformat`. No leaks, no manual frees.

These do not introduce raylib functionality beyond §8; they only smooth
the Nim ↔ C boundary.
