package game

val CLICK_LABEL_Y: Int = 388
val CURRENCY_Y:    Int = 90
val FONT_LARGE:    Int = 28
val FONT_MEDIUM:   Int = 20
val FONT_SMALL:    Int = 18
val FONT_TITLE:    Int = 36
val PASSIVE_Y:     Int = 140
val TITLE_Y:       Int = 30

val COIN_FRAME_H: Float = 128f
val COIN_FRAME_W: Float = 128f

final case class Point(x: Int, y: Int)

val CoinFrame: Point = Point(128, 128)
val Window:    Point = Point(800, 600)

final case class Rect(topLeft: Point, bottomRight: Point):
    def x: Int = topLeft.x
    def y: Int = topLeft.y
    def w: Int = bottomRight.x - topLeft.x
    def h: Int = bottomRight.y - topLeft.y
    def contains(p: Point): Boolean =
        p.x >= topLeft.x && p.x <= bottomRight.x && p.y >= topLeft.y && p.y <= bottomRight.y

val ClickButtonRect:    Rect = Rect(Point(80, 220),  Point(320, 460))
val ClickUpgradeRect:   Rect = Rect(Point(400, 220), Point(720, 330))
val CoinDestRect:       Rect = Rect(Point(125, 232), Point(275, 382))
val PassiveUpgradeRect: Rect = Rect(Point(400, 350), Point(720, 460))

// pure layout arithmetic
def upgradeTextPoints(rect: Rect): (Point, Point, Point, Point) =
    val x = rect.x + 12
    val y = rect.y + 4
    (
        Point(x, y),
        Point(x, y + FONT_MEDIUM + 4),
        Point(x, y + FONT_MEDIUM + 4 + FONT_SMALL + 4),
        Point(x, y + FONT_MEDIUM + 4 + FONT_SMALL + 4 + FONT_SMALL + 4)
    )
