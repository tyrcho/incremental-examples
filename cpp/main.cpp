#include "game_loop.hpp"

int main() {
    InitWindow(WINDOW_W, WINDOW_H, "Idle Clicker");
    SetTargetFPS(60);
    run_game_loop();
    CloseWindow();
    return 0;
}
