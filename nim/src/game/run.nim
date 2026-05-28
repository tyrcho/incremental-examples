import raylib
import std/strformat
import ./ui_helpers

const
  WINDOW_W*: int32 = 800
  WINDOW_H*: int32 = 600

  TITLE_Y:    int32 = 30
  CURRENCY_Y: int32 = 90
  PASSIVE_Y:  int32 = 140

  CLICK_COST_INIT:   int32 = 10
  PASSIVE_COST_INIT: int32 = 25

  CLICK_BUTTON    = Rectangle(x: 80,  y: 220, width: 240, height: 240)
  CLICK_UPGRADE   = Rectangle(x: 400, y: 220, width: 320, height: 110)
  PASSIVE_UPGRADE = Rectangle(x: 400, y: 350, width: 320, height: 110)

  COIN_FRAMES:     int32   = 8
  COIN_FRAME_W:    float32 = 128.0
  COIN_FRAME_H:    float32 = 128.0
  COIN_FRAME_TIME: float64 = 0.06
  COIN_SHEET_PATH          = "../assets/coin_sheet.png"

  COIN_DEST = Rectangle(x: 125, y: 232, width: 150, height: 150)

proc nextCost(c: int32): int32 =
  (c * 3) div 2

proc run*() =
  var
    currency:    int64   = 0
    clickPower:  int32   = 1
    passiveRate: int32   = 0
    clickCost:   int32   = CLICK_COST_INIT
    passiveCost: int32   = PASSIVE_COST_INIT
    accumulator: float64 = 0.0

  let coin = loadTexture(COIN_SHEET_PATH)
  var
    animPlaying = false
    animFrame: int32 = 0
    animTimer: float64 = 0.0

  while not windowShouldClose():
    let dt = getFrameTime()

    accumulator += float64(dt) * float64(passiveRate)
    while accumulator >= 1.0:
      currency += 1
      accumulator -= 1.0

    if animPlaying:
      animTimer += float64(dt)
      while animTimer >= COIN_FRAME_TIME:
        animTimer -= COIN_FRAME_TIME
        animFrame += 1
        if animFrame >= COIN_FRAMES:
          animFrame = COIN_FRAMES - 1
          animPlaying = false
          currency += int64(clickPower)
          break

    let mouse = getMousePosition()
    if isMouseButtonPressed(MouseButton.Left):
      if checkCollisionPointRec(mouse, CLICK_BUTTON):
        animPlaying = true
        animFrame = 0
        animTimer = 0.0
      elif checkCollisionPointRec(mouse, CLICK_UPGRADE) and
           currency >= int64(clickCost):
        currency -= int64(clickCost)
        clickPower += 1
        clickCost = nextCost(clickCost)
      elif checkCollisionPointRec(mouse, PASSIVE_UPGRADE) and
           currency >= int64(passiveCost):
        currency -= int64(passiveCost)
        passiveRate += 1
        passiveCost = nextCost(passiveCost)

    beginDrawing()
    clearBackground(RayWhite)

    drawCenteredText("Idle Clicker",
                     0'i32, WINDOW_W, TITLE_Y, FONT_TITLE, DarkGray)

    drawCenteredText(&"Currency: {currency}",
                     0'i32, WINDOW_W, CURRENCY_Y, FONT_LARGE, Black)

    drawCenteredText(&"+{passiveRate}/sec",
                     0'i32, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DarkGreen)

    drawRectangle(
      int32(CLICK_BUTTON.x), int32(CLICK_BUTTON.y),
      int32(CLICK_BUTTON.width), int32(CLICK_BUTTON.height),
      Green)
    drawRectangleLines(CLICK_BUTTON, 3.0'f32, DarkGreen)
    let coinSrc = Rectangle(
      x: float32(animFrame) * COIN_FRAME_W, y: 0,
      width: COIN_FRAME_W, height: COIN_FRAME_H)
    drawTexture(coin, coinSrc, COIN_DEST, Vector2(x: 0, y: 0), 0.0'f32, White)
    block:
      let topY = 388'i32
      let cx  = int32(CLICK_BUTTON.x)
      let cw  = int32(CLICK_BUTTON.width)
      drawCenteredText("CLICK",            cx, cw, topY,              FONT_TITLE, Black)
      drawCenteredText(&"(+{clickPower})", cx, cw, topY + FONT_TITLE, FONT_LARGE, Black)

    let clickAffordable = currency >= int64(clickCost)
    drawUpgradeButton(
      CLICK_UPGRADE,
      "Click Power",
      &"Level: {clickPower}",
      "+1 per click",
      &"Cost: {clickCost}",
      clickAffordable)

    let passiveAffordable = currency >= int64(passiveCost)
    drawUpgradeButton(
      PASSIVE_UPGRADE,
      "Passive Income",
      &"Level: {passiveRate}",
      "+1 per second",
      &"Cost: {passiveCost}",
      passiveAffordable)

    endDrawing()
