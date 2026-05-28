# Crystal — game-run-refactor

## Current layout

```
crystal/
  src/
    idle_clicker.cr   # @[Link("raylib")] lib LibRaylib { ... }
                      # color constants (RAYWHITE, BLACK, ...)
                      # entry point: InitWindow → run_game_loop → CloseWindow
    game_loop.cr      # WINDOW_W/H, geometry constants, next_cost, run_game_loop
    ui_helpers.cr     # FONT_*, draw_centered_text, draw_upgrade_button
  shard.yml           # targets.idle_clicker.main: src/idle_clicker.cr
```

## Target layout

```
crystal/
  src/
    idle_clicker.cr        # entry point only; requires Game, calls Game.run
    game/
      raylib_lib.cr        # LibRaylib FFI block + color constants
      run.cr               # module Game; geometry; def self.run; def next_cost
      ui_helpers.cr        # module Game; FONT_*; helper procs
  shard.yml                # unchanged
```

## The Crystal-specific gotcha: load order

`idle_clicker.cr` today does `require "./game_loop"` at the top of the file
but the `lib LibRaylib` block and color constants it references are written
*lower down in the same file*. This currently works because Crystal performs
whole-program semantic analysis after parsing — declarations are not order-
dependent the way Ruby's are.

**Do not rely on that any further than necessary.** As part of this refactor,
extract the FFI bindings + color constants out of `idle_clicker.cr` into a
dedicated `src/game/raylib_lib.cr`, and `require` it first from both the
entry file and the new game module files. This removes the implicit cycle
and makes the dependency direction visible.

## Steps

1. `mkdir crystal/src/game`.
2. Create `crystal/src/game/raylib_lib.cr`:
   - Move the `@[Link("raylib")] lib LibRaylib ... end` block out of
     `idle_clicker.cr`.
   - Move `MOUSE_BUTTON_LEFT` and every `Color.new(...)` constant
     (`RAYWHITE`, `BLACK`, `DARKGRAY`, `LIGHTGRAY`, `GREEN`, `DARKGREEN`,
     `SKYBLUE`, `RED`) out as well. Keep them as top-level constants — every
     existing call site reads them unqualified.
3. `git mv crystal/src/ui_helpers.cr crystal/src/game/ui_helpers.cr`. Wrap the
   file body in `module Game ... end`. Mark the two procs with `def self.`
   so they're callable as `Game.draw_centered_text` / `Game.draw_upgrade_button`.
   Add `require "./raylib_lib"` at the top.
4. `git mv crystal/src/game_loop.cr crystal/src/game/run.cr`. Inside:
   - `require "./raylib_lib"` and `require "./ui_helpers"` at the top.
   - Wrap everything in `module Game ... end`.
   - Rename `def run_game_loop` → `def self.run`.
   - Change `next_cost` to `def self.next_cost` (it's used only inside Game).
   - Every top-level constant in this file moves into `Game::`:
     - Integers: `WINDOW_W`, `WINDOW_H`, `TITLE_Y`, `CURRENCY_Y`, `PASSIVE_Y`.
     - `LibRaylib::Rectangle` constants: `CLICK_BUTTON`, `CLICK_UPGRADE`,
       `PASSIVE_UPGRADE`.
   - The `FONT_*` constants in `ui_helpers.cr` likewise become `Game::FONT_*`
     once that file is wrapped in `module Game` (step 3).
   - Helper calls inside `Game.run` stay written unqualified —
     `draw_centered_text(...)`, `draw_upgrade_button(...)`, `next_cost(...)` —
     because all three call sites and definitions live inside `module Game`,
     where Crystal resolves bare method calls to module-method `def self.`
     forms. From *outside* `module Game` they are `Game.draw_centered_text`,
     `Game.draw_upgrade_button`, `Game.next_cost`.
5. Rewrite `crystal/src/idle_clicker.cr` to roughly:
   ```crystal
   require "lib_c"
   require "./game/run"

   LibRaylib.init_window(Game::WINDOW_W, Game::WINDOW_H, "Idle Clicker")
   LibRaylib.set_target_fps(60)
   Game.run
   LibRaylib.close_window
   ```
6. `shard.yml` — no change. The entry point is still `src/idle_clicker.cr`.

## Things to watch

- Color constants stay top-level (not inside `module Game`) so that
  `LibRaylib.clear_background(RAYWHITE)` calls inside `Game.run` still resolve.
  If you choose to nest them under `Game::`, every call site needs the
  prefix.
- Crystal does not require explicit `require` for files in the same target,
  but the project does use them — keep that style.
- After the move, run `crystal tool format src/` to keep formatting clean.

## Verification

```
crystal/scripts/build_and_run.sh
grep -rn "run_game_loop\|src/game_loop" crystal   # expect: no hits
```
