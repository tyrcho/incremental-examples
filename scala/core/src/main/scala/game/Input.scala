package game

trait Input:
    def takeClick(): Option[Point]
