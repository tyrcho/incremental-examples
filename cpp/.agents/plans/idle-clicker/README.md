# Idle Clicker (C++ / raylib) — Plan Index

Implementation plan for the spec at `~/Downloads/idle_clicker_spec.md`, targeting C++17 with the raylib C API.

## Goal

A 100–200 line single-source C++ program that opens an 800×600 raylib window titled "Idle Clicker", lets the player accumulate currency by clicking a green square and buying two upgrades (click power, passive income). No external assets, no extra features beyond the spec.

## Plan documents

1. [`01-setup-and-build.md`](./01-setup-and-build.md) — Directory layout, raylib install, CMakeLists, alternative `g++` build line.
2. [`02-implementation.md`](./02-implementation.md) — Single-file source walkthrough mapped to spec §3–§7.
3. [`03-acceptance.md`](./03-acceptance.md) — Manual verification checklist matching spec §11.

## Deliverables

Files produced under `incremental-examples/cpp/`:

- `main.cpp` — the entire game (single translation unit).
- `CMakeLists.txt` — minimal, `find_package(raylib REQUIRED)`, C++17.
- `README.md` — one paragraph, build/run commands, controls (left-click).

## Hard constraints (from spec)

- Only raylib for windowing/input/drawing.
- Only the raylib functions listed in spec §8.
- No image, font, or audio assets — default raylib font only.
- State is exactly the six primitives in spec §3; no classes, no ECS, no traits.
- Cost scaling uses integer arithmetic only: `new_cost = (old_cost * 3) / 2`.
- No save/load, animations, sound, extra upgrades, or prestige.

## Out of scope

Anything in the "Not add features beyond those specified" list from spec §1: persistence, animation, audio, extra upgrade types, prestige, settings menu, fullscreen toggle, keyboard input.
