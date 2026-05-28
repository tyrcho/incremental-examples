require "./raylib_lib"
require "./ui_helpers"

module Game
  WINDOW_W = 800
  WINDOW_H = 600

  TITLE_Y    =  30
  CURRENCY_Y =  90
  PASSIVE_Y  = 140

  CLICK_BUTTON    = LibRaylib::Rectangle.new(x:  80.0_f32, y: 220.0_f32, width: 240.0_f32, height: 240.0_f32)
  CLICK_UPGRADE   = LibRaylib::Rectangle.new(x: 400.0_f32, y: 220.0_f32, width: 320.0_f32, height: 110.0_f32)
  PASSIVE_UPGRADE = LibRaylib::Rectangle.new(x: 400.0_f32, y: 350.0_f32, width: 320.0_f32, height: 110.0_f32)

  def self.next_cost(c : Int32) : Int32
    (c * 3) // 2
  end

  def self.run
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
  end
end
