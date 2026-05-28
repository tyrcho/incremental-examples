# Odin — game-run-refactor

## Current layout

```
odin/
  main.odin          # package main; calls run_game_loop()
  game_loop.odin     # package main; WINDOW_W/H, geometry, run_game_loop
  ui_helpers.odin    # package main; FONT_*, draw_centered_text, ...
```

All three files are `package main`. Odin packages are directory-bound, so
moving only `game_loop.odin` is not enough — the helpers come with it.

## Target layout

```
odin/
  main.odin          # package main; imports game; calls game.run()
  game/
    run.odin         # package game; WINDOW_W/H, geometry, proc run
    ui_helpers.odin  # package game; FONT_*, draw_centered_text, ...
```

## Steps

1. `mkdir odin/game`.
2. `git mv odin/ui_helpers.odin odin/game/ui_helpers.odin`. Change the
   `package main` line to `package game`. No other content changes.
3. `git mv odin/game_loop.odin odin/game/run.odin`. Inside:
   - `package main` → `package game`.
   - Rename `run_game_loop :: proc()` → `run :: proc()`.
   - `next_cost :: proc(...)` stays — same package as `run`.
4. Update `odin/main.odin`:
   ```odin
   package main

   import rl "vendor:raylib"
   import "game"

   main :: proc() {
       rl.InitWindow(game.WINDOW_W, game.WINDOW_H, "Idle Clicker")
       defer rl.CloseWindow()
       rl.SetTargetFPS(60)
       game.run()
   }
   ```

## Things to watch

- `WINDOW_W` / `WINDOW_H` are `::` constants. Once the file is in
  `package game`, they're exported as `game.WINDOW_W` / `game.WINDOW_H`.
  Currently `main.odin` references them bare; that breaks until the
  import-and-qualify is in place. Update `main.odin` in the same commit
  as the package move.
- Odin import syntax: the build is invoked as `odin build .` from `odin/`
  (see `scripts/build_and_run.sh`), which makes `odin/` the collection
  root. The idiomatic form for a sibling-directory package is therefore
  `import "game"` — *not* `import "./game"`. The resulting name binding
  is the package name declared inside the directory's files (`game`).
  Don't alias unless needed.
- `game_loop.odin` uses `fmt.ctprintf` and `free_all(context.temp_allocator)`.
  Those keep working inside `package game` — `context` is built-in and
  `core:fmt` is just an `import` away (already there).
- Search for any other `run_game_loop` references in `odin/` after the
  rename.

## Verification

```
odin/scripts/build_and_run.sh
grep -rn "run_game_loop\|game_loop\.odin" odin   # expect: no hits
```
