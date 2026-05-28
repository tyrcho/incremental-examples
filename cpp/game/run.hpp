#pragma once

#include <raylib.h>
#include <cstdint>
#include <cstdio>

#include "ui_helpers.hpp"

namespace game {

inline constexpr int WINDOW_W = 800;
inline constexpr int WINDOW_H = 600;

inline constexpr int TITLE_Y    = 30;
inline constexpr int CURRENCY_Y = 90;
inline constexpr int PASSIVE_Y  = 140;

inline constexpr Rectangle CLICK_BUTTON    = { 80.0f,  220.0f, 240.0f, 240.0f };
inline constexpr Rectangle CLICK_UPGRADE   = { 400.0f, 220.0f, 320.0f, 110.0f };
inline constexpr Rectangle PASSIVE_UPGRADE = { 400.0f, 350.0f, 320.0f, 110.0f };

inline constexpr int   COIN_FRAMES     = 8;
inline constexpr float COIN_FRAME_W    = 128.0f;
inline constexpr float COIN_FRAME_H    = 128.0f;
inline constexpr double COIN_FRAME_TIME = 0.06;
inline constexpr const char* COIN_SHEET_PATH = "../assets/coin_sheet.png";

inline constexpr Rectangle COIN_DEST = { 125.0f, 232.0f, 150.0f, 150.0f };

inline int32_t next_cost(int32_t c) { return (c * 3) / 2; }

inline void run() {
    int64_t currency     = 0;
    int32_t click_power  = 1;
    int32_t passive_rate = 0;
    int32_t click_cost   = 10;
    int32_t passive_cost = 25;
    double  accumulator  = 0.0;

    Texture2D coin = LoadTexture(COIN_SHEET_PATH);
    bool   anim_playing = false;
    int    anim_frame   = 0;
    double anim_timer   = 0.0;

    while (!WindowShouldClose()) {
        float dt = GetFrameTime();

        accumulator += (double)dt * (double)passive_rate;
        while (accumulator >= 1.0) { currency += 1; accumulator -= 1.0; }

        if (anim_playing) {
            anim_timer += (double)dt;
            while (anim_timer >= COIN_FRAME_TIME) {
                anim_timer -= COIN_FRAME_TIME;
                anim_frame += 1;
                if (anim_frame >= COIN_FRAMES) {
                    anim_frame   = COIN_FRAMES - 1;
                    anim_playing = false;
                    currency    += click_power;
                    break;
                }
            }
        }

        Vector2 mouse = GetMousePosition();
        if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) {
            if (CheckCollisionPointRec(mouse, CLICK_BUTTON)) {
                anim_playing = true;
                anim_frame   = 0;
                anim_timer   = 0.0;
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

        Rectangle coin_src = { anim_frame * COIN_FRAME_W, 0.0f, COIN_FRAME_W, COIN_FRAME_H };
        DrawTexturePro(coin, coin_src, COIN_DEST, Vector2{ 0.0f, 0.0f }, 0.0f, WHITE);

        int top_y = 388;
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
    UnloadTexture(coin);
}

} // namespace game
