class_name BurnEmbers
extends Node2D
## The "this is burning" cue (Searing Jab, Ember Hop, Wildfire): when the fire catches, a
## short white-hot flare licks up the target's body; after that only two or three embers at
## a time rise off it and flicker out, so a crowd of burning trash mobs stays readable (see
## DESIGN.md, visual hierarchy). Sized to the target's body (FxBody). Burning adds it to
## the burning target.

## Most embers alive at once.
const MAX_EMBERS := 3
## Seconds between new embers (each one waits a little extra at random).
const SPAWN_INTERVAL := 0.25
const SPAWN_JITTER := 0.15
## Seconds an ember lives, and how far it rises in that time, as a share of the body's height.
const EMBER_LIFETIME := 0.6
const RISE_SHARE := 0.45
## Where embers start: up to this share of the body's height left or right of the middle,
## and between these shares of its height above the feet.
const SPAWN_HALF_WIDTH_SHARE := 0.25
const SPAWN_LOW_SHARE := 0.25
const SPAWN_HIGH_SHARE := 0.7
## How far an ember sways sideways as it rises, in pixels, and how fast.
const SWAY := 1.0
const SWAY_SPEED := 9.0
## Fresh embers are 2×2 pixels for this share of their life, then shrink to one pixel.
const BIG_SHARE := 0.3
## Every so often a frame flickers a shade brighter.
const FLICKER_CHANCE := 0.25
## The flare when the fire catches: how long it lasts, how many flame tongues, how tall
## (share of the body's height) and how often they flicker.
const FLARE_SECONDS := 0.22
const FLARE_TONGUES := 5
const FLARE_HEIGHT_SHARE := 0.6
const FLARE_FLICKER_RATE := 30.0
## Height of the old 16 px enemies, used when a body can't be measured.
const FALLBACK_BODY_HEIGHT := 16.0

## Each ember: {"start": Vector2, "age": float}.
var _embers: Array[Dictionary] = []
var _seconds_to_spawn: float = 0.0
var _age: float = 0.0
var _body_height: float = FALLBACK_BODY_HEIGHT
## Hot when born, cooling as it rises: Emberoo's burst colours (see EmberooFlameColors).
var _ramp: Array[Color] = EmberooFlameColors.burst_ramp()


func _ready() -> void:
	_body_height = FxBody.height_of(get_parent(), FALLBACK_BODY_HEIGHT)


func _process(delta: float) -> void:
	_age += delta
	_age_embers(delta)
	_seconds_to_spawn -= delta
	if _seconds_to_spawn <= 0.0 and _embers.size() < MAX_EMBERS:
		_seconds_to_spawn = SPAWN_INTERVAL + randf() * SPAWN_JITTER
		_embers.append({"start": _random_start(), "age": 0.0})
	queue_redraw()


func _draw() -> void:
	if _age < FLARE_SECONDS:
		_draw_flare(_age / FLARE_SECONDS)
	for ember in _embers:
		var life_share: float = ember["age"] / EMBER_LIFETIME
		var sway := sin(ember["age"] * SWAY_SPEED) * SWAY
		var spot: Vector2 = ember["start"] + Vector2(sway, -_body_height * RISE_SHARE * life_share)
		var size := Vector2.ONE * (2.0 if life_share < BIG_SHARE else 1.0)
		draw_rect(Rect2(spot.round(), size), _ember_color(life_share))


## Flame tongues licking up the body from its feet, white-hot at first, shrinking and cooling.
func _draw_flare(progress: float) -> void:
	var flicker_step := floori(_age * FLARE_FLICKER_RATE)
	var half_width := roundi(_body_height * SPAWN_HALF_WIDTH_SHARE)
	var tallest := _body_height * FLARE_HEIGHT_SHARE * (1.0 - progress * 0.6)
	for tongue in FLARE_TONGUES:
		var x := roundi(lerpf(-half_width, half_width, (tongue + 0.5) / FLARE_TONGUES))
		var height := roundi(tallest * (0.5 + 0.5 * FxPixels.noise(tongue, 0, flicker_step)))
		for rise in height:
			var heat_lost := progress * 0.5 + float(rise) / maxf(tallest, 1.0) * 0.6
			draw_rect(Rect2(x, -rise - 1, 1, 1), FxPixels.ramp_color(_ramp, heat_lost))


func _age_embers(delta: float) -> void:
	for ember in _embers:
		ember["age"] += delta
	_embers = _embers.filter(func(ember: Dictionary) -> bool: return ember["age"] < EMBER_LIFETIME)


func _random_start() -> Vector2:
	var half_width := roundi(_body_height * SPAWN_HALF_WIDTH_SHARE)
	var low := roundi(_body_height * SPAWN_LOW_SHARE)
	var high := roundi(_body_height * SPAWN_HIGH_SHARE)
	return Vector2(randi_range(-half_width, half_width), -randi_range(low, high))


## Gold when born, orange, then red; now and then a frame a shade brighter.
func _ember_color(life_share: float) -> Color:
	var heat_index := 1 if life_share < 0.3 else (2 if life_share < 0.7 else 4)
	if randf() < FLICKER_CHANCE:
		heat_index -= 1
	return _ramp[heat_index]
