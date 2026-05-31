package game

private val COIN_FRAMES: Int        = 8
private val COIN_FRAME_TIME: Double = 0.06

case class AnimState(frame: Int = 0, timer: Double = 0.0):

    def tick(dt: Double): Option[AnimState] =
        val newTimer = timer + dt
        val frames   = (newTimer / COIN_FRAME_TIME).toInt
        val newFrame = frame + frames
        if newFrame >= COIN_FRAMES then None
        else
            Some(
              copy(
                frame = newFrame,
                timer = newTimer - frames * COIN_FRAME_TIME
              )
            )
