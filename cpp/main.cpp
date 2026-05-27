#include <raylib.h>
#include <cstdint>
#include <cstdio>

static constexpr int WINDOW_W = 800;
static constexpr int WINDOW_H = 600;

static constexpr int TITLE_Y    = 30;
static constexpr int CURRENCY_Y = 90;
static constexpr int PASSIVE_Y  = 140;

static constexpr int FONT_TITLE  = 36;
static constexpr int FONT_LARGE  = 28;
static constexpr int FONT_MEDIUM = 20;
static constexpr int FONT_SMALL  = 18;

static const Rectangle CLICK_BUTTON    = { 80.0f,  220.0f, 240.0f, 240.0f };
static const Rectangle CLICK_UPGRADE   = { 400.0f, 220.0f, 320.0f, 110.0f };
static const Rectangle PASSIVE_UPGRADE = { 400.0f, 350.0f, 320.0f, 110.0f };

static int32_t next_cost(int32_t c) { return (c * 3) / 2; }

static void draw_centered_text(const char* text, int container_x, int container_w,
                               int y, int font, Color color) {
    int tw = MeasureText(text, font);
    DrawText(text, container_x + (container_w - tw) / 2, y, font, color);
}

static void draw_upgrade_button(Rectangle r, const char* title,
                                const char* level_line, const char* effect_line,
                                const char* cost_line, bool affordable) {
    Color fill = affordable ? SKYBLUE : LIGHTGRAY;
    DrawRectangle((int)r.x, (int)r.y, (int)r.width, (int)r.height, fill);
    DrawRectangleLinesEx(r, 2.0f, DARKGRAY);

    int x = (int)r.x + 12;
    int y = (int)r.y + 4;
    DrawText(title,       x, y, FONT_MEDIUM, BLACK);          y += FONT_MEDIUM + 4;
    DrawText(level_line,  x, y, FONT_SMALL,  DARKGRAY);       y += FONT_SMALL  + 4;
    DrawText(effect_line, x, y, FONT_SMALL,  DARKGRAY);       y += FONT_SMALL  + 4;
    DrawText(cost_line,   x, y, FONT_SMALL,  affordable ? BLACK : RED);
}

int main() {
    InitWindow(WINDOW_W, WINDOW_H, "Idle Clicker");
    SetTargetFPS(60);

    int64_t currency     = 0;
    int32_t click_power  = 1;
    int32_t passive_rate = 0;
    int32_t click_cost   = 10;
    int32_t passive_cost = 25;
    double  accumulator  = 0.0;

    while (!WindowShouldClose()) {
        float dt = GetFrameTime();

        accumulator += (double)dt * (double)passive_rate;
        while (accumulator >= 1.0) { currency += 1; accumulator -= 1.0; }

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

        BeginDrawing();
        ClearBackground(RAYWHITE);

        draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY);

        char buf[64];
        std::snprintf(buf, sizeof buf, "Currency: %lld", (long long)currency);
        draw_centered_text(buf, 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK);

        std::snprintf(buf, sizeof buf, "+%d/sec", passive_rate);
        draw_centered_text(buf, 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DARKGREEN);

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

        char lvl[32], cost[32];
        std::snprintf(lvl,  sizeof lvl,  "Level: %d", click_power);
        std::snprintf(cost, sizeof cost, "Cost: %d",  click_cost);
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
