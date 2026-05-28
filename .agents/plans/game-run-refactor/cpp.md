# C++ — game-run-refactor

## Current layout

```
cpp/
  main.cpp           # InitWindow + run_game_loop()
  game_loop.hpp      # inline void run_game_loop(); WINDOW_W/H + UI constants
  ui_helpers.hpp     # FONT_*, draw_centered_text, draw_upgrade_button
  CMakeLists.txt     # add_executable(idle_clicker main.cpp)
```

Both headers are header-only / `inline`, so the refactor is purely a file
move + symbol rename. CMake does not need to learn about new source files.

## Target layout

```
cpp/
  main.cpp
  game/
    run.hpp          # namespace game { inline void run(); WINDOW_W/H; ... }
    ui_helpers.hpp   # namespace game { FONT_*; draw_centered_text; ... }
  CMakeLists.txt     # unchanged
```

## Steps

1. `mkdir cpp/game`.
2. `git mv cpp/ui_helpers.hpp cpp/game/ui_helpers.hpp`. Wrap the existing
   contents in `namespace game { ... }`.
3. `git mv cpp/game_loop.hpp cpp/game/run.hpp`. Inside:
   - Wrap everything in `namespace game { ... }`.
   - Rename `run_game_loop` → `run`.
   - Update the include to `#include "ui_helpers.hpp"` (same directory now).
4. Update `cpp/main.cpp`:
   ```cpp
   #include "game/run.hpp"

   int main() {
       InitWindow(game::WINDOW_W, game::WINDOW_H, "Idle Clicker");
       SetTargetFPS(60);
       game::run();
       CloseWindow();
       return 0;
   }
   ```
5. `CMakeLists.txt` — no change. `main.cpp` is the only listed source and
   includes are resolved relative to it.

## Things to watch

- **`#include` directives stay at file scope, not inside `namespace game`.**
  Wrap only the declarations and definitions — raylib's `#include <raylib.h>`
  in both `run.hpp` and `ui_helpers.hpp`, and `<cstdint>` / `<cstdio>` in
  `run.hpp`, must remain above the namespace block. If they get pulled
  inside, every raylib symbol (`InitWindow`, `SetTargetFPS`, `Rectangle`,
  `Color`, `MOUSE_BUTTON_LEFT`, …) ends up in `game::`, which breaks the
  raylib calls in `main.cpp` and turns every unqualified raylib reference
  inside the namespace into a compile error.
- Concretely, the structure of each header is:
  ```cpp
  #pragma once
  #include <raylib.h>
  // (other includes)

  namespace game {
      // constants, types, inline functions
  }
  ```
- `Rectangle`, `Color`, raylib free functions, and macros like
  `MOUSE_BUTTON_LEFT` come from `<raylib.h>` (C API, global namespace).
  They do **not** need `game::` qualification inside `namespace game` —
  provided the include stays outside the namespace per the rule above.
- `inline constexpr` globals stay valid across translation units when wrapped
  in a namespace. No ODR concern from this move.
- If anything still spells `run_game_loop`, the build will fail at link
  resolution — grep the tree after the rename.

## Verification

```
rm -rf cpp/build
cpp/scripts/build_and_run.sh   # builds + launches window
grep -rn "run_game_loop\|game_loop\.hpp" cpp   # expect: no hits
```
