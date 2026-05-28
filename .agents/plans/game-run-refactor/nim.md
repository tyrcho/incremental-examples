# Nim — game-run-refactor

## Current layout

```
nim/
  src/
    idle_clicker.nim   # imports raylib + ./game_loop; calls runGameLoop()
    game_loop.nim      # WINDOW_W/H, geometry, nextCost, proc runGameLoop*
    ui_helpers.nim     # FONT_*, drawCenteredText*, drawUpgradeButton*
  idle_clicker.nimble  # bin = @["idle_clicker"]
```

## Target layout

```
nim/
  src/
    idle_clicker.nim          # entry only
    game/
      run.nim                 # WINDOW_W/H, nextCost, proc run*
      ui_helpers.nim          # unchanged contents
  idle_clicker.nimble         # unchanged
```

## Steps

1. `mkdir nim/src/game`.
2. `git mv nim/src/ui_helpers.nim nim/src/game/ui_helpers.nim`. Contents
   unchanged.
3. `git mv nim/src/game_loop.nim nim/src/game/run.nim`. Inside:
   - Change `import ./ui_helpers` → `import ./ui_helpers` (same path now that
     both files are in `src/game/`).
   - Rename `proc runGameLoop*()` → `proc run*()`.
   - Constants (`WINDOW_W`, `WINDOW_H`, etc.) keep their `*` export marker.
4. Update `nim/src/idle_clicker.nim`:
   ```nim
   import raylib
   import ./game/run

   proc main() =
     initWindow(run.WINDOW_W, run.WINDOW_H, "Idle Clicker")
     setTargetFps(60)
     run.run()
     closeWindow()

   when isMainModule:
     main()
   ```
   `run.run()` is awkward — alternative: `from ./game/run as game import run, WINDOW_W, WINDOW_H` then `game.run()`. Pick whichever reads better; the
   second is recommended.
5. `idle_clicker.nimble` — no change. `srcDir = "src"` still points at the
   entry module.

## Things to watch

- Nim resolves `import ./game/run` against the importing file's directory.
  `idle_clicker.nim` is in `src/`, so `./game/run` resolves to
  `src/game/run.nim` ✓.
- If you use `from ... as game import ...`, only the listed symbols are
  visible — that's fine for the entry file but won't work as a general
  re-export.
- `runGameLoop` was the only public symbol in the old module. After renaming
  to `run`, grep to confirm no other file referenced the old name.

## Verification

```
nim/scripts/build_and_run.sh
grep -rn "runGameLoop\|game_loop\.nim" nim   # expect: no hits
```
