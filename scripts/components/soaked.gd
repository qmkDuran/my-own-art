class_name Soaked
extends ImpairingEffect
## Soaked (the Tide element): the target is drenched, dripping and tinted sky blue, and slowed
## (it covers only part of the ground it means to). A set-up: Fire on it is a Steam Burst,
## Ripfin's Riptide Ambush bursts up under every soaked enemy, and its Signal Skill crits.
## Attached at runtime by `Soaked.apply_to`; applying it again refreshes it.

const NODE_NAME := "Soaked"
## Share of its own movement a soaked target still makes.
const SPEED_SHARE := 0.55
const DRIP_SECONDS := 0.12
const DRIP_COLORS: Array[Color] = [ApolloPalette.SKY, ApolloPalette.SKY_LIGHT]
## Drops fall from up to this far left or right of the body, this high above the feet.
const DRIP_SPREAD := 4
const DRIP_HEIGHT := -12
const DRIP_LIFETIME := 0.35

var _last_position: Vector2
var _drip_left: float = 0.0


static func apply_to(target_health: Health, seconds: float) -> bool:
	var soaked := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Soaked.new()) as Soaked
	if soaked == null:
		return false
	soaked.extend_to(seconds)
	return true


func _init() -> void:
	immunity_seconds = 0.0


func _ready() -> void:
	z_index = 2
	_last_position = (target() as Node2D).global_position
	_tint_target(ApolloPalette.SKY)


func _advance(delta: float) -> void:
	super._advance(delta)
	var body := target() as Node2D
	body.global_position = _last_position + (body.global_position - _last_position) * SPEED_SHARE
	_last_position = body.global_position
	_drip_left -= delta
	if _drip_left <= 0.0:
		_drip_left = DRIP_SECONDS
		_drip(body)


func _drip(body: Node2D) -> void:
	var from := body.global_position + Vector2(randi_range(-DRIP_SPREAD, DRIP_SPREAD), DRIP_HEIGHT)
	var drop := PixelDebris.spray(body.get_parent(), from, DRIP_COLORS, 1, Vector2.DOWN, 20.0)
	drop.speed_range = Vector2(5, 15)
	drop.lifetime = DRIP_LIFETIME
	drop.chunk_share = 0.0
