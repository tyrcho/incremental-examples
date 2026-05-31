package game

trait Renderer:
    def beginFrame(): Unit = ()
    def endFrame(): Unit = ()

    def clearBackground(c: RgbaColor): Unit
    def drawRect(rect: Rect, c: RgbaColor): Unit
    def drawRectOutline(rect: Rect, thickness: Float, c: RgbaColor): Unit
    def measureText(text: String, fontSize: Int): Int
    def drawText(text: String, pos: Point, fontSize: Int, c: RgbaColor): Unit
    def drawSpriteFrame(frameIdx: Int, frameSize: Point, dest: Rect, tint: RgbaColor): Unit
