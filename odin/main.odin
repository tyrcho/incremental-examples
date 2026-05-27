package main

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(WINDOW_W, WINDOW_H, "Idle Clicker")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	run_game_loop()
}
