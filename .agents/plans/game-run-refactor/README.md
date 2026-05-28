# game-run-refactor

Refactor each language's idle-clicker example to:

1. **Move the game loop into a `game` directory / package / module** alongside its
   helper code, so `main` no longer sits next to loop internals.
2. **Rename the loop file `game_loop` → `run`** and the entry function
   `run_game_loop` → `run`. After the refactor, the entry point reads
   `game.run()` / `game::run()` / `Game.run` depending on the language.

## Assumptions

- Both the file and the function are renamed (`game_loop.X → run.X`,
  `run_game_loop → run`). If only one was intended, flag and stop.
- `ui_helpers` moves into the `game` namespace too. It is used exclusively by the
  loop, so co-locating it keeps `main` clean. Each per-language plan calls this
  out explicitly.
- The window-construction constants `WINDOW_W` / `WINDOW_H`, currently exported
  from `game_loop`, become part of the new `game` namespace and `main` reads
  them through that namespace.
- Behaviour is identical post-refactor. No gameplay, layout, or build-script
  changes beyond what file moves require.

## Per-language plans

- [cpp.md](./cpp.md) — header-only, namespace `game`
- [crystal.md](./crystal.md) — `module Game` under `src/game/`; FFI load order
  is the gotcha to verify
- [nim.md](./nim.md) — `src/game/run.nim` with `import ./game/run`
- [odin.md](./odin.md) — directory-bound `package game`; helpers must move with
  the loop
- [rust.md](./rust.md) — `src/game/mod.rs` exposes `pub fn run`

## Acceptance (same for every language)

- `scripts/build_and_run.sh` builds clean from a wiped output dir.
- The binary launches a 800×600 window titled "Idle Clicker" and clicks /
  upgrades behave identically to the pre-refactor build.
- No file at the language root still references `game_loop` or `run_game_loop`.
