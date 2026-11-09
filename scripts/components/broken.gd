class_name Broken
extends PinnedEffect
## Broken: the target's poise ran out (see Poise). It's knocked down and dazed for a
## moment (held in place, stars circling its head): the big opening. Ripfin's and
## Emberoo's Signal Skills fire on it. Attached at runtime by `Broken.apply_to`.

const NODE_NAME := "Broken"
const STAR_COUNT := 3
const STAR_ORBIT := Vector2(6, 2)
const STAR_HEIGHT := -16.0
## How fast the stars circle, in radians per second.
const STAR_SPIN_SPEED := 7.0
## Each star trails one fainter pixel behind it.
const STAR_TRAIL_ALPHA := 0.7

var _age: float = 0.0


static func apply_to(target_health: Health, seconds: float) -> bool:
	var broken := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Broken.new()) as Broken
	if broken == null or broken.is_active():
		return false
	broken.start(seconds)
	return true


func _init() -> void:
	immunity_seconds = 0.0


func _ready() -> void:
	z_index = 2
	_tint_target(ApolloPalette.CREAM)


func _advance(delta: float) -> void:
	super._advance(delta)
	_age += delta
	queue_redraw()


func _draw() -> void:
	if not is_active():
		return
	for star in STAR_COUNT:
		var angle := _age * STAR_SPIN_SPEED + TAU * star / STAR_COUNT
		var spot := (Vector2(cos(angle) * STAR_ORBIT.x, STAR_HEIGHT + sin(angle) * STAR_ORBIT.y)).round()
		draw_rect(Rect2(spot, Vector2.ONE), ApolloPalette.GOLD)
		draw_rect(Rect2(spot + Vector2(-1, 0), Vector2.ONE), Color(ApolloPalette.WHITE, STAR_TRAIL_ALPHA))
