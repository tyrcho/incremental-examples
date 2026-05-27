# Idle Clicker (Odin / raylib) — Plan Index

Implementation plan for the spec at `~/Downloads/idle_clicker_spec.md`, targeting Odin with the bundled `vendor:raylib` collection.

## Goal

A 100–200 line single-source Odin program that opens an 800×600 raylib window titled "Idle Clicker", lets the player accumulate currency by clicking a green square and buying two upgrades (click power, passive income). No external assets, no extra features beyond the spec.

## Plan documents

1. [`01-setup-and-build.md`](./01-setup-and-build.md) — Directory layout, Odin install, why `vendor:raylib` needs no separate raylib install, build commands.
2. [`02-implementation.md`](./02-implementation.md) — Single-file source walkthrough mapped to spec §3–§7, with the Odin-side names of every spec §8 call.
3. [`03-acceptance.md`](./03-acceptance.md) — Manual verification checklist matching spec §11.

## Deliverables

Files produced under `incremental-examples/odin/`:

- `main.odin` — the entire game (single source file, `package main`).
- `README.md` — one paragraph, build/run commands, controls (left-click).

No project manifest. Odin's build tool discovers all `.odin` files in a package directory; spec §10 lists `odin run . -o:speed` as the canonical invocation and that is the whole story.

## Hard constraints (from spec)

- Only raylib for windowing/input/drawing.
- Only the raylib functions listed in spec §8.
- No image, font, or audio assets — default raylib font only.
- State is exactly the six primitives in spec §3; no structs of our own beyond the raylib types, no abstractions.
- Cost scaling uses integer arithmetic only: `new_cost = (old_cost * 3) / 2`.
- No save/load, animations, sound, extra upgrades, or prestige.

## Out of scope

Anything in the "Not add features beyond those specified" list from spec §1: persistence, animation, audio, extra upgrade types, prestige, settings menu, fullscreen toggle, keyboard input.

## Why Odin is the easy implementation

Of the five target languages, Odin has the lowest-friction setup: `vendor:raylib` ships with the Odin distribution, including prebuilt raylib static libraries for macOS (Intel + Apple Silicon), Linux, and Windows. There is no `brew install raylib`, no `pkg-config`, no `find_package`, no shard-side native install script. Install Odin → `odin run .` → window opens. This plan reflects that simplicity — `01-setup-and-build.md` is short on purpose.
