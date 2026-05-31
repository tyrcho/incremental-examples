package game

import scala.scalanative.unsafe.*

class RaylibRenderer(coin: Ptr[Texture2D]) extends Renderer:

    override def beginFrame(): Unit = Raylib.BeginDrawing()
    override def endFrame(): Unit   = Raylib.EndDrawing()

    def clearBackground(c: RgbaColor): Unit =
        Zone { Raylib.SN_ClearBackground(mkColor(c.r, c.g, c.b, c.a)) }

    def drawRect(rect: Rect, c: RgbaColor): Unit =
        Zone { Raylib.SN_DrawRectangle(rect.x, rect.y, rect.w, rect.h, mkColor(c.r, c.g, c.b, c.a)) }

    def drawRectOutline(rect: Rect, thickness: Float, c: RgbaColor): Unit =
        Zone { Raylib.SN_DrawRectangleLinesEx(mkRect(rect.x.toFloat, rect.y.toFloat, rect.w.toFloat, rect.h.toFloat), thickness, mkColor(c.r, c.g, c.b, c.a)) }

    def measureText(text: String, fontSize: Int): Int =
        Zone { Raylib.MeasureText(toCString(text), fontSize) }

    def drawText(text: String, pos: Point, fontSize: Int, c: RgbaColor): Unit =
        Zone { Raylib.SN_DrawText(toCString(text), pos.x, pos.y, fontSize, mkColor(c.r, c.g, c.b, c.a)) }

    def drawSpriteFrame(frameIdx: Int, frameSize: Point, dest: Rect, tint: RgbaColor): Unit =
        Zone {
            Raylib.SN_DrawTexturePro(
              coin,
              mkRect((frameIdx * frameSize.x).toFloat, 0, frameSize.x.toFloat, frameSize.y.toFloat),
              mkRect(dest.x.toFloat, dest.y.toFloat, dest.w.toFloat, dest.h.toFloat),
              mkVec2(0, 0),
              0f,
              mkColor(tint.r, tint.g, tint.b, tint.a)
            )
        }
