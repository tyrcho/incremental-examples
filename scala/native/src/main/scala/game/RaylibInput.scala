package game

import scala.scalanative.unsafe.*

class RaylibInput extends Input:
    private var mouseX: Float = 0f  // f10: idiomatic Scala 3 — no underscore prefix
    private var mouseY: Float = 0f

    def poll(): Unit =  // stackalloc needs no Zone
        val mouse = stackalloc[Vector2]()
        Raylib.SN_GetMousePosition(mouse)
        mouseX = mouse.vx
        mouseY = mouse.vy

    def takeClick(): Option[Point] =
        if Raylib.IsMouseButtonPressed(MOUSE_LEFT) then Some(Point(mouseX.toInt, mouseY.toInt))
        else None
