use raylib::prelude::*;

mod ui_helpers;
use self::ui_helpers::*;

pub const WINDOW_W: i32 = 800;
pub const WINDOW_H: i32 = 600;

pub const TITLE_Y: i32 = 30;
pub const CURRENCY_Y: i32 = 90;
pub const PASSIVE_Y: i32 = 140;

const CLICK_COST_INIT: i32 = 10;
const PASSIVE_COST_INIT: i32 = 25;

pub const CLICK_BUTTON: Rectangle = Rectangle {
    x: 80.0,
    y: 220.0,
    width: 240.0,
    height: 240.0,
};
pub const CLICK_UPGRADE: Rectangle = Rectangle {
    x: 400.0,
    y: 220.0,
    width: 320.0,
    height: 110.0,
};
pub const PASSIVE_UPGRADE: Rectangle = Rectangle {
    x: 400.0,
    y: 350.0,
    width: 320.0,
    height: 110.0,
};

fn next_cost(c: i32) -> i32 {
    c * 3 / 2
}

pub fn run(rl: &mut RaylibHandle, thread: &RaylibThread) {
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

        let mut d = rl.begin_drawing(thread);
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
