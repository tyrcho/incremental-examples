use raylib::prelude::*;

mod ui_helpers;
use self::ui_helpers::*;

pub const WINDOW_W: i32 = 800;
pub const WINDOW_H: i32 = 600;

const TITLE_Y: i32 = 30;
const CURRENCY_Y: i32 = 90;
const PASSIVE_Y: i32 = 140;

const CLICK_COST_INIT: i32 = 10;
const PASSIVE_COST_INIT: i32 = 25;

const COIN_FRAMES: i32 = 8;
const COIN_FRAME_W: f32 = 128.0;
const COIN_FRAME_H: f32 = 128.0;
const COIN_FRAME_TIME: f64 = 0.06;
const COIN_SHEET_PATH: &str = "../assets/coin_sheet.png";

const COIN_DEST: Rectangle = Rectangle { x: 125.0, y: 232.0, width: 150.0, height: 150.0 };

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

pub fn run(rl: &mut RaylibHandle, thread: &RaylibThread) {
    let mut currency: i64 = 0;
    let mut click_power: i32 = 1;
    let mut passive_rate: i32 = 0;
    let mut click_cost: i32 = CLICK_COST_INIT;
    let mut passive_cost: i32 = PASSIVE_COST_INIT;
    let mut accumulator: f64 = 0.0;
    let coin = rl
        .load_texture(thread, COIN_SHEET_PATH)
        .expect("load coin_sheet.png");
    let mut anim_playing = false;
    let mut anim_frame: i32 = 0;
    let mut anim_timer: f64 = 0.0;

    while !rl.window_should_close() {
        let dt = rl.get_frame_time();

        accumulator += (dt as f64) * (passive_rate as f64);
        while accumulator >= 1.0 {
            currency += 1;
            accumulator -= 1.0;
        }

        if anim_playing {
            anim_timer += dt as f64;
            while anim_timer >= COIN_FRAME_TIME {
                anim_timer -= COIN_FRAME_TIME;
                anim_frame += 1;
                if anim_frame >= COIN_FRAMES {
                    anim_frame = COIN_FRAMES - 1;
                    anim_playing = false;
                    currency += click_power as i64;
                    break;
                }
            }
        }

        let mouse = rl.get_mouse_position();
        if rl.is_mouse_button_pressed(MouseButton::MOUSE_BUTTON_LEFT) {
            if CLICK_BUTTON.check_collision_point_rec(mouse) {
                anim_playing = true;
                anim_frame = 0;
                anim_timer = 0.0;
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
            let source = Rectangle {
                x: anim_frame as f32 * COIN_FRAME_W,
                y: 0.0,
                width: COIN_FRAME_W,
                height: COIN_FRAME_H,
            };
            d.draw_texture_pro(&coin, source, COIN_DEST, Vector2::zero(), 0.0, Color::WHITE);
        }
        {
            let line2 = format!("(+{})", click_power);
            let cy = 388;
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
