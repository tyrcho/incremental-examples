# animation-player

Add a click animation to each language's idle-clicker. Today, clicking the big
green CLICK button awards `click_power` currency **immediately**. This feature
defers the reward behind a short, non-looping sprite animation:

1. **Clicking the button starts a non-looping coin-spin animation** instead of
   awarding currency right away.
2. **Currency is awarded when the animation reaches its final frame** (you get
   `click_power`, the same amount as today).
3. **Clicking the button again returns the animation to frame 0** and replays
   it from the start.

The upgrade buttons (Click Power, Passive Income) and passive income are
**unchanged**. Passive income keeps accumulating while the coin spins.

## Key behavioral consequence — confirm before implementing

Because a re-click resets the animation to frame 0 (point 3) and currency is
only awarded at the **final** frame (point 2), **rapid re-clicking forfeits the
pending reward**: the animation never finishes, so no currency banks. You must
let the spin complete before clicking again to collect. This is the literal
reading of the request ("clicking returns the animation to the starting frame"),
but it is an unusual game-feel choice — flag it at plan review. If instead the
intent is "queue one reward per click" or "let the current spin finish then
restart," say so and this plan changes.

## The asset

- **Source:** "Spinning coin anim" by **rzuf** on OpenGameArt —
  <https://opengameart.org/content/spinning-coin-anim>
- **License:** CC0 (public domain). No attribution required; crediting rzuf in
  the per-language READMEs is good practice but optional.
- **File:** `coin_sheet.png`, direct link
  <https://opengameart.org/sites/default/files/coin_sheet_0.png>
- **Layout (verified by inspecting the PNG):** `1024 × 128`, a single
  horizontal strip of **8 frames**, each **128 × 128**. Frame _i_ lives at
  source rect `{ x: i * 128, y: 0, w: 128, h: 128 }`. The coin is centered
  within every frame (the edge-on frames are thin but centered), so scaling a
  whole frame into a square destination keeps it centered — no per-frame offset
  math needed.

### Where the file goes

Commit the PNG **once** at `incremental-examples/assets/coin_sheet.png` and load
it from each language as the **identical** relative path `"../assets/coin_sheet.png"`.
This works because every `scripts/build_and_run.sh` does `cd "$(dirname "$0")/.."`
first, so the process working directory is always the language root
(`rust/`, `cpp/`, `nim/`, `odin/`, `crystal/`), and `../assets/` resolves to the
shared directory. One identical path string in all five plans is the maximally
"similar shape" option.

> Alternative (not recommended): copy the PNG into each language's own
> `assets/` dir and load `"assets/coin_sheet.png"`. Preserves per-language
> self-containment at the cost of committing the same ~45 KB file five times.

> **Setup step (do once, before any language work):**
> ```bash
> mkdir -p incremental-examples/assets
> curl -sL -o incremental-examples/assets/coin_sheet.png \
>   https://opengameart.org/sites/default/files/coin_sheet_0.png
> # verify: should print "PNG image data, 1024 x 128"
> file incremental-examples/assets/coin_sheet.png
> ```

### Load failure

The raw C-API languages (C++, Crystal, Odin) return a **zero-id texture** on a
bad path: raylib logs a warning to stderr and the program keeps running, drawing
nothing for the coin. The two bindings that wrap loading surface the failure
instead — Rust's `raylib` crate returns a `Result` (the plan uses `.expect`,
which aborts with a clear message) and Nim's naylib raises `RaylibError`. Both
are a *nicer* signal at setup time. Either way, **don't add extra
`IsTextureReady`/validity guards beyond what each binding already forces.** If
the coin never appears, confirm the process working directory is the language
root so `../assets/coin_sheet.png` resolves.

## Shared design (pin these once; per-language plans differ only in syntax)

### Constants

| Name              | Value | Meaning                                       |
| ----------------- | ----- | --------------------------------------------- |
| `COIN_FRAMES`     | `8`   | frames in the strip                           |
| `COIN_FRAME_W`    | `128` | source frame width (px)                       |
| `COIN_FRAME_H`    | `128` | source frame height (px)                      |
| `COIN_FRAME_TIME` | `0.06`| seconds per frame → ~0.48 s full spin (tune)  |
| `COIN_SHEET_PATH` | `"../assets/coin_sheet.png"` | path from language root        |

`COIN_DEST` — where the coin draws, centered horizontally in `CLICK_BUTTON`
(which is `{ 80, 220, 240, 240 }`), sitting above the button label:

```
COIN_DEST = { x: 125, y: 232, width: 150, height: 150 }
```

(`x = 80 + (240 - 150) / 2 = 125`.) These pixel values are tunable, but keep
them **identical across all five languages**.

### New per-run state (locals inside `run`, alongside `currency` etc.)

| Name           | Type        | Init    |
| -------------- | ----------- | ------- |
| `anim_playing` | bool        | `false` |
| `anim_frame`   | int (i32)   | `0`     |
| `anim_timer`   | float (f64) | `0.0`   |

On first launch (before any click) the coin shows frame 0 statically. After a
spin completes it rests on the **last** frame until the next click resets it to
frame 0 — which is why point 3 says "returns to the starting frame."

### Texture lifetime

Load the texture **inside `run`** (the window already exists — `main` creates it
before calling `run`, and is therefore **unchanged in every language**). Languages
with RAII textures (Rust, Nim/naylib) unload automatically when `run` returns;
the others (C++, Crystal, Odin) unload explicitly at the end of `run`.

### Loop order of operations

Keep today's order and slot the animation advance in as a third time-based
update, between passive accumulation and input:

1. `dt = frame time`
2. **passive accumulation** (unchanged)
3. **animation advance** (new — see pseudocode)
4. **input / click** (the CLICK_BUTTON branch changes; upgrades unchanged)
5. **draw** (add the coin between the green button fill/border and the label)

### Animation-advance pseudocode (step 3)

```
if anim_playing:
    anim_timer += dt
    while anim_timer >= COIN_FRAME_TIME:
        anim_timer -= COIN_FRAME_TIME
        anim_frame += 1
        if anim_frame >= COIN_FRAMES:
            anim_frame   = COIN_FRAMES - 1   # rest on last frame
            anim_playing = false
            currency    += click_power       # << reward banks here
            break                            # don't advance/award twice
```

The `break` matters: at low frame rates a single `dt` could cross several frame
boundaries, and we must award exactly once.

### Click handling (step 4) — CLICK_BUTTON branch

Replace the old `currency += click_power` with a start/restart:

```
anim_playing = true
anim_frame   = 0
anim_timer   = 0.0
```

The `CLICK_UPGRADE` and `PASSIVE_UPGRADE` branches are untouched. `click_power`
is read at completion time (step 3), so an upgrade purchased mid-spin applies to
that spin's payout — acceptable and not worth special-casing.

### Draw (step 5)

Inside the existing CLICK_BUTTON drawing, after the green fill +
`DrawRectangleLinesEx` border and **before** the text label, draw the current
frame with `DrawTexturePro`:

```
source = { x: anim_frame * COIN_FRAME_W, y: 0, w: COIN_FRAME_W, h: COIN_FRAME_H }
dest   = COIN_DEST
origin = { 0, 0 }
DrawTexturePro(coin, source, dest, origin, 0.0, WHITE)
```

Then move the existing two-line label block (`"CLICK"` + `"(+n)"`) **below** the
coin so it no longer overlaps: change its top-Y from the old vertical-center
formula to a fixed `388` (the coin occupies y 232–382; the label block at
FONT_TITLE+FONT_LARGE = 64 px tall then runs 388–452, inside the button's
220–460 range). Keep the existing fonts and centering helper; only the Y origin
moves.

## Per-language plans

- [cpp.md](./cpp.md) — `Texture2D` + explicit `UnloadTexture`, header-only `game::run`
- [crystal.md](./crystal.md) — **adds FFI bindings** to `raylib_lib.cr` (the gotcha)
- [nim.md](./nim.md) — naylib auto-unload; confirm the `drawTexture`/`drawTexturePro` overload
- [odin.md](./odin.md) — `rl.LoadTexture` + `defer rl.UnloadTexture`
- [rust.md](./rust.md) — `rl.load_texture(thread, …)`, RAII drop, `draw_texture_pro`

## Acceptance (same for every language)

- The shared `incremental-examples/assets/coin_sheet.png` exists (1024 × 128).
- `scripts/build_and_run.sh` builds clean and launches the 800 × 600
  "Idle Clicker" window.
- Clicking the green button plays a one-shot coin spin; **currency does not
  change until the spin's last frame**, then increases by `click_power`.
- The spin does **not** loop — it rests on the final frame.
- Clicking again restarts the spin from frame 0 (and, per the behavioral note
  above, forfeits any not-yet-completed reward).
- Upgrade buttons and passive income behave exactly as before.
- `COIN_FRAMES`, `COIN_FRAME_*`, `COIN_FRAME_TIME`, `COIN_DEST`, and the state
  variable names/initials match the tables above in every language.
