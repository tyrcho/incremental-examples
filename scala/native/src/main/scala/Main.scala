import game.*
import scala.scalanative.unsafe.*

object Main:
    def main(args: Array[String]): Unit =
        Zone {
            Raylib.InitWindow(Window.x.toInt, Window.y.toInt, c"Idle Clicker")
            Raylib.SetTargetFPS(60)
            val coin = alloc[Texture2D]()
            Raylib.SN_LoadTexture(c"../assets/coin_sheet.png", coin)
            val renderer = RaylibRenderer(coin)
            val input    = RaylibInput()
            try
                var state = GameState()
                while !Raylib.WindowShouldClose() do
                    Zone {
                        val dtSec = Raylib.GetFrameTime()
                        input.poll()
                        state = state.tick(dtSec)
                        for p <- input.takeClick() do
                            state = handleClick(p)(state)
                        renderer.beginFrame()
                        drawScene(state, renderer)
                        renderer.endFrame()
                    }
            finally
                Raylib.SN_UnloadTexture(coin)
                Raylib.CloseWindow()
        }
