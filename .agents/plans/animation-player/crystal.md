# Crystal — animation-player

See [README.md](./README.md) for the shared design, constants, and the
reward-forfeit behavioral note. **Crystal is the gotcha language**: its raylib
binding is hand-written FFI, so the texture functions don't exist yet and must
be added before `run.cr` can use them.

## Files touched

- `crystal/src/game/raylib_lib.cr` — **add FFI bindings** (struct + 3 funs + WHITE).
- `crystal/src/game/run.cr` — the feature logic.
- `crystal/src/idle_clicker.cr` — **unchanged** (window already inits before `Game.run`).
- `crystal/src/game/ui_helpers.cr` — **unchanged**.

## Step 1 — extend `raylib_lib.cr`

Inside the `lib LibRaylib` block, add the `Texture2D` struct (field order/types
must match raylib.h exactly — `id` is `unsigned int`, the rest are `int`):

```crystal
struct Texture2D
  id      : UInt32
  width   : Int32
  height  : Int32
  mipmaps : Int32
  format  : Int32
end
```

…and the three functions (Crystal passes these structs by value, exactly like
the existing `Rectangle`/`Color` params):

```crystal
fun load_texture     = LoadTexture(file_name : LibC::Char*) : Texture2D
fun unload_texture   = UnloadTexture(texture : Texture2D)
fun draw_texture_pro = DrawTexturePro(texture : Texture2D, source : Rectangle, dest : Rectangle, origin : Vector2, rotation : Float32, tint : Color)
```

Then, alongside the other color constants at the bottom of the file, add:

```crystal
WHITE = LibRaylib::Color.new(r: 255_u8, g: 255_u8, b: 255_u8, a: 255_u8)
```

> Passing a Crystal `String` literal to the `LibC::Char*` param works the same
> way `init_window(..., "Idle Clicker")` already does — no manual conversion.

## Step 2 — constants in `run.cr`

In the `module Game` block, near the `CLICK_BUTTON` constants:

```crystal
COIN_FRAMES     =   8
COIN_FRAME_W    = 128.0_f32
COIN_FRAME_H    = 128.0_f32
COIN_FRAME_TIME = 0.06
COIN_SHEET_PATH = "../assets/coin_sheet.png"

COIN_DEST = LibRaylib::Rectangle.new(x: 125.0_f32, y: 232.0_f32, width: 150.0_f32, height: 150.0_f32)
```

## Step 3 — state + texture in `self.run`

After the existing `accumulator = 0.0` line:

```crystal
coin         = LibRaylib.load_texture(COIN_SHEET_PATH)
anim_playing = false
anim_frame   = 0
anim_timer   = 0.0
```

## Step 4 — animation advance

After the passive accumulation `while` loop, before `mouse = LibRaylib.get_mouse_position`:

```crystal
if anim_playing
  anim_timer += dt.to_f64
  while anim_timer >= COIN_FRAME_TIME
    anim_timer -= COIN_FRAME_TIME
    anim_frame += 1
    if anim_frame >= COIN_FRAMES
      anim_frame   = COIN_FRAMES - 1
      anim_playing = false
      currency    += click_power
      break
    end
  end
end
```

## Step 5 — click handler

Replace the `CLICK_BUTTON` branch body (`currency += click_power`) with:

```crystal
anim_playing = true
anim_frame   = 0
anim_timer   = 0.0
```

Leave the `elsif` upgrade branches unchanged.

## Step 6 — draw the coin

After `LibRaylib.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0_f32, DARKGREEN)` and
before the `"CLICK"` text:

```crystal
coin_src = LibRaylib::Rectangle.new(
  x: anim_frame.to_f32 * COIN_FRAME_W, y: 0.0_f32,
  width: COIN_FRAME_W, height: COIN_FRAME_H)
origin = LibRaylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
LibRaylib.draw_texture_pro(coin, coin_src, COIN_DEST, origin, 0.0_f32, WHITE)
```

## Step 7 — move the label below the coin

Change:
```crystal
top_y = CLICK_BUTTON.y.to_i + (CLICK_BUTTON.height.to_i - block_h) // 2
```
to:
```crystal
top_y = 388
```
(`block_h` becomes unused — delete its assignment.)

## Step 8 — unload before close

`Game.run` returns to `idle_clicker.cr`, which then calls `close_window`. Unload
the texture at the very end of `run`, after the `until` loop closes:

```crystal
LibRaylib.unload_texture(coin)
```

## Verification

```
crystal/scripts/build_and_run.sh
# click the coin: currency only rises at the end of the spin; re-click restarts at frame 0
grep -n "currency += click_power" crystal/src/game/run.cr   # expect: only inside the anim-complete block
grep -n "DrawTexturePro\|LoadTexture\|UnloadTexture" crystal/src/game/raylib_lib.cr   # bindings present
```
