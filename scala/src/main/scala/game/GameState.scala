package game

case class GameState(
    currency: Long = 0L,
    clickPower: Int = 1,
    passiveRate: Int = 0,
    clickCost: Int = 10,
    passiveCost: Int = 25,
    accumulatorSec: Float = 0.0f,
    anim: Option[AnimState] = None
):

    def startAnimation(): GameState = copy(anim = Some(AnimState()))

    def tryBuyClickUpgrade: GameState =
        if currency >= clickCost
        then
            copy(
              currency = currency - clickCost,
              clickPower = clickPower + 1,
              clickCost = clickCost * 3 / 2
            )
        else this

    def tryBuyPassiveUpgrade: GameState =
        if currency >= passiveCost
        then
            copy(
              currency = currency - passiveCost,
              passiveRate = passiveRate + 1,
              passiveCost = passiveCost * 3 / 2
            )
        else this

    def tick(dtSec: Float): GameState =
        val newAcc  = accumulatorSec + dtSec * passiveRate
        val earned  = newAcc.toLong
        val newAnim = anim.flatMap(_.tick(dtSec))
        val reward  = if anim.isDefined && newAnim.isEmpty then clickPower else 0
        copy(
          currency       = currency + earned + reward,
          accumulatorSec = newAcc - earned.toFloat,
          anim           = newAnim
        )
