import raylib

const
  FONT_TITLE*:  int32 = 36
  FONT_LARGE*:  int32 = 28
  FONT_MEDIUM*: int32 = 20
  FONT_SMALL*:  int32 = 18

proc drawCenteredText*(text: string;
                      containerX, containerW, y, fontSize: int32;
                      color: Color) =
  let w = measureText(text, fontSize)
  let x = containerX + (containerW - w) div 2
  drawText(text, x, y, fontSize, color)

proc drawUpgradeButton*(
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
