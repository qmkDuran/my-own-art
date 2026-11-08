class_name HealthFlames
extends Control
## The player's health as a row of small flames at the bottom of the screen.
##
## One flame per point of health. Each hit snuffs a flame out to a grey ember.

## Pixel map of one flame. '.' = empty, 'o' = outer flame, 'r' = red, 'c' = bright core.
const FLAME_PIXELS := [
	"...o...",
	"..oo...",
	"..oro..",
	".orro..",
	".orcro.",
	"orcccro",
	"orcccro",
	".orrro.",
]
const FLAME_WIDTH := 7
## Pixels from one flame's left edge to the next.
const FLAME_SPACING := 8

@export var outline_color: Color = Color(0.035, 0.039, 0.078)
@export var lit_colors: Dictionary = {
	"o": Color(0.871, 0.62, 0.255),
	"r": Color(0.812, 0.341, 0.235),
	"c": Color(0.91, 0.757, 0.439),
}
@export var snuffed_colors: Dictionary = {
	"o": Color(0.224, 0.29, 0.314),
	"r": Color(0.341, 0.447, 0.467),
	"c": Color(0.341, 0.447, 0.467),
}

var _health: Health


func _ready() -> void:
	# Wait one frame so the player has been added to the level.
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_health = player.get_node_or_null("Health")
	if _health != null:
		_health.damaged.connect(func(_amount: int, _from: Vector2) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if _health == null:
		return
	var row_width := (_health.max_health - 1) * FLAME_SPACING + FLAME_WIDTH
	var left := roundf((size.x - row_width) / 2.0)
	for flame_index in _health.max_health:
		var is_lit := flame_index < _health.current_health
		_draw_flame(Vector2(left + flame_index * FLAME_SPACING, 1), lit_colors if is_lit else snuffed_colors)


func _draw_flame(top_left: Vector2, colors: Dictionary) -> void:
	# Dark outline first, one pixel around every flame pixel, so it reads on any ground.
	for y in FLAME_PIXELS.size():
		for x in FLAME_WIDTH:
			if FLAME_PIXELS[y][x] != ".":
				draw_rect(Rect2(top_left + Vector2(x - 1, y - 1), Vector2(3, 3)), outline_color)
	for y in FLAME_PIXELS.size():
		for x in FLAME_WIDTH:
			var pixel: String = FLAME_PIXELS[y][x]
			if pixel != ".":
				draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), colors[pixel])
