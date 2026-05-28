mod game;

fn main() {
    let (mut rl, thread) = raylib::init()
        .size(game::WINDOW_W, game::WINDOW_H)
        .title("Idle Clicker")
        .build();
    rl.set_target_fps(60);
    game::run(&mut rl, &thread);
}
