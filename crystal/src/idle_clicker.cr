require "lib_c"

@[Link("raylib")]
lib LibRaylib
  struct Color
    r, g, b, a : UInt8
  end

  struct Vector2
    x, y : Float32
  end

  struct Rectangle
    x, y, width, height : Float32
  end

  fun init_window         = InitWindow(width : Int32, height : Int32, title : LibC::Char*)
  fun close_window        = CloseWindow
  fun window_should_close = WindowShouldClose : Bool
  fun set_target_fps      = SetTargetFPS(fps : Int32)

  fun begin_drawing       = BeginDrawing
  fun end_drawing         = EndDrawing
  fun clear_background    = ClearBackground(color : Color)

  fun draw_rectangle          = DrawRectangle(x : Int32, y : Int32, w : Int32, h : Int32, color : Color)
  fun draw_rectangle_lines_ex = DrawRectangleLinesEx(rec : Rectangle, line_thick : Float32, color : Color)
  fun draw_text               = DrawText(text : LibC::Char*, x : Int32, y : Int32, font_size : Int32, color : Color)
  fun measure_text            = MeasureText(text : LibC::Char*, font_size : Int32) : Int32

  fun get_mouse_position      = GetMousePosition : Vector2
  fun is_mouse_button_pressed = IsMouseButtonPressed(button : Int32) : Bool
  fun get_frame_time          = GetFrameTime : Float32

  fun check_collision_point_rec = CheckCollisionPointRec(point : Vector2, rec : Rectangle) : Bool
end

MOUSE_BUTTON_LEFT = 0

RAYWHITE  = LibRaylib::Color.new(r: 245_u8, g: 245_u8, b: 245_u8, a: 255_u8)
BLACK     = LibRaylib::Color.new(r:   0_u8, g:   0_u8, b:   0_u8, a: 255_u8)
DARKGRAY  = LibRaylib::Color.new(r:  80_u8, g:  80_u8, b:  80_u8, a: 255_u8)
LIGHTGRAY = LibRaylib::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8)
GREEN     = LibRaylib::Color.new(r:   0_u8, g: 228_u8, b:  48_u8, a: 255_u8)
DARKGREEN = LibRaylib::Color.new(r:   0_u8, g: 117_u8, b:  44_u8, a: 255_u8)
SKYBLUE   = LibRaylib::Color.new(r: 102_u8, g: 191_u8, b: 255_u8, a: 255_u8)
RED       = LibRaylib::Color.new(r: 230_u8, g:  41_u8, b:  55_u8, a: 255_u8)

WINDOW_W = 800
WINDOW_H = 600

TITLE_Y    =  30
CURRENCY_Y =  90
PASSIVE_Y  = 140

FONT_TITLE  = 36
FONT_LARGE  = 28
FONT_MEDIUM = 20
FONT_SMALL  = 18

CLICK_BUTTON    = LibRaylib::Rectangle.new(x:  80.0_f32, y: 220.0_f32, width: 240.0_f32, height: 240.0_f32)
CLICK_UPGRADE   = LibRaylib::Rectangle.new(x: 400.0_f32, y: 220.0_f32, width: 320.0_f32, height: 110.0_f32)
PASSIVE_UPGRADE = LibRaylib::Rectangle.new(x: 400.0_f32, y: 350.0_f32, width: 320.0_f32, height: 110.0_f32)

def next_cost(c : Int32) : Int32
  (c * 3) // 2
end

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

# --- main ---

LibRaylib.init_window(WINDOW_W, WINDOW_H, "Idle Clicker")
LibRaylib.set_target_fps(60)

currency     = 0_i64
click_power  = 1
passive_rate = 0
click_cost   = 10
passive_cost = 25
accumulator  = 0.0

until LibRaylib.window_should_close
  dt = LibRaylib.get_frame_time

  accumulator += dt.to_f64 * passive_rate.to_f64
  while accumulator >= 1.0
    currency += 1
    accumulator -= 1.0
  end

  mouse = LibRaylib.get_mouse_position
  if LibRaylib.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    if LibRaylib.check_collision_point_rec(mouse, CLICK_BUTTON)
      currency += click_power
    elsif LibRaylib.check_collision_point_rec(mouse, CLICK_UPGRADE) && currency >= click_cost
      currency    -= click_cost
      click_power += 1
      click_cost   = next_cost(click_cost)
    elsif LibRaylib.check_collision_point_rec(mouse, PASSIVE_UPGRADE) && currency >= passive_cost
      currency     -= passive_cost
      passive_rate += 1
      passive_cost  = next_cost(passive_cost)
    end
  end

  LibRaylib.begin_drawing
  LibRaylib.clear_background(RAYWHITE)

  draw_centered_text("Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY)
  draw_centered_text("Currency: #{currency}", 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK)
  draw_centered_text("+#{passive_rate}/sec", 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DARKGREEN)

  LibRaylib.draw_rectangle(CLICK_BUTTON.x.to_i, CLICK_BUTTON.y.to_i,
                           CLICK_BUTTON.width.to_i, CLICK_BUTTON.height.to_i, GREEN)
  LibRaylib.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0_f32, DARKGREEN)

  block_h = FONT_TITLE + FONT_LARGE
  top_y   = CLICK_BUTTON.y.to_i + (CLICK_BUTTON.height.to_i - block_h) // 2
  cx      = CLICK_BUTTON.x.to_i
  cw      = CLICK_BUTTON.width.to_i
  draw_centered_text("CLICK",             cx, cw, top_y,              FONT_TITLE, BLACK)
  draw_centered_text("(+#{click_power})", cx, cw, top_y + FONT_TITLE, FONT_LARGE, BLACK)

  draw_upgrade_button(CLICK_UPGRADE, "Click Power",
                      "Level: #{click_power}", "+1 per click", "Cost: #{click_cost}",
                      currency >= click_cost)
  draw_upgrade_button(PASSIVE_UPGRADE, "Passive Income",
                      "Level: #{passive_rate}", "+1 per second", "Cost: #{passive_cost}",
                      currency >= passive_cost)

  LibRaylib.end_drawing
end

LibRaylib.close_window
