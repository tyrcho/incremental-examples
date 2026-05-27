use raylib::prelude::*;

const WINDOW_W: i32 = 800;
const WINDOW_H: i32 = 600;

const TITLE_Y: i32 = 30;
const CURRENCY_Y: i32 = 90;
const PASSIVE_Y: i32 = 140;

const FONT_TITLE: i32 = 36;
const FONT_LARGE: i32 = 28;
const FONT_MEDIUM: i32 = 20;
const FONT_SMALL: i32 = 18;

const CLICK_COST_INIT: i32 = 10;
const PASSIVE_COST_INIT: i32 = 25;

const CLICK_BUTTON: Rectangle = Rectangle {
    x: 80.0,
    y: 220.0,
    width: 240.0,
    height: 240.0,
};
const CLICK_UPGRADE: Rectangle = Rectangle {
    x: 400.0,
    y: 220.0,
    width: 320.0,
    height: 110.0,
};
const PASSIVE_UPGRADE: Rectangle = Rectangle {
    x: 400.0,
    y: 350.0,
    width: 320.0,
    height: 110.0,
};

fn next_cost(c: i32) -> i32 {
    c * 3 / 2
}

fn draw_centered_text(
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

fn draw_upgrade_button(
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

fn main() {
    let (mut rl, thread) = raylib::init()
        .size(WINDOW_W, WINDOW_H)
        .title("Idle Clicker")
        .build();
    rl.set_target_fps(60);

    let mut currency: i64 = 0;
    let mut click_power: i32 = 1;
    let mut passive_rate: i32 = 0;
    let mut click_cost: i32 = CLICK_COST_INIT;
    let mut passive_cost: i32 = PASSIVE_COST_INIT;
    let mut accumulator: f64 = 0.0;

    while !rl.window_should_close() {
        let dt = rl.get_frame_time();

        accumulator += (dt as f64) * (passive_rate as f64);
        while accumulator >= 1.0 {
            currency += 1;
            accumulator -= 1.0;
        }

        let mouse = rl.get_mouse_position();
        if rl.is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT) {
            if CLICK_BUTTON.check_collision_point_rec(mouse) {
                currency += click_power as i64;
            } else if CLICK_UPGRADE.check_collision_point_rec(mouse)
                && currency >= click_cost as i64
            {
                currency -= click_cost as i64;
                click_power += 1;
                click_cost = next_cost(click_cost);
            } else if PASSIVE_UPGRADE.check_collision_point_rec(mouse)
                && currency >= passive_cost as i64
            {
                currency -= passive_cost as i64;
                passive_rate += 1;
                passive_cost = next_cost(passive_cost);
            }
        }

        let mut d = rl.begin_drawing(&thread);
        d.clear_background(Color::RAYWHITE);

        draw_centered_text(
            &mut d,
            "Idle Clicker",
            0,
            WINDOW_W,
            TITLE_Y,
            FONT_TITLE,
            Color::DARKGRAY,
        );

        let currency_text = format!("Currency: {}", currency);
        draw_centered_text(
            &mut d,
            &currency_text,
            0,
            WINDOW_W,
            CURRENCY_Y,
            FONT_LARGE,
            Color::BLACK,
        );

        let passive_text = format!("+{}/sec", passive_rate);
        draw_centered_text(
            &mut d,
            &passive_text,
            0,
            WINDOW_W,
            PASSIVE_Y,
            FONT_MEDIUM,
            Color::DARKGREEN,
        );

        d.draw_rectangle(
            CLICK_BUTTON.x as i32,
            CLICK_BUTTON.y as i32,
            CLICK_BUTTON.width as i32,
            CLICK_BUTTON.height as i32,
            Color::GREEN,
        );
        d.draw_rectangle_lines_ex(CLICK_BUTTON, 3.0, Color::DARKGREEN);
        {
            let line2 = format!("(+{})", click_power);
            let total_h = FONT_TITLE + FONT_LARGE;
            let cy = CLICK_BUTTON.y as i32 + (CLICK_BUTTON.height as i32 - total_h) / 2;
            let cx = CLICK_BUTTON.x as i32;
            let cw = CLICK_BUTTON.width as i32;
            draw_centered_text(&mut d, "CLICK", cx, cw, cy, FONT_TITLE, Color::BLACK);
            draw_centered_text(
                &mut d,
                &line2,
                cx,
                cw,
                cy + FONT_TITLE,
                FONT_LARGE,
                Color::BLACK,
            );
        }

        let click_affordable = currency >= click_cost as i64;
        let click_lvl = format!("Level: {}", click_power);
        let click_cost_s = format!("Cost: {}", click_cost);
        draw_upgrade_button(
            &mut d,
            CLICK_UPGRADE,
            "Click Power",
            &click_lvl,
            "+1 per click",
            &click_cost_s,
            click_affordable,
        );

        let passive_affordable = currency >= passive_cost as i64;
        let passive_lvl = format!("Level: {}", passive_rate);
        let passive_cost_s = format!("Cost: {}", passive_cost);
        draw_upgrade_button(
            &mut d,
            PASSIVE_UPGRADE,
            "Passive Income",
            &passive_lvl,
            "+1 per second",
            &passive_cost_s,
            passive_affordable,
        );
    }
}
