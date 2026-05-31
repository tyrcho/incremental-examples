package game

import scala.scalanative.unsafe.*

class RaylibInput extends Input:
    private var _px: Float = 0f
    private var _py: Float = 0f

    def poll()(using Zone): Unit =
        val mouse = stackalloc[Vector2]()
        Raylib.SN_GetMousePosition(mouse)
        _px = mouse._1
        _py = mouse._2

    def takeClick(): Option[Point] =
        if Raylib.IsMouseButtonPressed(MOUSE_LEFT) then Some(Point(_px.toInt, _py.toInt))
        else None
