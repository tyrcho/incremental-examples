package main

import rl "vendor:raylib"

FONT_TITLE  :: 36
FONT_LARGE  :: 28
FONT_MEDIUM :: 20
FONT_SMALL  :: 18

draw_centered_text :: proc(text: cstring, container_x, container_w, y, font: i32, color: rl.Color) {
	tw := rl.MeasureText(text, font)
	rl.DrawText(text, container_x + (container_w - tw) / 2, y, font, color)
}

draw_upgrade_button :: proc(
	r: rl.Rectangle,
	title, level_line, effect_line, cost_line: cstring,
	affordable: bool,
) {
	fill := affordable ? rl.SKYBLUE : rl.LIGHTGRAY
	rl.DrawRectangle(i32(r.x), i32(r.y), i32(r.width), i32(r.height), fill)
	rl.DrawRectangleLinesEx(r, 2, rl.DARKGRAY)

	x := i32(r.x) + 12
	y := i32(r.y) + 4
	rl.DrawText(title,       x, y, FONT_MEDIUM, rl.BLACK);    y += FONT_MEDIUM + 4
	rl.DrawText(level_line,  x, y, FONT_SMALL,  rl.DARKGRAY); y += FONT_SMALL  + 4
	rl.DrawText(effect_line, x, y, FONT_SMALL,  rl.DARKGRAY); y += FONT_SMALL  + 4
	cost_color := affordable ? rl.BLACK : rl.RED
	rl.DrawText(cost_line,   x, y, FONT_SMALL,  cost_color)
}
