require "lib_c"
require "./game/raylib_lib"
require "./game/run"

LibRaylib.init_window(Game::WINDOW_W, Game::WINDOW_H, "Idle Clicker")
LibRaylib.set_target_fps(60)
Game.run
LibRaylib.close_window
