import game.*
import scala.scalanative.unsafe.*

object Main:

    def main(args: Array[String]): Unit =
        Zone {
            Raylib.InitWindow(WINDOW_W, WINDOW_H, c"Idle Clicker")
            Raylib.SetTargetFPS(60)
            val coin = alloc[Texture2D]()
            Raylib.SN_LoadTexture(c"../assets/coin_sheet.png", coin)
            try gameLoop(coin)
            finally
                Raylib.SN_UnloadTexture(coin)
                Raylib.CloseWindow()
        }
