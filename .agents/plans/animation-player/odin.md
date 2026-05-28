# Odin — animation-player

See [README.md](./README.md) for the shared design, constants, and the
reward-forfeit behavioral note. This file is only the Odin-specific syntax.

## Files touched

- `odin/game/run.odin` — all changes live here.
- `odin/main.odin` — **unchanged** (`rl.InitWindow` runs before `game.run`).
- `odin/game/ui_helpers.odin` — **unchanged**.

## vendor:raylib notes

- `rl.LoadTexture(fileName: cstring) -> Texture2D`. `COIN_SHEET_PATH :: "..."` is
  an *untyped* string constant, which Odin coerces to `cstring` at the call site,
  so `rl.LoadTexture(COIN_SHEET_PATH)` compiles. (If a build ever complains, wrap
  it: `rl.LoadTexture(cstring(COIN_SHEET_PATH))`.)
- `rl.UnloadTexture` is **explicit** — pair the load with `defer` so it runs
  when `run` returns.
- `rl.DrawTexturePro(texture, source, dest, origin, rotation, tint)`; tint is
  `rl.WHITE`.
- **Odin errors on unused locals** — when you delete `block_h` (step 6) it must
  go completely, or the build fails. The new `coin` / `coin_src` are all used.

## Steps (all in `odin/game/run.odin`)

1. Add constants near `CLICK_BUTTON` (top level, `::`):
   ```odin
   COIN_FRAMES     :: 8
   COIN_FRAME_W    :: 128
   COIN_FRAME_H    :: 128
   COIN_FRAME_TIME :: 0.06
   COIN_SHEET_PATH :: "../assets/coin_sheet.png"

   COIN_DEST :: rl.Rectangle{x = 125, y = 232, width = 150, height = 150}
   ```

2. In `run`, after the existing locals (`accumulator: f64 = 0.0`) and before the
   `for !rl.WindowShouldClose()` loop, load the texture and add state:
   ```odin
   coin := rl.LoadTexture(COIN_SHEET_PATH)
   defer rl.UnloadTexture(coin)

   anim_playing := false
   anim_frame:  i32 = 0
   anim_timer:  f64 = 0.0
   ```

3. Animation advance — after the passive accumulation `for accumulator >= 1.0`
   loop and before `mouse := rl.GetMousePosition()`:
   ```odin
   if anim_playing {
       anim_timer += f64(dt)
       for anim_timer >= COIN_FRAME_TIME {
           anim_timer -= COIN_FRAME_TIME
           anim_frame += 1
           if anim_frame >= COIN_FRAMES {
               anim_frame   = COIN_FRAMES - 1
               anim_playing = false
               currency    += i64(click_power)
               break
           }
       }
   }
   ```

4. Click handler — replace the `CLICK_BUTTON` branch body
   (`currency += i64(click_power)`) with:
   ```odin
   anim_playing = true
   anim_frame   = 0
   anim_timer   = 0.0
   ```
   Leave the `else if` upgrade branches unchanged.

5. Drawing — after `rl.DrawRectangleLinesEx(CLICK_BUTTON, 3, rl.DARKGREEN)` and
   before the `"CLICK"` text:
   ```odin
   coin_src := rl.Rectangle{
       x = f32(anim_frame) * COIN_FRAME_W, y = 0,
       width = COIN_FRAME_W, height = COIN_FRAME_H,
   }
   rl.DrawTexturePro(coin, coin_src, COIN_DEST, rl.Vector2{0, 0}, 0, rl.WHITE)
   ```

6. Move the label below the coin: change
   ```odin
   top_y   := i32(CLICK_BUTTON.y) + (i32(CLICK_BUTTON.height) - block_h) / 2
   ```
   to
   ```odin
   top_y   := i32(388)
   ```
   and **delete** the `block_h := i32(FONT_TITLE + FONT_LARGE)` line (unused →
   compile error otherwise).

## Verification

```
odin/scripts/build_and_run.sh
# click the coin: currency only rises at the end of the spin; re-click restarts at frame 0
grep -n "currency += i64(click_power)" odin/game/run.odin   # expect: only inside the anim-complete block
```
