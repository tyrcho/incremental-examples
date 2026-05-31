package game

case class GameState(
    currency: Long = 0L,
    clickPower: Int = 1,
    passiveRate: Int = 0,
    clickCost: Int = 10,
    passiveCost: Int = 25,
    accumulator: Double = 0.0,
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

    def tick(dt: Double): GameState =
        val newAcc = accumulator + dt * passiveRate
        val earned = newAcc.toLong
        val withPassive = copy(
          currency = currency + earned,
          accumulator = newAcc - earned.toDouble
        )
        anim match
            case None => withPassive
            case Some(a) =>
                a.tick(dt) match
                    case Some(newAnim) => withPassive.copy(anim = Some(newAnim))
                    case None =>
                        withPassive.copy(
                          anim = None,
                          currency = withPassive.currency + clickPower
                        )
