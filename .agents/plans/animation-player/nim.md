# Nim — animation-player

See [README.md](./README.md) for the shared design, constants, and the
reward-forfeit behavioral note. This file is only the Nim-specific syntax.

## Files touched

- `nim/src/game/run.nim` — all changes live here.
- `nim/src/idle_clicker.nim` — **unchanged** (`initWindow` runs before `game.run`).
- `nim/src/game/ui_helpers.nim` — **unchanged**.

## naylib notes (two divergences from the README's generic API)

- **Naming:** Nim convention is camelCase, so the README's `anim_playing` etc.
  become `animPlaying`, `animFrame`, `animTimer`. The numeric values are
  identical to every other language.
- **`drawTexture` overload:** naylib folds the whole `DrawTexture*` family into
  overloads of `drawTexture`. Use
  `drawTexture(coin, source, dest, origin, rotation, tint)` — this 6-arg overload
  (`source: Rectangle, dest: Rectangle, origin: Vector2, rotation: float32, tint:
  Color`) is naylib's mapping of C's `DrawTexturePro`. There is no separate
  `drawTexturePro` proc in current naylib; it is overload-only.
- **`loadTexture` raises on failure** (unlike the raw C API the README
  describes). A bad path throws `RaylibError` and aborts — which is a *better*
  failure mode for setup. Just make sure `../assets/coin_sheet.png` exists.
- **RAII:** naylib's `Texture2D` auto-unloads via `=destroy` when `run` returns
  — **no manual unload**.

## Steps (all in `nim/src/game/run.nim`)

1. Add to the `const` block near `CLICK_BUTTON`:
   ```nim
   COIN_FRAMES:     int32   = 8
   COIN_FRAME_W:    float32 = 128.0
   COIN_FRAME_H:    float32 = 128.0
   COIN_FRAME_TIME: float64 = 0.06
   COIN_SHEET_PATH          = "../assets/coin_sheet.png"

   COIN_DEST = Rectangle(x: 125, y: 232, width: 150, height: 150)
   ```

2. In `run`, after the existing `var` block, load the texture and add state:
   ```nim
   let coin = loadTexture(COIN_SHEET_PATH)
   var
     animPlaying = false
     animFrame: int32 = 0
     animTimer: float64 = 0.0
   ```

3. Animation advance — after the passive accumulation `while` loop and before
   `let mouse = getMousePosition()`:
   ```nim
   if animPlaying:
     animTimer += float64(dt)
     while animTimer >= COIN_FRAME_TIME:
       animTimer -= COIN_FRAME_TIME
       animFrame += 1
       if animFrame >= COIN_FRAMES:
         animFrame = COIN_FRAMES - 1
         animPlaying = false
         currency += int64(clickPower)
         break
   ```

4. Click handler — replace the `CLICK_BUTTON` branch body
   (`currency += int64(clickPower)`) with:
   ```nim
   animPlaying = true
   animFrame = 0
   animTimer = 0.0
   ```
   Leave the `elif` upgrade branches unchanged.

5. Drawing — after `drawRectangleLines(CLICK_BUTTON, 3.0'f32, DarkGreen)` and
   before the `block:` that draws the CLICK text:
   ```nim
   let coinSrc = Rectangle(
     x: float32(animFrame) * COIN_FRAME_W, y: 0,
     width: COIN_FRAME_W, height: COIN_FRAME_H)
   drawTexture(coin, coinSrc, COIN_DEST, Vector2(x: 0, y: 0), 0.0'f32, White)
   ```

6. Move the label below the coin: inside that `block:`, change
   ```nim
   let topY = int32(CLICK_BUTTON.y) +
              (int32(CLICK_BUTTON.height) - totalH) div 2
   ```
   to
   ```nim
   let topY = 388'i32
   ```
   (`totalH` is now unused — delete its `let` line.)

## Verification

```
nim/scripts/build_and_run.sh
# click the coin: currency only rises at the end of the spin; re-click restarts at frame 0
grep -n "currency += int64(clickPower)" nim/src/game/run.nim   # expect: only inside the anim-complete block
```
