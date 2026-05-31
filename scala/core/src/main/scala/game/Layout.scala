package game

val FONT_TITLE:  Int = 36
val FONT_LARGE:  Int = 28
val FONT_MEDIUM: Int = 20
val FONT_SMALL:  Int = 18

val TITLE_Y:       Int = 30
val CURRENCY_Y:    Int = 90
val PASSIVE_Y:     Int = 140
val CLICK_LABEL_Y: Int = 388

final case class Point(x: Int, y: Int)

val Window:    Point = Point(800, 600)
val CoinFrame: Point = Point(128, 128)

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
