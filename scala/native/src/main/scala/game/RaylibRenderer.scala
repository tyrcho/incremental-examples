package game

import scala.scalanative.unsafe.*

// f2: one Zone per frame, opened/rolled in beginFrame/endFrame.
// Methods that only use stackalloc (mkColor, mkRect, mkVec2) need no Zone.
// Only drawText/measureText need Zone (for toCString); they use frameZone.
class RaylibRenderer(coin: Ptr[Texture2D]) extends Renderer:
    private var frameZone: Zone = Zone.open()

    override def beginFrame(): Unit = Raylib.BeginDrawing()

    override def endFrame(): Unit =
        Raylib.EndDrawing()
        frameZone.close()
        frameZone = Zone.open()

    def clearBackground(c: RgbaColor): Unit =
        Raylib.SN_ClearBackground(mkColor(c.r, c.g, c.b, c.a))

    def drawRect(rect: Rect, c: RgbaColor): Unit =
        Raylib.SN_DrawRectangle(rect.x, rect.y, rect.w, rect.h, mkColor(c.r, c.g, c.b, c.a))

    def drawRectOutline(rect: Rect, thickness: Float, c: RgbaColor): Unit =
        Raylib.SN_DrawRectangleLinesEx(mkRect(rect.x.toFloat, rect.y.toFloat, rect.w.toFloat, rect.h.toFloat), thickness, mkColor(c.r, c.g, c.b, c.a))

    def measureText(text: String, fontSize: Int): Int =
        given Zone = frameZone
        Raylib.MeasureText(toCString(text), fontSize)

    def drawText(text: String, pos: Point, fontSize: Int, c: RgbaColor): Unit =
        given Zone = frameZone
        Raylib.SN_DrawText(toCString(text), pos.x, pos.y, fontSize, mkColor(c.r, c.g, c.b, c.a))

    def drawSpriteFrame(frameIdx: Int, frameSize: Point, dest: Rect, tint: RgbaColor): Unit =
        Raylib.SN_DrawTexturePro(
          coin,
          mkRect((frameIdx * frameSize.x).toFloat, 0, frameSize.x.toFloat, frameSize.y.toFloat),
          mkRect(dest.x.toFloat, dest.y.toFloat, dest.w.toFloat, dest.h.toFloat),
          mkVec2(0, 0),
          0f,
          mkColor(tint.r, tint.g, tint.b, tint.a)
        )
