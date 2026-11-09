class_name Rooted
extends PinnedEffect
## Rooted (the Bloom element): vines wrap the target's feet and hold it in place. A set-up:
## Tide on it is a Drown, Fire on it is Kindling, Ripfin's Signal Skill fires on it, and
## Mossdillo's Rolling Thicket hits it twice as hard and bowls it into others.
## Attached at runtime by `Rooted.apply_to`.

const NODE_NAME := "Rooted"
const IMMUNITY := 0.5
const VINE_COUNT := 5
## Seconds the vines take to grow to full height.
const GROW_SECONDS := 0.15
## The leftmost vine's x, the gap between vines, and the shortest vine, in pixels.
const FIRST_VINE_X := -6
const VINE_SPACING := 3
const SHORTEST_VINE := 4
## The vine that binds across the feet: its half-width, and how high its ends rise at full growth.
const BIND_HALF_WIDTH := 7
const BIND_LEFT_RISE := 2
const BIND_RIGHT_RISE := 3

var _age: float = 0.0


static func apply_to(target_health: Health, seconds: float) -> bool:
	var rooted := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Rooted.new()) as Rooted
	if rooted == null:
		return false
	rooted.extend_to(seconds)
	return true


func _init() -> void:
	immunity_seconds = IMMUNITY


func _ready() -> void:
	z_index = 2
	_tint_target(ApolloPalette.GREEN)


func _advance(delta: float) -> void:
	super._advance(delta)
	_age += delta
	queue_redraw()


## Vines curling up around the feet, growing in over the first moment.
func _draw() -> void:
	if not is_active():
		return
	var grow := clampf(_age / GROW_SECONDS, 0.0, 1.0)
	for vine in VINE_COUNT:
		var base_x := FIRST_VINE_X + vine * VINE_SPACING
		var height := roundf((SHORTEST_VINE + (vine % 3) * 2) * grow)
		var lean := 1 if vine % 2 == 0 else -1
		draw_line(Vector2(base_x, 1), Vector2(base_x, 1 - height), ApolloPalette.GREEN_DARK, 1.0)
		draw_rect(Rect2(Vector2(base_x + lean, -height), Vector2.ONE), ApolloPalette.GREEN_LIGHT)
	draw_line(Vector2(-BIND_HALF_WIDTH, -BIND_LEFT_RISE * grow), Vector2(BIND_HALF_WIDTH, -BIND_RIGHT_RISE * grow), ApolloPalette.GREEN, 1.0)
