class_name AwakeningAura
extends Node2D
## Awakening II's quiet aura: a few faint blue-white flame pixels rising off Emberoo's body
## and flickering out. Low and see-through on purpose: auras mean elites and bosses (see
## DESIGN.md, visual hierarchy), so the player's is only a shimmer and he stays the clearest
## thing on screen. AwakeningLook shows it from Awakening II on; it follows the sprite.

## Most flame pixels alive at once.
const MAX_FLAMES := 4
## Seconds between new flame pixels (each one waits a little extra at random).
const SPAWN_INTERVAL := 0.12
const SPAWN_JITTER := 0.1
## Seconds a flame pixel lives, and how far it rises in that time, in pixels.
const FLAME_LIFETIME := 0.55
const RISE_HEIGHT := 6.0
## Where flame pixels start, from the sprite's centre: along his sides, up to his ears.
const SPAWN_HALF_WIDTH := 6
const SPAWN_LOW := 6
const SPAWN_HIGH := -6
## How see-through the flame pixels are when born (they fade as they rise).
const START_ALPHA := 0.55

## The sprite to follow (it lifts when he leaps).
@export var sprite: Node2D

## Each flame: {"start": Vector2, "age": float}.
var _flames: Array[Dictionary] = []
var _seconds_to_spawn: float = 0.0


func _process(delta: float) -> void:
	if not visible:
		_flames.clear()
		return
	position = sprite.position
	for flame in _flames:
		flame["age"] += delta
	_flames = _flames.filter(func(flame: Dictionary) -> bool: return flame["age"] < FLAME_LIFETIME)
	_seconds_to_spawn -= delta
	if _seconds_to_spawn <= 0.0 and _flames.size() < MAX_FLAMES:
		_seconds_to_spawn = SPAWN_INTERVAL + randf() * SPAWN_JITTER
		_flames.append({"start": _random_start(), "age": 0.0})
	queue_redraw()


func _draw() -> void:
	for flame in _flames:
		var life_share: float = flame["age"] / FLAME_LIFETIME
		var spot: Vector2 = flame["start"] + Vector2(0, -RISE_HEIGHT * life_share)
		var color := EmberooFlameColors.warm() if life_share < 0.5 else EmberooFlameColors.cool()
		draw_rect(Rect2(spot.round(), Vector2.ONE), Color(color, START_ALPHA * (1.0 - life_share)))


## Somewhere along the edge of his body, so the shimmer frames him without covering him.
func _random_start() -> Vector2:
	var side := -1 if randf() < 0.5 else 1
	return Vector2(side * randi_range(SPAWN_HALF_WIDTH - 2, SPAWN_HALF_WIDTH), randi_range(SPAWN_HIGH, SPAWN_LOW))
