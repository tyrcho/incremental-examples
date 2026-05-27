# 02 — Implementation Walkthrough

Target: a single `main.cpp`, ~120–180 lines, C++17, raylib C API only. Spec section references in parentheses.

## File outline

```
#include <raylib.h>
#include <cstdint>
#include <cstdio>     // snprintf for the dynamic strings

// 1. Constants (spec §4)
// 2. Helpers: next_cost, draw_centered_text, draw_upgrade_button
// 3. main: init, loop, close
```

No `using namespace`. Free functions only — no classes, no namespaces of our own.

## Constants block (spec §4)

`static constexpr` integers at file scope. Rectangles as `Rectangle` literals (raylib's `Rectangle` is `{float x, y, width, height}`).

```cpp
static constexpr int WINDOW_W = 800;
static constexpr int WINDOW_H = 600;

static constexpr int TITLE_Y    = 30;
static constexpr int CURRENCY_Y = 90;
static constexpr int PASSIVE_Y  = 140;

static constexpr int FONT_TITLE  = 36;
static constexpr int FONT_LARGE  = 28;
static constexpr int FONT_MEDIUM = 20;
static constexpr int FONT_SMALL  = 18;

static const Rectangle CLICK_BUTTON     = { 80,  220, 240, 240 };
static const Rectangle CLICK_UPGRADE    = { 400, 220, 320, 110 };
static const Rectangle PASSIVE_UPGRADE  = { 400, 350, 320, 110 };
```

`Rectangle` cannot be `constexpr` against the raylib struct in C++, so `static const` is fine. Use `int` for the geometry constants and convert at call sites where raylib wants `float`.

## State (spec §3)

Six locals at the top of `main`. No struct — the spec explicitly permits "just six locals in main".

```cpp
int64_t currency     = 0;
int32_t click_power  = 1;
int32_t passive_rate = 0;
int32_t click_cost   = 10;
int32_t passive_cost = 25;
double  accumulator  = 0.0;
```

## Helpers

### Cost scaling (spec §5)

```cpp
static int32_t next_cost(int32_t c) { return (c * 3) / 2; }
```

Integer division, truncating — matches the spec sequences (10→15→22→33→49…, 25→37→55→82…).

### Centered text

The spec says: use `MeasureText(text, fontSize)`, then `x = (container_w - text_w) / 2 + container_x`. Two helpers cover every use:

```cpp
static void draw_centered_text(const char* text, int container_x, int container_w,
                                int y, int font, Color color) {
    int tw = MeasureText(text, font);
    DrawText(text, container_x + (container_w - tw) / 2, y, font, color);
}
```

For the click button's two stacked centered lines (spec §7.5), compute the combined block height and the per-line y so the pair is vertically centered in `CLICK_BUTTON`:

- Total block height = `FONT_TITLE + FONT_LARGE` (no inter-line padding called out in spec; if a small gap reads better, mention it but do not deviate — the spec says "stack the two lines vertically centered in the rect").
- Top y = `rect.y + (rect.height - block_h) / 2`.
- Line 1 y = top y; line 2 y = top y + `FONT_TITLE`.

### Upgrade button (spec §7.6 / §7.7, and §9.4 "required if it would otherwise duplicate ~10 lines")

The two upgrade buttons share layout — factor them to avoid duplication.

```cpp
static void draw_upgrade_button(Rectangle r, const char* title,
                                 const char* level_line, const char* effect_line,
                                 const char* cost_line, bool affordable) {
    Color fill = affordable ? SKYBLUE : LIGHTGRAY;
    DrawRectangle((int)r.x, (int)r.y, (int)r.width, (int)r.height, fill);
    DrawRectangleLinesEx(r, 2.0f, DARKGRAY);

    int x = (int)r.x + 12;
    int y = (int)r.y + 4;                  // 4px top padding
    DrawText(title,       x, y, FONT_MEDIUM, BLACK);          y += FONT_MEDIUM + 4;
    DrawText(level_line,  x, y, FONT_SMALL,  DARKGRAY);       y += FONT_SMALL  + 4;
    DrawText(effect_line, x, y, FONT_SMALL,  DARKGRAY);       y += FONT_SMALL  + 4;
    DrawText(cost_line,   x, y, FONT_SMALL,  affordable ? BLACK : RED);
}
```

Build the four label strings in `main` with `snprintf` against small stack buffers (`char buf[64]`) and pass them in. Two upgrade-button call sites, no duplication.

## `main` walkthrough

Order matches spec §6 exactly.

```cpp
int main() {
    InitWindow(WINDOW_W, WINDOW_H, "Idle Clicker");
    SetTargetFPS(60);

    // ... six state locals declared here ...

    while (!WindowShouldClose()) {
        float dt = GetFrameTime();

        // §6.2 passive income tick
        accumulator += (double)dt * (double)passive_rate;
        while (accumulator >= 1.0) { currency += 1; accumulator -= 1.0; }

        // §6.3 input
        Vector2 mouse = GetMousePosition();
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            if (CheckCollisionPointRec(mouse, CLICK_BUTTON)) {
                currency += click_power;
            } else if (CheckCollisionPointRec(mouse, CLICK_UPGRADE) && currency >= click_cost) {
                currency    -= click_cost;
                click_power += 1;
                click_cost   = next_cost(click_cost);
            } else if (CheckCollisionPointRec(mouse, PASSIVE_UPGRADE) && currency >= passive_cost) {
                currency     -= passive_cost;
                passive_rate += 1;
                passive_cost  = next_cost(passive_cost);
            }
        }

        // §6.4 draw
        BeginDrawing();
        ClearBackground(RAYWHITE);

        draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY);

        char buf[64];
        std::snprintf(buf, sizeof buf, "Currency: %lld", (long long)currency);
        draw_centered_text(buf, 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK);

        std::snprintf(buf, sizeof buf, "+%d/sec", passive_rate);
        draw_centered_text(buf, 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DARKGREEN);

        // click button (§7.5)
        DrawRectangle((int)CLICK_BUTTON.x, (int)CLICK_BUTTON.y,
                      (int)CLICK_BUTTON.width, (int)CLICK_BUTTON.height, GREEN);
        DrawRectangleLinesEx(CLICK_BUTTON, 3.0f, DARKGREEN);

        int block_h = FONT_TITLE + FONT_LARGE;
        int top_y   = (int)CLICK_BUTTON.y + ((int)CLICK_BUTTON.height - block_h) / 2;
        draw_centered_text("CLICK", (int)CLICK_BUTTON.x, (int)CLICK_BUTTON.width,
                           top_y, FONT_TITLE, BLACK);

        char line2[32];
        std::snprintf(line2, sizeof line2, "(+%d)", click_power);
        draw_centered_text(line2, (int)CLICK_BUTTON.x, (int)CLICK_BUTTON.width,
                           top_y + FONT_TITLE, FONT_LARGE, BLACK);

        // upgrade buttons (§7.6, §7.7)
        char lvl[32], cost[32];
        std::snprintf(lvl,  sizeof lvl,  "Level: %d",  click_power);
        std::snprintf(cost, sizeof cost, "Cost: %d",   click_cost);
        draw_upgrade_button(CLICK_UPGRADE, "Click Power", lvl, "+1 per click",
                            cost, currency >= click_cost);

        std::snprintf(lvl,  sizeof lvl,  "Level: %d", passive_rate);
        std::snprintf(cost, sizeof cost, "Cost: %d",  passive_cost);
        draw_upgrade_button(PASSIVE_UPGRADE, "Passive Income", lvl, "+1 per second",
                            cost, currency >= passive_cost);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
```

## Subtleties to get right

- **Order of operations** — spec §6 mandates passive tick before input within the same frame. Don't fold them.
- **Accumulator semantics** — `passive_rate = 0` must produce zero ticks regardless of `dt`. The multiply by zero in the accumulator update handles this; no special case needed.
- **Integer cost formula** — do not promote to `double` "for safety". Spec §5 explicitly forbids it; the truncating sequence is part of the contract.
- **`int64_t` printf** — use `%lld` with `(long long)` cast. Avoid `<inttypes.h>` macros; `snprintf` keeps it portable enough.
- **`Rectangle` casts** — raylib's `Rectangle` fields are `float`. `DrawRectangle` takes `int`. Cast at the call site; do not store both.
- **Only the API in spec §8** — resist the urge to use `DrawRectangleRec`, `Fade`, `DrawTextEx`, etc. They are not on the allowed list.
- **No assets** — `DrawText` uses the default font baked into raylib. Do not `LoadFont`.
- **`MOUSE_BUTTON_LEFT`** — modern raylib name. If the installed raylib is old enough to only have `MOUSE_LEFT_BUTTON`, fall back to that; spec §8 allows the older name.
- **Click hits one thing per frame** — the `else if` chain in §6.3 is required; do not let a single click both spend currency and earn it.

## Line count target

State + constants + two helpers + `main` body ≈ 150 lines including blank lines. If the file exceeds ~200 lines, look for accidental duplication (most likely: the upgrade-button block was not factored).
