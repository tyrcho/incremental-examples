import raylib
import std/strformat

const
  WINDOW_W: int32 = 800
  WINDOW_H: int32 = 600

  TITLE_Y:    int32 = 30
  CURRENCY_Y: int32 = 90
  PASSIVE_Y:  int32 = 140

  FONT_TITLE:  int32 = 36
  FONT_LARGE:  int32 = 28
  FONT_MEDIUM: int32 = 20
  FONT_SMALL:  int32 = 18

  CLICK_COST_INIT:   int32 = 10
  PASSIVE_COST_INIT: int32 = 25

  CLICK_BUTTON    = Rectangle(x: 80,  y: 220, width: 240, height: 240)
  CLICK_UPGRADE   = Rectangle(x: 400, y: 220, width: 320, height: 110)
  PASSIVE_UPGRADE = Rectangle(x: 400, y: 350, width: 320, height: 110)

proc nextCost(c: int32): int32 =
  (c * 3) div 2

proc drawCenteredText(text: string;
                      containerX, containerW, y, fontSize: int32;
                      color: Color) =
  let w = measureText(text, fontSize)
  let x = containerX + (containerW - w) div 2
  drawText(text, x, y, fontSize, color)

proc drawUpgradeButton(
    rec: Rectangle;
    title, levelLine, effectLine, costLine: string;
    affordable: bool) =
  let fill = if affordable: SkyBlue else: LightGray
  drawRectangle(
    int32(rec.x), int32(rec.y),
    int32(rec.width), int32(rec.height),
    fill)
  drawRectangleLines(rec, 2.0'f32, DarkGray)

  let x = int32(rec.x) + 12'i32
  var y = int32(rec.y) + 4'i32
  drawText(title,      x, y, FONT_MEDIUM, Black);    y += FONT_MEDIUM + 4
  drawText(levelLine,  x, y, FONT_SMALL,  DarkGray); y += FONT_SMALL  + 4
  drawText(effectLine, x, y, FONT_SMALL,  DarkGray); y += FONT_SMALL  + 4
  let costColor = if affordable: Black else: Red
  drawText(costLine,   x, y, FONT_SMALL,  costColor)

proc main() =
  initWindow(WINDOW_W, WINDOW_H, "Idle Clicker")
  setTargetFps(60)

  var
    currency:    int64   = 0
    clickPower:  int32   = 1
    passiveRate: int32   = 0
    clickCost:   int32   = CLICK_COST_INIT
    passiveCost: int32   = PASSIVE_COST_INIT
    accumulator: float64 = 0.0

  while not windowShouldClose():
    let dt = getFrameTime()

    accumulator += float64(dt) * float64(passiveRate)
    while accumulator >= 1.0:
      currency += 1
      accumulator -= 1.0

    let mouse = getMousePosition()
    if isMouseButtonPressed(MouseButton.Left):
      if checkCollisionPointRec(mouse, CLICK_BUTTON):
        currency += int64(clickPower)
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
    block:
      let totalH = FONT_TITLE + FONT_LARGE
      let topY = int32(CLICK_BUTTON.y) +
                 (int32(CLICK_BUTTON.height) - totalH) div 2
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

  closeWindow()

when isMainModule:
  main()
