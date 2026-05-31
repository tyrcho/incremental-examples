package game

final case class RgbaColor(r: Int, g: Int, b: Int, a: Int = 255)

object RgbaColor:
    val Black:     RgbaColor = RgbaColor(0, 0, 0)
    val DarkGray:  RgbaColor = RgbaColor(80, 80, 80)
    val DarkGreen: RgbaColor = RgbaColor(0, 117, 44)
    val Green:     RgbaColor = RgbaColor(0, 228, 48)
    val LightGray: RgbaColor = RgbaColor(200, 200, 200)
    val RayWhite:  RgbaColor = RgbaColor(245, 245, 245)
    val Red:       RgbaColor = RgbaColor(230, 41, 55)
    val SkyBlue:   RgbaColor = RgbaColor(102, 191, 255)
    val White:     RgbaColor = RgbaColor(255, 255, 255)
