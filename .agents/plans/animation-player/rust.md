# Rust — animation-player

See [README.md](./README.md) for the shared design, constants, and the
reward-forfeit behavioral note. This file is only the Rust-specific syntax.

## Files touched

- `rust/src/game/mod.rs` — all changes live here.
- `rust/src/main.rs` — **unchanged** (window is created here; texture loads in `run`).
- `rust/src/game/ui_helpers.rs` — **unchanged**.

## raylib-rs notes

- `rl.load_texture(thread, path)` returns `Result<Texture2D, Error>` (raylib-rs's
  own error type, not `String`). The `Texture2D` is RAII — it unloads on drop
  when `run` returns, so **no manual unload**.
- Borrow ordering is fine: load the texture before the loop while you hold
  `&mut rl`; the per-frame `rl.begin_drawing(thread)` borrow comes later and
  doesn't overlap.
- `RaylibDrawHandle::draw_texture_pro(texture, source, dest, origin, rotation, tint)`
  is the draw call. `Rectangle`, `Vector2`, `Color` are already in scope via
  `raylib::prelude::*`.

## Steps (all in `rust/src/game/mod.rs`)

1. Add constants near the existing `WINDOW_*` block:
   ```rust
   const COIN_FRAMES: i32 = 8;
   const COIN_FRAME_W: f32 = 128.0;
   const COIN_FRAME_H: f32 = 128.0;
   const COIN_FRAME_TIME: f64 = 0.06;
   const COIN_SHEET_PATH: &str = "../assets/coin_sheet.png";

   const COIN_DEST: Rectangle = Rectangle { x: 125.0, y: 232.0, width: 150.0, height: 150.0 };
   ```

2. At the top of `run`, after the existing `let mut accumulator …`, load the
   texture and add the animation state:
   ```rust
   let coin = rl
       .load_texture(thread, COIN_SHEET_PATH)
       .expect("load coin_sheet.png");
   let mut anim_playing = false;
   let mut anim_frame: i32 = 0;
   let mut anim_timer: f64 = 0.0;
   ```
   > `.expect` is fine for an example. If you prefer the README's silent
   > zero-texture fallback, use `.unwrap_or_default()` instead — but `expect`
   > gives a clearer message during setup.

3. Animation advance — insert **after** the passive accumulation `while` loop
   and **before** `let mouse = …`:
   ```rust
   if anim_playing {
       anim_timer += dt as f64;
       while anim_timer >= COIN_FRAME_TIME {
           anim_timer -= COIN_FRAME_TIME;
           anim_frame += 1;
           if anim_frame >= COIN_FRAMES {
               anim_frame = COIN_FRAMES - 1;
               anim_playing = false;
               currency += click_power as i64;
               break;
           }
       }
   }
   ```

4. In the click handler, replace the `CLICK_BUTTON` branch body
   (`currency += click_power as i64;`) with:
   ```rust
   anim_playing = true;
   anim_frame = 0;
   anim_timer = 0.0;
   ```
   Leave the `CLICK_UPGRADE` / `PASSIVE_UPGRADE` branches as-is.

5. Drawing — inside the CLICK_BUTTON draw block, after
   `d.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0, Color::DARKGREEN);` and before
   the `{ let line2 = … }` text block, add:
   ```rust
   let source = Rectangle {
       x: anim_frame as f32 * COIN_FRAME_W,
       y: 0.0,
       width: COIN_FRAME_W,
       height: COIN_FRAME_H,
   };
   d.draw_texture_pro(&coin, source, COIN_DEST, Vector2::zero(), 0.0, Color::WHITE);
   ```

6. Move the label below the coin: in that same text block, change
   ```rust
   let cy = CLICK_BUTTON.y as i32 + (CLICK_BUTTON.height as i32 - total_h) / 2;
   ```
   to a fixed top:
   ```rust
   let cy = 388;
   ```
   (`total_h` is now unused — delete its `let` line to avoid a warning.)

## Verification

```
rust/scripts/build_and_run.sh
# click the coin: currency only rises when the spin ends; re-click restarts at frame 0
grep -n "currency += click_power" rust/src/game/mod.rs   # expect: only inside the anim-complete block
cargo clippy --manifest-path rust/Cargo.toml -- -D warnings   # optional
```
