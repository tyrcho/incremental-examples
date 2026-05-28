import raylib
from ./game/run as game import run, WINDOW_W, WINDOW_H

proc main() =
  initWindow(game.WINDOW_W, game.WINDOW_H, "Idle Clicker")
  setTargetFps(60)
  game.run()
  closeWindow()

when isMainModule:
  main()
