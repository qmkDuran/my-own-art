class_name Rooted
extends PinnedEffect
## Rooted (the Bloom element): vines wrap the target's feet and hold it in place. A set-up:
## Tide on it is a Drown, Fire on it is Kindling, Ripfin's Signal Skill fires on it, and
## Mossdillo's Rolling Thicket hits it twice as hard and bowls it into others.
## Attached at runtime by `Rooted.apply_to`.

const NODE_NAME := "Rooted"
const IMMUNITY := 0.5
const VINE_COUNT := 5

var _tint: StatusTint
var _age: float = 0.0


static func apply_to(target_health: Health, seconds: float) -> bool:
	var rooted := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Rooted.new()) as Rooted
	if rooted == null:
		return false
	rooted.start(maxf(seconds, rooted.seconds_left()))
	return true


func _init() -> void:
	immunity_seconds = IMMUNITY


func _ready() -> void:
	z_index = 2
	_tint = StatusTint.new(target().get_node_or_null("Sprite") as CanvasItem, ApolloPalette.GREEN)
	add_child(_tint)


func _advance(delta: float) -> void:
	super._advance(delta)
	_age += delta
	queue_redraw()


## Vines curling up around the feet, growing in over the first moment.
func _draw() -> void:
	if not is_active():
		return
	var grow := clampf(_age / 0.15, 0.0, 1.0)
	for vine in VINE_COUNT:
		var base_x := -6 + vine * 3
		var height := roundf((4 + (vine % 3) * 2) * grow)
		var lean := 1 if vine % 2 == 0 else -1
		draw_line(Vector2(base_x, 1), Vector2(base_x, 1 - height), ApolloPalette.GREEN_DARK, 1.0)
		draw_rect(Rect2(Vector2(base_x + lean, -height), Vector2.ONE), ApolloPalette.GREEN_LIGHT)
	draw_line(Vector2(-7, -2 * grow), Vector2(7, -3 * grow), ApolloPalette.GREEN, 1.0)


func _end() -> void:
	if is_instance_valid(_tint):
		_tint.queue_free()
