package game

import RgbaColor.*

def handleClick(p: Point)(s: GameState): GameState =
    if ClickButtonRect.contains(p) then s.startAnimation()
    else if ClickUpgradeRect.contains(p) then s.tryBuyClickUpgrade
    else if PassiveUpgradeRect.contains(p) then s.tryBuyPassiveUpgrade
    else s

def drawScene(s: GameState, r: Renderer): Unit =
    r.clearBackground(RayWhite)
    drawCenteredText(r, "Idle Clicker", 0, Window.x, TITLE_Y, FONT_TITLE, DarkGray)
    drawCenteredText(r, s"Currency: ${s.currency}", 0, Window.x, CURRENCY_Y, FONT_LARGE, Black)
    drawCenteredText(r, s"+${s.passiveRate}/sec", 0, Window.x, PASSIVE_Y, FONT_MEDIUM, DarkGreen)
    drawClickArea(s.clickPower, s.anim.fold(0)(_.frame), r)
    drawUpgrades(s, r)

private def drawCenteredText(
    r: Renderer,
    text: String,
    containerX: Int,
    containerW: Int,
    y: Int,
    size: Int,
    color: RgbaColor
): Unit =
    val w = r.measureText(text, size)
    r.drawText(text, Point(containerX + (containerW - w) / 2, y), size, color)

private def drawClickArea(clickPower: Int, frame: Int, r: Renderer): Unit =
    r.drawRect(ClickButtonRect, Green)
    r.drawRectOutline(ClickButtonRect, 3f, DarkGreen)
    r.drawSpriteFrame(frame, CoinFrame, CoinDestRect, White)
    drawCenteredText(r, "CLICK", ClickButtonRect.x, ClickButtonRect.w, CLICK_LABEL_Y, FONT_TITLE, Black)
    drawCenteredText(r, s"(+$clickPower)", ClickButtonRect.x, ClickButtonRect.w, CLICK_LABEL_Y + FONT_TITLE, FONT_LARGE, Black)

private def drawUpgrades(s: GameState, r: Renderer): Unit =
    drawUpgradeButton(r, ClickUpgradeRect, "Click Power", s"Level: ${s.clickPower}", "+1 per click", s"Cost: ${s.clickCost}", s.canBuyClickUpgrade)
    drawUpgradeButton(r, PassiveUpgradeRect, "Passive Income", s"Level: ${s.passiveRate}", "+1 per second", s"Cost: ${s.passiveCost}", s.canBuyPassiveUpgrade)

private def drawUpgradeButton(
    r: Renderer,
    rect: Rect,
    title: String,
    levelLine: String,
    effectLine: String,
    costLine: String,
    affordable: Boolean
): Unit =
    r.drawRect(rect, if affordable then SkyBlue else LightGray)
    r.drawRectOutline(rect, 2f, DarkGray)
    val x = rect.x + 12
    var y = rect.y + 4
    r.drawText(title,      Point(x, y), FONT_MEDIUM, Black);    y += FONT_MEDIUM + 4
    r.drawText(levelLine,  Point(x, y), FONT_SMALL,  DarkGray); y += FONT_SMALL  + 4
    r.drawText(effectLine, Point(x, y), FONT_SMALL,  DarkGray); y += FONT_SMALL  + 4
    r.drawText(costLine,   Point(x, y), FONT_SMALL,  if affordable then Black else Red)
