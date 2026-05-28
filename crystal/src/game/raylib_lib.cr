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

  MOUSE_BUTTON_LEFT = 0
end

RAYWHITE  = LibRaylib::Color.new(r: 245_u8, g: 245_u8, b: 245_u8, a: 255_u8)
BLACK     = LibRaylib::Color.new(r:   0_u8, g:   0_u8, b:   0_u8, a: 255_u8)
DARKGRAY  = LibRaylib::Color.new(r:  80_u8, g:  80_u8, b:  80_u8, a: 255_u8)
LIGHTGRAY = LibRaylib::Color.new(r: 200_u8, g: 200_u8, b: 200_u8, a: 255_u8)
GREEN     = LibRaylib::Color.new(r:   0_u8, g: 228_u8, b:  48_u8, a: 255_u8)
DARKGREEN = LibRaylib::Color.new(r:   0_u8, g: 117_u8, b:  44_u8, a: 255_u8)
SKYBLUE   = LibRaylib::Color.new(r: 102_u8, g: 191_u8, b: 255_u8, a: 255_u8)
RED       = LibRaylib::Color.new(r: 230_u8, g:  41_u8, b:  55_u8, a: 255_u8)
