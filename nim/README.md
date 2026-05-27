# Idle Clicker (Nim + naylib)

A minimal idle clicker built with naylib, the Nim wrapper around raylib.
Click the green square to earn currency. Buy upgrades on the right to
increase your per-click yield or earn passive income per second. Costs
scale 1.5× per purchase.

## Build

    nimble install -d
    nimble build -d:release

(The first `nimble install` compiles naylib's bundled raylib C sources;
expect a couple of minutes. Subsequent builds are fast.)

## Run

    ./idle_clicker

## Controls

Left-click. That's all.
