package game

import org.scalajs.dom

class DomInput(canvas: dom.html.Canvas) extends Input:
    private var _click: Option[Point] = None

    canvas.addEventListener(
      "mousedown",
      (e: dom.MouseEvent) => {
          val rect = canvas.getBoundingClientRect()
          _click = Some(Point((e.clientX - rect.left).toInt, (e.clientY - rect.top).toInt))
      }
    )

    canvas.addEventListener(
      "touchstart",
      (e: dom.TouchEvent) => {
          e.preventDefault()
          val t    = e.touches(0)
          val rect = canvas.getBoundingClientRect()
          _click = Some(Point((t.clientX - rect.left).toInt, (t.clientY - rect.top).toInt))
      }
    )

    def takeClick(): Option[Point] =
        val c = _click
        _click = None
        c
