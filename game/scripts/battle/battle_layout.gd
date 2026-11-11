class_name BattleLayout
extends RefCounted
## Where everything sits on the 320x180 battle stage (the stage is centred on wider screens). The backdrop's
## pads are painted to match FOE_BASE and ALLY_BASE (art/scenes.py).

const STAGE: Vector2 = Vector2(320, 180)
const SPRITE: Vector2 = Vector2(80, 80)
const FOE_BASE: Vector2 = Vector2(100, 83)
const ALLY_BASE: Vector2 = Vector2(236, 152)
const FOE_CARD: Vector2 = Vector2(186, 6)
const ALLY_CARD: Vector2 = Vector2(6, 92)
const LOG_RECT: Rect2 = Rect2(4, 132, 192, 44)
const CMD_RECT: Rect2 = Rect2(200, 132, 116, 44)
const MOVES_RECT: Rect2 = Rect2(4, 132, 210, 44)
const INFO_RECT: Rect2 = Rect2(218, 132, 98, 44)
const RING_LIFT: Vector2 = Vector2(0, -36)
const CMD_COL_W: int = 54
const MOVE_COL_W: int = 100


static func base(ally: bool) -> Vector2:
	return ALLY_BASE if ally else FOE_BASE


static func ring_point(ally: bool) -> Vector2:
	return base(ally) + RING_LIFT
