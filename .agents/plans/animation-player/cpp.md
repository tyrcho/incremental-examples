# C++ — animation-player

See [README.md](./README.md) for the shared design, constants, and the
reward-forfeit behavioral note. This file is only the C++-specific syntax.

## Files touched

- `cpp/game/run.hpp` — all changes live here.
- `cpp/main.cpp` — **unchanged** (`InitWindow` already runs before `game::run`).
- `cpp/game/ui_helpers.hpp` — **unchanged**.

## raylib (C API) notes

- `Texture2D LoadTexture(const char *fileName)` loads after the window exists.
- `UnloadTexture(Texture2D)` is **explicit** — call it before `run` returns.
- `DrawTexturePro(Texture2D, Rectangle source, Rectangle dest, Vector2 origin,
  float rotation, Color tint)` is the draw call. `WHITE` is a built-in raylib
  color macro.

## Steps (all in `cpp/game/run.hpp`)

1. Add constants in the `namespace game` block, near the `WINDOW_*` /
   `CLICK_BUTTON` constants:
   ```cpp
   inline constexpr int   COIN_FRAMES     = 8;
   inline constexpr float COIN_FRAME_W    = 128.0f;
   inline constexpr float COIN_FRAME_H    = 128.0f;
   inline constexpr double COIN_FRAME_TIME = 0.06;
   inline constexpr const char* COIN_SHEET_PATH = "../assets/coin_sheet.png";

   inline constexpr Rectangle COIN_DEST = { 125.0f, 232.0f, 150.0f, 150.0f };
   ```

2. At the top of `run`, after the existing locals, load the texture and add
   animation state:
   ```cpp
   Texture2D coin = LoadTexture(COIN_SHEET_PATH);
   bool   anim_playing = false;
   int    anim_frame   = 0;
   double anim_timer   = 0.0;
   ```

3. Animation advance — after the passive accumulation `while` loop and before
   `Vector2 mouse = GetMousePosition();`:
   ```cpp
   if (anim_playing) {
       anim_timer += (double)dt;
       while (anim_timer >= COIN_FRAME_TIME) {
           anim_timer -= COIN_FRAME_TIME;
           anim_frame += 1;
           if (anim_frame >= COIN_FRAMES) {
               anim_frame   = COIN_FRAMES - 1;
               anim_playing = false;
               currency    += click_power;
               break;
           }
       }
   }
   ```

4. In the click handler, replace the `CLICK_BUTTON` branch body
   (`currency += click_power;`) with:
   ```cpp
   anim_playing = true;
   anim_frame   = 0;
   anim_timer   = 0.0;
   ```
   Leave the upgrade branches unchanged.

5. Drawing — after `DrawRectangleLinesEx(CLICK_BUTTON, 3.0f, DARKGREEN);` and
   before the `"CLICK"` text, add:
   ```cpp
   Rectangle coin_src = { anim_frame * COIN_FRAME_W, 0.0f, COIN_FRAME_W, COIN_FRAME_H };
   DrawTexturePro(coin, coin_src, COIN_DEST, Vector2{ 0.0f, 0.0f }, 0.0f, WHITE);
   ```

6. Move the label below the coin: change
   ```cpp
   int top_y = (int)CLICK_BUTTON.y + ((int)CLICK_BUTTON.height - block_h) / 2;
   ```
   to
   ```cpp
   int top_y = 388;
   ```
   (`block_h` is now unused — delete its declaration.)

7. Unload before returning: at the very end of `run`, after the `while
   (!WindowShouldClose())` loop closes, add:
   ```cpp
   UnloadTexture(coin);
   ```

## Verification

```
cpp/scripts/build_and_run.sh
# click the coin: currency only rises at the end of the spin; re-click restarts at frame 0
grep -n "currency += click_power" cpp/game/run.hpp   # expect: only inside the anim-complete block
```
