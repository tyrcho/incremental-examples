#include "game/run.hpp"

int main() {
    InitWindow(game::WINDOW_W, game::WINDOW_H, "Idle Clicker");
    SetTargetFPS(60);
    game::run();
    CloseWindow();
    return 0;
}
