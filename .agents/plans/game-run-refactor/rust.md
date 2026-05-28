# Rust — game-run-refactor

## Current layout

```
rust/
  src/
    main.rs           # mod game_loop; mod ui_helpers; calls run_game_loop
    game_loop.rs      # WINDOW_W/H, geometry, pub fn run_game_loop
    ui_helpers.rs     # FONT_*, draw_centered_text, draw_upgrade_button
  Cargo.toml          # name = "idle_clicker", raylib = "5"
```

## Target layout

```
rust/
  src/
    main.rs           # mod game; calls game::run(...)
    game/
      mod.rs          # WINDOW_W/H, geometry, pub fn run; mod ui_helpers;
      ui_helpers.rs   # FONT_*, helpers (unchanged contents)
  Cargo.toml          # unchanged
```

There is no need for a separate `run.rs` submodule — the only callable
exported from this package is `run` itself, so putting it directly in
`game/mod.rs` keeps `game::run` as the public surface without an extra
`game::run::run` layer.

## Steps

1. `mkdir rust/src/game`.
2. `git mv rust/src/ui_helpers.rs rust/src/game/ui_helpers.rs`. Contents
   unchanged.
3. `git mv rust/src/game_loop.rs rust/src/game/mod.rs`. Inside:
   - Replace `use crate::ui_helpers::*;` with `use self::ui_helpers::*;`.
   - Add `mod ui_helpers;` near the top.
   - Rename `pub fn run_game_loop` → `pub fn run`.
   - `pub const WINDOW_W: i32 = 800;` and `WINDOW_H` keep their `pub`
     visibility so `main` can read them as `game::WINDOW_W`.
4. Rewrite `rust/src/main.rs`:
   ```rust
   mod game;

   fn main() {
       let (mut rl, thread) = raylib::init()
           .size(game::WINDOW_W, game::WINDOW_H)
           .title("Idle Clicker")
           .build();
       rl.set_target_fps(60);
       game::run(&mut rl, &thread);
   }
   ```
5. `Cargo.toml` — no change. The bin target is auto-derived from `src/main.rs`.

## Things to watch

- The 2018+ module convention here is `game/mod.rs`. The alternative
  (`game.rs` plus a `game/` directory for submodules) would also work, but
  `mod.rs` is fine and keeps the move surface smaller.
- `ui_helpers.rs` is private to `mod game` after the move. Nothing else
  referenced it, so no `pub use` re-export is needed.
- `raylib::prelude::*` already brings `Rectangle`, `Color`, `MouseButton`,
  `RaylibHandle`, `RaylibThread`, and `RaylibDrawHandle` into scope; no
  signature change is required.
- After the rename, run `cargo build` once and let the compiler report any
  stale references — Rust's error messages will name them directly.

## Verification

```
rust/scripts/build_and_run.sh
grep -rn "run_game_loop\|game_loop\.rs\|mod game_loop" rust/src   # expect: no hits
cargo clippy --manifest-path rust/Cargo.toml -- -D warnings        # optional
```
