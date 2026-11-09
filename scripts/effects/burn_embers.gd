class_name BurnEmbers
extends Node2D
## The quiet "this is burning" cue: one or two ember pixels at a time, rising off the
## target's body and flickering out. Small on purpose, so a crowd of burning trash mobs
## stays readable (see DESIGN.md, visual hierarchy). Burning adds it to the burning target.

## Most embers alive at once.
const MAX_EMBERS := 2
## Seconds between new embers (each one waits a little extra at random).
const SPAWN_INTERVAL := 0.3
const SPAWN_JITTER := 0.15
## Seconds an ember lives, and how far it rises in that time, in pixels.
const EMBER_LIFETIME := 0.6
const RISE_HEIGHT := 7.0
## Where embers start, from the target's feet: up to this far left or right, and between
## these heights (negative is up), i.e. somewhere on a small creature's body.
const SPAWN_HALF_WIDTH := 4
const SPAWN_LOW := -4
const SPAWN_HIGH := -11
## How far an ember sways sideways as it rises, in pixels, and how fast.
const SWAY := 1.0
const SWAY_SPEED := 9.0
## Every so often a frame flickers a shade brighter.
const FLICKER_CHANCE := 0.25

## Each ember: {"start": Vector2, "age": float}.
var _embers: Array[Dictionary] = []
var _seconds_to_spawn: float = 0.0
## Hot when born, cooling as it rises: Emberoo's fire colours (see EmberooFlameColors).
var _hot_color := EmberooFlameColors.hot()
var _warm_color := EmberooFlameColors.warm()
var _cool_color := EmberooFlameColors.cool()


func _process(delta: float) -> void:
	_age_embers(delta)
	_seconds_to_spawn -= delta
	if _seconds_to_spawn <= 0.0 and _embers.size() < MAX_EMBERS:
		_seconds_to_spawn = SPAWN_INTERVAL + randf() * SPAWN_JITTER
		_embers.append({"start": _random_start(), "age": 0.0})
	queue_redraw()


func _draw() -> void:
	for ember in _embers:
		var life_share: float = ember["age"] / EMBER_LIFETIME
		var sway := sin(ember["age"] * SWAY_SPEED) * SWAY
		var spot: Vector2 = ember["start"] + Vector2(sway, -RISE_HEIGHT * life_share)
		draw_rect(Rect2(spot.round(), Vector2.ONE), _ember_color(life_share))


func _age_embers(delta: float) -> void:
	for ember in _embers:
		ember["age"] += delta
	_embers = _embers.filter(func(ember: Dictionary) -> bool: return ember["age"] < EMBER_LIFETIME)


func _random_start() -> Vector2:
	return Vector2(randi_range(-SPAWN_HALF_WIDTH, SPAWN_HALF_WIDTH), randi_range(SPAWN_HIGH, SPAWN_LOW))


func _ember_color(life_share: float) -> Color:
	var color := _hot_color if life_share < 0.3 else (_warm_color if life_share < 0.7 else _cool_color)
	if randf() < FLICKER_CHANCE:
		return _hot_color if color != _hot_color else _warm_color
	return color
