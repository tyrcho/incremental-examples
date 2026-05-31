package game

private val COIN_FRAMES: Int               = 8
private val COIN_FRAME_DURATION_SEC: Float = 0.06f

case class AnimState(frame: Int = 0, timerSec: Float = 0.0f):

    def tick(dtSec: Float): Option[AnimState] =
        val newTimer = timerSec + dtSec
        val frames   = (newTimer / COIN_FRAME_DURATION_SEC).toInt
        val newFrame = frame + frames
        if newFrame >= COIN_FRAMES then None
        else
            Some(
              copy(
                frame = newFrame,
                timerSec = newTimer - frames * COIN_FRAME_DURATION_SEC
              )
            )
