import raylib
import ./game_loop

proc main() =
  initWindow(WINDOW_W, WINDOW_H, "Idle Clicker")
  setTargetFps(60)
  runGameLoop()
  closeWindow()

when isMainModule:
  main()
