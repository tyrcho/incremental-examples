#pragma once

#include <raylib.h>

namespace game {

inline constexpr int FONT_TITLE  = 36;
inline constexpr int FONT_LARGE  = 28;
inline constexpr int FONT_MEDIUM = 20;
inline constexpr int FONT_SMALL  = 18;

inline void draw_centered_text(const char* text, int container_x, int container_w,
                               int y, int font, Color color) {
    int tw = MeasureText(text, font);
    DrawText(text, container_x + (container_w - tw) / 2, y, font, color);
}

inline void draw_upgrade_button(Rectangle r, const char* title,
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

} // namespace game
