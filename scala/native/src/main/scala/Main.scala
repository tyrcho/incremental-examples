import game.*
import scala.scalanative.unsafe.*

object Main:
    def main(args: Array[String]): Unit =
        Zone {  // outer zone owns texture lifetime
            Raylib.InitWindow(Window.x, Window.y, c"Idle Clicker")
            Raylib.SetTargetFPS(60)
            val coin = alloc[Texture2D]()
            Raylib.SN_LoadTexture(c"../assets/coin_sheet.png", coin)
            val renderer = RaylibRenderer(coin)
            val input    = RaylibInput()
            try
                var state = GameState()

                def runFrame(): Unit =
                    val dtSec = Raylib.GetFrameTime()
                    input.poll()
                    state = state.tick(dtSec)
                    for p <- input.takeClick() do state = handleClick(p)(state)
                    renderer.beginFrame()
                    drawScene(state, renderer)
                    renderer.endFrame()

                while !Raylib.WindowShouldClose() do runFrame()
            finally
                Raylib.SN_UnloadTexture(coin)
                Raylib.CloseWindow()
        }
