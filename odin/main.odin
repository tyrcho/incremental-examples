package main

import rl "vendor:raylib"
import "game"

main :: proc() {
	rl.InitWindow(game.WINDOW_W, game.WINDOW_H, "Idle Clicker")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	game.run()
}
