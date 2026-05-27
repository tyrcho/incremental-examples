# 01 — Setup and Build

## Directory layout

```
incremental-examples/cpp/
├── CMakeLists.txt
├── main.cpp
└── README.md
```

Keep the project flat at the language root. No subfolders for `src/`, `include/`, etc. — a single source file does not warrant a tree, and the sibling Rust/Crystal/Odin/Nim ports also live at their respective language roots.

## Install raylib (macOS, this machine)

Raylib is not currently installed (`pkg-config --modversion raylib` failed, `/opt/homebrew/lib/libraylib*` empty). Use Homebrew:

```bash
brew install raylib
```

This drops the library at `/opt/homebrew/lib/libraylib.dylib` and the CMake config at `/opt/homebrew/lib/cmake/raylib/`. CMake's `find_package(raylib REQUIRED)` will pick it up automatically because Homebrew's prefix is on the default search path on Apple Silicon.

If the user is on Linux instead, `apt install libraylib-dev` (Debian/Ubuntu ≥ 22.04 ships raylib 4.x) or build from source. The plan does not need to enumerate every OS — the spec only requires "the system raylib".

## CMakeLists.txt

Minimal, exactly what spec §10 calls for:

```cmake
cmake_minimum_required(VERSION 3.15)
project(idle_clicker CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(raylib REQUIRED)

add_executable(idle_clicker main.cpp)
target_link_libraries(idle_clicker PRIVATE raylib)
```

No options, no fetch-content fallback, no warnings flags. The spec asks for "a minimal CMakeLists.txt"; this is it.

## Build commands

```bash
cd incremental-examples/cpp
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/idle_clicker
```

## Alternative one-line build (document in README)

Per spec §10, the README may instead carry a `g++` invocation. Include both for the user's convenience:

```bash
g++ -std=c++17 -O2 main.cpp -o idle_clicker $(pkg-config --cflags --libs raylib)
./idle_clicker
```

On macOS without `pkg-config` for raylib, the Homebrew-style fallback:

```bash
g++ -std=c++17 -O2 main.cpp -o idle_clicker \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib \
    -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL
```

Prefer the CMake path as primary in the README; keep the g++ line as a secondary block.

## README contents (for the deliverable, not this plan)

Single short file. Required sections per spec §10:

- One-paragraph description.
- Build command (CMake block above).
- Run command (`./build/idle_clicker`).
- Controls: "Left-click the green square to earn currency; left-click an upgrade to buy it."
- Optional: the alternative `g++` one-liner.

No screenshots, no design notes, no roadmap.
