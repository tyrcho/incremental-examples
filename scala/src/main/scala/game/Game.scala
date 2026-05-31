package game

import scala.scalanative.unsafe.*
import scala.scalanative.unsigned.*
import Colors.*

val WINDOW_W: CInt = 800
val WINDOW_H: CInt = 600

private val TITLE_Y: Int        = 30
private val CURRENCY_Y: Int     = 90
private val PASSIVE_Y: Int      = 140
private val COIN_FRAME_W: Float = 128
private val COIN_FRAME_H: Float = 128
private val CLICK_LABEL_Y: Int  = 388

// named layout rects — single source of truth for both hit-testing and drawing
private inline def clickButtonRect: Ptr[Rectangle]  = mkRect(80, 220, 240, 240)
private inline def clickUpgradeRect: Ptr[Rectangle] = mkRect(400, 220, 320, 110)
private inline def coinDestRect: Ptr[Rectangle]     = mkRect(125, 232, 150, 150)

private inline def passiveUpgradeRect: Ptr[Rectangle] =
    mkRect(400, 350, 320, 110)

def gameLoop(coin: Ptr[Texture2D])(using Zone): Unit =
    val mouse = alloc[Vector2]()
    var state = GameState()
    while !Raylib.WindowShouldClose() do
        val dtSec = Raylib.GetFrameTime()
        Raylib.SN_GetMousePosition(mouse)
        state = handleClick(mouse)(state.tick(dtSec))
        Raylib.BeginDrawing()
        Raylib.SN_ClearBackground(RAYWHITE)
        drawScene(state, coin)
        Raylib.EndDrawing()

private def handleClick(mouse: Ptr[Vector2])(s: GameState): GameState =
    if !Raylib.IsMouseButtonPressed(MOUSE_LEFT) then s
    else if Raylib.SN_CheckCollisionPointRec(mouse, clickButtonRect) then s.startAnimation()
    else if Raylib.SN_CheckCollisionPointRec(mouse, clickUpgradeRect) then s.tryBuyClickUpgrade
    else if Raylib.SN_CheckCollisionPointRec(mouse, passiveUpgradeRect) then s.tryBuyPassiveUpgrade
    else s

// Drawing

private def drawScene(s: GameState, coin: Ptr[Texture2D])(using Zone): Unit =
    drawCenteredText(c"Idle Clicker", 0, WINDOW_W, TITLE_Y, FONT_TITLE, DARKGRAY)
    drawCenteredText(toCString(s"Currency: ${s.currency}"), 0, WINDOW_W, CURRENCY_Y, FONT_LARGE, BLACK)
    drawCenteredText(toCString(s"+${s.passiveRate}/sec"), 0, WINDOW_W, PASSIVE_Y, FONT_MEDIUM, DARKGREEN)
    drawClickArea(s.clickPower, s.anim.fold(0)(_.frame), coin)
    drawUpgrades(s)

private def drawClickArea(
    clickPower: Int,
    animFrame: Int,
    coin: Ptr[Texture2D]
)(using Zone): Unit =
    val r = clickButtonRect
    Raylib.SN_DrawRectangle(r.x.toInt, r.y.toInt, r.width.toInt, r.height.toInt, GREEN)
    Raylib.SN_DrawRectangleLinesEx(r, 3.0f, DARKGREEN)
    Raylib.SN_DrawTexturePro(coin, mkRect(animFrame * COIN_FRAME_W, 0, COIN_FRAME_W, COIN_FRAME_H), coinDestRect, mkVec2(0, 0), 0.0f, WHITE)
    drawCenteredText(c"CLICK", r.x.toInt, r.width.toInt, CLICK_LABEL_Y, FONT_TITLE, BLACK)
    drawCenteredText(toCString(s"(+$clickPower)"), r.x.toInt, r.width.toInt, CLICK_LABEL_Y + FONT_TITLE, FONT_LARGE, BLACK)

private def drawUpgrades(s: GameState)(using Zone): Unit =
    drawUpgradeButton(clickUpgradeRect, c"Click Power", toCString(s"Level: ${s.clickPower}"), c"+1 per click", toCString(s"Cost: ${s.clickCost}"), s.currency >= s.clickCost)
    drawUpgradeButton(passiveUpgradeRect, c"Passive Income", toCString(s"Level: ${s.passiveRate}"), c"+1 per second", toCString(s"Cost: ${s.passiveCost}"), s.currency >= s.passiveCost)
