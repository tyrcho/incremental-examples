mod game_loop;
mod ui_helpers;

use game_loop::{run_game_loop, WINDOW_H, WINDOW_W};

fn main() {
    let (mut rl, thread) = raylib::init()
        .size(WINDOW_W, WINDOW_H)
        .title("Idle Clicker")
        .build();
    rl.set_target_fps(60);
    run_game_loop(&mut rl, &thread);
}
