# Idle Clicker (Crystal / raylib)

Single-file Crystal port of the cross-language idle-clicker spec. The game opens an 800×600 window: click the green square to earn currency, then buy upgrades on the right to increase click power and passive income.

## Prereqs

```bash
brew install crystal raylib
```

## Build and run

```bash
shards build --release --no-debug
./bin/idle_clicker
```

## Controls

Left-click the green square to earn currency; left-click an upgrade panel to buy it when you can afford it.

## Notes

raylib is loaded dynamically via Homebrew's `libraylib.dylib`. The ~14 raylib functions used by the game are declared inline as a hand-rolled `lib LibRaylib` FFI block at the top of `src/idle_clicker.cr` — no third-party raylib shard is used.
