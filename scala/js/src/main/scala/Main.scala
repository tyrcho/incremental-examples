import game.*
import org.scalajs.dom

object Main:
    def main(args: Array[String]): Unit =
        val canvas = dom.document.getElementById("game").asInstanceOf[dom.html.Canvas]
        canvas.width  = Window.x.toInt
        canvas.height = Window.y.toInt
        val ctx      = canvas.getContext("2d").asInstanceOf[dom.CanvasRenderingContext2D]
        val renderer = CanvasRenderer(ctx)
        val input    = DomInput(canvas)

        val img = dom.document.createElement("img").asInstanceOf[dom.html.Image]
        img.onload = _ => startLoop(renderer, input)
        renderer.setSprite(img)
        img.src = "coin_sheet.png"

    private def startLoop(renderer: CanvasRenderer, input: DomInput): Unit =
        var state: GameState = GameState()
        var lastTs: Float    = 0f

        def tick(ts: Double): Unit =
            val tsF   = ts.toFloat
            val dtSec = ((tsF - lastTs) / 1000f).min(0.1f)
            lastTs    = tsF

            for p <- input.takeClick() do
                state = handleClick(p)(state)

            state = state.tick(dtSec)
            drawScene(state, renderer)

            dom.window.requestAnimationFrame(tick)

        dom.window.requestAnimationFrame { ts =>
            lastTs = ts.toFloat
            dom.window.requestAnimationFrame(tick)
        }
