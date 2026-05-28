# Idle Clicker (Odin / raylib)

A minimal idle-clicker game in Odin (a `main` entry point plus a `game` package) using the bundled `vendor:raylib` collection. Opens an 800×600 window, lets you accumulate currency by clicking a green square, and offers two upgrades (click power, passive income). No external assets and no separate raylib install — Odin ships prebuilt raylib static libraries for macOS, Linux, and Windows as part of its standard distribution.

## Build

```bash
odin build . -o:speed -out:idle_clicker
```

## Run

```bash
./idle_clicker
```

Or do both in one step for development:

```bash
odin run . -o:speed
```

## Controls

Left-click the green square to earn currency; left-click an upgrade panel to buy it (if you can afford it).
