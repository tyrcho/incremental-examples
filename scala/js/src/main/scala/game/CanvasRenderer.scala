package game

import org.scalajs.dom
import org.scalajs.dom.CanvasRenderingContext2D

class CanvasRenderer(ctx: CanvasRenderingContext2D) extends Renderer:
    private var sprite: Option[dom.html.Image] = None

    def setSprite(img: dom.html.Image): Unit = sprite = Some(img)

    private def rgba(c: RgbaColor): String =
        s"rgba(${c.r},${c.g},${c.b},${c.a / 255.0})"

    def clearBackground(c: RgbaColor): Unit =
        ctx.fillStyle = rgba(c)
        ctx.fillRect(0, 0, Window.x.toDouble, Window.y.toDouble)

    def drawRect(rect: Rect, c: RgbaColor): Unit =
        ctx.fillStyle = rgba(c)
        ctx.fillRect(rect.x.toDouble, rect.y.toDouble, rect.w.toDouble, rect.h.toDouble)

    def drawRectOutline(rect: Rect, thickness: Float, c: RgbaColor): Unit =
        ctx.strokeStyle = rgba(c)
        ctx.lineWidth = thickness.toDouble
        ctx.strokeRect(rect.x.toDouble, rect.y.toDouble, rect.w.toDouble, rect.h.toDouble)

    def measureText(text: String, fontSize: Int): Int =
        ctx.font = s"${fontSize}px monospace"
        ctx.measureText(text).width.toInt

    def drawText(text: String, pos: Point, fontSize: Int, c: RgbaColor): Unit =
        ctx.font = s"${fontSize}px monospace"
        ctx.fillStyle = rgba(c)
        ctx.textBaseline = "top"
        ctx.fillText(text, pos.x.toDouble, pos.y.toDouble)

    def drawSpriteFrame(frameIdx: Int, frameSize: Point, dest: Rect, tint: RgbaColor): Unit =
        sprite.foreach { img =>
            ctx.drawImage(
              img,
              frameIdx * frameSize.x.toDouble,
              0,
              frameSize.x.toDouble,
              frameSize.y.toDouble,
              dest.x.toDouble,
              dest.y.toDouble,
              dest.w.toDouble,
              dest.h.toDouble
            )
        }
