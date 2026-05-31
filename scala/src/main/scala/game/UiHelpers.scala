package game

import scala.scalanative.unsafe.*
import scala.scalanative.unsigned.*
import Colors.*

// f5: alphabetical order
val FONT_LARGE: CInt  = 28
val FONT_MEDIUM: CInt = 20
val FONT_SMALL: CInt  = 18
val FONT_TITLE: CInt  = 36

def drawCenteredText(
    text: CString,
    containerX: CInt,
    containerW: CInt,
    y: CInt,
    size: CInt,
    color: Ptr[Color]
): Unit =
    val w = Raylib.MeasureText(text, size)
    Raylib.SN_DrawText(text, containerX + (containerW - w) / 2, y, size, color)

def drawUpgradeButton(
    rect: Ptr[Rectangle],
    title: CString,
    levelLine: CString,
    effectLine: CString,
    costLine: CString,
    affordable: Boolean
): Unit =
    val fill = if affordable then SKYBLUE else LIGHTGRAY
    // f3: named accessors instead of _1/_2/_3/_4
    Raylib.SN_DrawRectangle(
      rect.x.toInt,
      rect.y.toInt,
      rect.width.toInt,
      rect.height.toInt,
      fill
    )
    Raylib.SN_DrawRectangleLinesEx(rect, 2.0f, DARKGRAY)
    val x = rect.x.toInt + 12
    var y = rect.y.toInt + 4
    Raylib.SN_DrawText(title, x, y, FONT_MEDIUM, BLACK); y += FONT_MEDIUM + 4
    Raylib.SN_DrawText(levelLine, x, y, FONT_SMALL, DARKGRAY);
    y += FONT_SMALL + 4
    Raylib.SN_DrawText(effectLine, x, y, FONT_SMALL, DARKGRAY);
    y += FONT_SMALL + 4
    val costColor = if affordable then BLACK else RED
    Raylib.SN_DrawText(costLine, x, y, FONT_SMALL, costColor)
