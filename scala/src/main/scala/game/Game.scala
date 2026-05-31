package game

import scala.scalanative.unsafe.*
import scala.scalanative.unsigned.*
import Colors.*

val WINDOW_W: CInt = 800
val WINDOW_H: CInt = 600

private val TITLE_Y:    CInt = 30
private val CURRENCY_Y: CInt = 90
private val PASSIVE_Y:  CInt = 140

private val CLICK_COST_INIT:   Int = 10
private val PASSIVE_COST_INIT: Int = 25

private val COIN_FRAMES:    Int    = 8
private val COIN_FRAME_W:   Float  = 128.0f
private val COIN_FRAME_H:   Float  = 128.0f
private val COIN_FRAME_TIME: Double = 0.06

def run()(using Zone): Unit =
  var currency:    Long    = 0L
  var clickPower:  Int     = 1
  var passiveRate: Int     = 0
  var clickCost:   Int     = CLICK_COST_INIT
  var passiveCost: Int     = PASSIVE_COST_INIT
  var accumulator: Double  = 0.0
  var animPlaying: Boolean = false
  var animFrame:   Int     = 0
  var animTimer:   Double  = 0.0

  val coin = alloc[Texture2D]()
  Raylib.SN_LoadTexture(c"../assets/coin_sheet.png", coin)

  val mouse = alloc[Vector2]()

  while !Raylib.WindowShouldClose() do
    val dt = Raylib.GetFrameTime().toDouble

    accumulator += dt * passiveRate
    while accumulator >= 1.0 do
      currency    += 1
      accumulator -= 1.0

    if animPlaying then
      animTimer += dt
      while animTimer >= COIN_FRAME_TIME do
        animTimer -= COIN_FRAME_TIME
        animFrame += 1
        if animFrame >= COIN_FRAMES then
          animFrame   = COIN_FRAMES - 1
          animPlaying = false
          currency   += clickPower
    end if

    Raylib.SN_GetMousePosition(mouse)

    if Raylib.IsMouseButtonPressed(MOUSE_LEFT) then
      if Raylib.SN_CheckCollisionPointRec(mouse, mkRect(80, 220, 240, 240)) then
        animPlaying = true; animFrame = 0; animTimer = 0.0
      else if Raylib.SN_CheckCollisionPointRec(mouse, mkRect(400, 220, 320, 110)) && currency >= clickCost then
        currency -= clickCost; clickPower += 1; clickCost = clickCost * 3 / 2
      else if Raylib.SN_CheckCollisionPointRec(mouse, mkRect(400, 350, 320, 110)) && currency >= passiveCost then
        currency -= passiveCost; passiveRate += 1; passiveCost = passiveCost * 3 / 2
    end if

    Raylib.BeginDrawing()
    Raylib.SN_ClearBackground(RAYWHITE)
    drawScene(currency, clickPower, passiveRate, clickCost, passiveCost, animFrame, coin)
    Raylib.EndDrawing()
  end while

  Raylib.SN_UnloadTexture(coin)

private def drawScene(currency: Long, clickPower: Int, passiveRate: Int,
                      clickCost: Int, passiveCost: Int, animFrame: Int,
                      coin: Ptr[Texture2D])(using Zone): Unit =
  drawCenteredText(c"Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY)
  drawCenteredText(toCString(s"Currency: $currency"), 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK)
  drawCenteredText(toCString(s"+$passiveRate/sec"), 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DARKGREEN)
  drawClickArea(clickPower, animFrame, coin)
  drawUpgrades(currency, clickPower, passiveRate, clickCost, passiveCost)

private def drawClickArea(clickPower: Int, animFrame: Int, coin: Ptr[Texture2D])(using Zone): Unit =
  Raylib.SN_DrawRectangle(80, 220, 240, 240, GREEN)
  Raylib.SN_DrawRectangleLinesEx(mkRect(80, 220, 240, 240), 3.0f, DARKGREEN)
  Raylib.SN_DrawTexturePro(coin,
    mkRect(animFrame * COIN_FRAME_W, 0, COIN_FRAME_W, COIN_FRAME_H),
    mkRect(125, 232, 150, 150),
    mkVec2(0, 0), 0.0f, WHITE)
  drawCenteredText(c"CLICK", 80, 240, 388, FONT_TITLE, BLACK)
  drawCenteredText(toCString(s"(+$clickPower)"), 80, 240, 388 + FONT_TITLE, FONT_LARGE, BLACK)

private def drawUpgrades(currency: Long, clickPower: Int, passiveRate: Int,
                         clickCost: Int, passiveCost: Int)(using Zone): Unit =
  drawUpgradeButton(mkRect(400, 220, 320, 110), c"Click Power",
    toCString(s"Level: $clickPower"), c"+1 per click",
    toCString(s"Cost: $clickCost"), currency >= clickCost)
  drawUpgradeButton(mkRect(400, 350, 320, 110), c"Passive Income",
    toCString(s"Level: $passiveRate"), c"+1 per second",
    toCString(s"Cost: $passiveCost"), currency >= passiveCost)
