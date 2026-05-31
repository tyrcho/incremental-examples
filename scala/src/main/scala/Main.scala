import game.*
import scala.scalanative.unsafe.*

object Main:
  def main(args: Array[String]): Unit =
    Zone {
      Raylib.InitWindow(WINDOW_W, WINDOW_H, c"Idle Clicker")
      Raylib.SetTargetFPS(60)
      run()
      Raylib.CloseWindow()
    }
