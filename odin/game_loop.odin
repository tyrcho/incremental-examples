package main

import rl "vendor:raylib"
import "core:fmt"

WINDOW_W :: 800
WINDOW_H :: 600

TITLE_Y    :: 30
CURRENCY_Y :: 90
PASSIVE_Y  :: 140

CLICK_BUTTON    :: rl.Rectangle{x =  80, y = 220, width = 240, height = 240}
CLICK_UPGRADE   :: rl.Rectangle{x = 400, y = 220, width = 320, height = 110}
PASSIVE_UPGRADE :: rl.Rectangle{x = 400, y = 350, width = 320, height = 110}

next_cost :: proc(c: i32) -> i32 {
	return (c * 3) / 2
}

run_game_loop :: proc() {
	currency:     i64 = 0
	click_power:  i32 = 1
	passive_rate: i32 = 0
	click_cost:   i32 = 10
	passive_cost: i32 = 25
	accumulator:  f64 = 0.0

	for !rl.WindowShouldClose() {
		defer free_all(context.temp_allocator)

		dt := rl.GetFrameTime()

		accumulator += f64(dt) * f64(passive_rate)
		for accumulator >= 1.0 {
			currency += 1
			accumulator -= 1.0
		}

		mouse := rl.GetMousePosition()
		if rl.IsMouseButtonPressed(.LEFT) {
			if rl.CheckCollisionPointRec(mouse, CLICK_BUTTON) {
				currency += i64(click_power)
			} else if rl.CheckCollisionPointRec(mouse, CLICK_UPGRADE) && currency >= i64(click_cost) {
				currency    -= i64(click_cost)
				click_power += 1
				click_cost   = next_cost(click_cost)
			} else if rl.CheckCollisionPointRec(mouse, PASSIVE_UPGRADE) && currency >= i64(passive_cost) {
				currency     -= i64(passive_cost)
				passive_rate += 1
				passive_cost  = next_cost(passive_cost)
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)

		draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, rl.DARKGRAY)
		draw_centered_text(fmt.ctprintf("Currency: %d", currency),
		                   0, WINDOW_W, CURRENCY_Y, FONT_LARGE, rl.BLACK)
		draw_centered_text(fmt.ctprintf("+%d/sec", passive_rate),
		                   0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, rl.DARKGREEN)

		rl.DrawRectangle(i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.y),
		                 i32(CLICK_BUTTON.width), i32(CLICK_BUTTON.height), rl.GREEN)
		rl.DrawRectangleLinesEx(CLICK_BUTTON, 3, rl.DARKGREEN)

		block_h := i32(FONT_TITLE + FONT_LARGE)
		top_y   := i32(CLICK_BUTTON.y) + (i32(CLICK_BUTTON.height) - block_h) / 2
		draw_centered_text("CLICK", i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.width),
		                   top_y, FONT_TITLE, rl.BLACK)
		draw_centered_text(fmt.ctprintf("(+%d)", click_power),
		                   i32(CLICK_BUTTON.x), i32(CLICK_BUTTON.width),
		                   top_y + FONT_TITLE, FONT_LARGE, rl.BLACK)

		draw_upgrade_button(
			CLICK_UPGRADE, "Click Power",
			fmt.ctprintf("Level: %d", click_power),
			"+1 per click",
			fmt.ctprintf("Cost: %d", click_cost),
			currency >= i64(click_cost),
		)
		draw_upgrade_button(
			PASSIVE_UPGRADE, "Passive Income",
			fmt.ctprintf("Level: %d", passive_rate),
			"+1 per second",
			fmt.ctprintf("Cost: %d", passive_cost),
			currency >= i64(passive_cost),
		)

		rl.EndDrawing()
	}
}
