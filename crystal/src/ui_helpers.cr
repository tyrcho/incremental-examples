FONT_TITLE  = 36
FONT_LARGE  = 28
FONT_MEDIUM = 20
FONT_SMALL  = 18

def draw_centered_text(text : String, container_x : Int32, container_w : Int32,
                       y : Int32, font : Int32, color : LibRaylib::Color)
  tw = LibRaylib.measure_text(text, font)
  LibRaylib.draw_text(text, container_x + (container_w - tw) // 2, y, font, color)
end

def draw_upgrade_button(r : LibRaylib::Rectangle, title : String,
                        level_line : String, effect_line : String,
                        cost_line : String, affordable : Bool)
  fill = affordable ? SKYBLUE : LIGHTGRAY
  LibRaylib.draw_rectangle(r.x.to_i, r.y.to_i, r.width.to_i, r.height.to_i, fill)
  LibRaylib.draw_rectangle_lines_ex(r, 2.0_f32, DARKGRAY)

  x = r.x.to_i + 12
  y = r.y.to_i + 4
  LibRaylib.draw_text(title,       x, y, FONT_MEDIUM, BLACK); y += FONT_MEDIUM + 4
  LibRaylib.draw_text(level_line,  x, y, FONT_SMALL,  DARKGRAY); y += FONT_SMALL + 4
  LibRaylib.draw_text(effect_line, x, y, FONT_SMALL,  DARKGRAY); y += FONT_SMALL + 4
  LibRaylib.draw_text(cost_line,   x, y, FONT_SMALL,  affordable ? BLACK : RED)
end
