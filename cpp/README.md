# Idle Clicker (C++ / raylib)

A minimal idle-clicker game written in C++17 against raylib. Click the green square to earn currency, then spend it on two upgrades: stronger clicks and passive income per second. The whole game lives in a single 800×600 window with no external assets.

## Build (CMake)

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
./build/idle_clicker
```

## Build (alternative, g++ one-liner)

```bash
g++ -std=c++17 -O2 main.cpp -o idle_clicker $(pkg-config --cflags --libs raylib)
./idle_clicker
```

On macOS without a `pkg-config` file for raylib, link against Homebrew directly:

```bash
g++ -std=c++17 -O2 main.cpp -o idle_clicker \
    -I/opt/homebrew/include -L/opt/homebrew/lib -lraylib \
    -framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL
```

## Controls

Left-click the green square to earn currency; left-click an upgrade panel to buy it.
