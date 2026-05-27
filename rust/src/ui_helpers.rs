use raylib::prelude::*;

pub const FONT_TITLE: i32 = 36;
pub const FONT_LARGE: i32 = 28;
pub const FONT_MEDIUM: i32 = 20;
pub const FONT_SMALL: i32 = 18;

pub fn draw_centered_text(
    d: &mut RaylibDrawHandle,
    text: &str,
    container_x: i32,
    container_w: i32,
    y: i32,
    size: i32,
    color: Color,
) {
    let w = d.measure_text(text, size);
    let x = container_x + (container_w - w) / 2;
    d.draw_text(text, x, y, size, color);
}

pub fn draw_upgrade_button(
    d: &mut RaylibDrawHandle,
    rect: Rectangle,
    title: &str,
    level_line: &str,
    effect_line: &str,
    cost_line: &str,
    affordable: bool,
) {
    let fill = if affordable {
        Color::SKYBLUE
    } else {
        Color::LIGHTGRAY
    };
    d.draw_rectangle(
        rect.x as i32,
        rect.y as i32,
        rect.width as i32,
        rect.height as i32,
        fill,
    );
    d.draw_rectangle_lines_ex(rect, 2.0, Color::DARKGRAY);

    let x_text = rect.x as i32 + 12;
    let mut y = rect.y as i32 + 4;

    d.draw_text(title, x_text, y, FONT_MEDIUM, Color::BLACK);
    y += FONT_MEDIUM + 4;
    d.draw_text(level_line, x_text, y, FONT_SMALL, Color::DARKGRAY);
    y += FONT_SMALL + 4;
    d.draw_text(effect_line, x_text, y, FONT_SMALL, Color::DARKGRAY);
    y += FONT_SMALL + 4;
    let cost_color = if affordable { Color::BLACK } else { Color::RED };
    d.draw_text(cost_line, x_text, y, FONT_SMALL, cost_color);
}
