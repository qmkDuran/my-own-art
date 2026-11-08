class_name HealthHeart
extends Control
## The player's health as one heart at the bottom of the screen.
##
## The heart is a container of red: it drains from the top down as health is lost.
## The exact numbers (e.g. 7/10) are shown beside it.

## Pixel map of the heart. 'x' = inside the heart.
const HEART_PIXELS := [
	"..xxx...xxx..",
	".xxxxx.xxxxx.",
	"xxxxxxxxxxxxx",
	"xxxxxxxxxxxxx",
	"xxxxxxxxxxxxx",
	".xxxxxxxxxxx.",
	"..xxxxxxxxx..",
	"...xxxxxxx...",
	"....xxxxx....",
	".....xxx.....",
	"......x......",
]
const HEART_SIZE := Vector2(13, 11)
## Pixels that catch the light (top-left of each lobe), when filled.
const SHINE_PIXELS := [Vector2(2, 1), Vector2(1, 2), Vector2(8, 1)]

@export var outline_color: Color = Color(0.035, 0.039, 0.078)
@export var empty_color: Color = Color(0.204, 0.11, 0.153)
@export var fill_color: Color = Color(0.647, 0.188, 0.188)
@export var shine_color: Color = Color(0.812, 0.341, 0.235)
@export var number_color: Color = Color(0.906, 0.835, 0.702)
## Gap between the heart and the numbers, in pixels.
const NUMBER_GAP := 4

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
		_health.healed.connect(func(_amount: int) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if _health == null:
		return
	var numbers := "%d/%d" % [_health.current_health, _health.max_health]
	var group_width := HEART_SIZE.x + NUMBER_GAP + PixelDigits.width_of(numbers)
	var top_left := Vector2(roundf((size.x - group_width) / 2.0), roundf((size.y - HEART_SIZE.y) / 2.0))
	_draw_outline(top_left)
	_draw_contents(top_left, _share_of_health_left())

	var numbers_top_left := top_left + Vector2(HEART_SIZE.x + NUMBER_GAP, roundf((HEART_SIZE.y - PixelDigits.GLYPH_HEIGHT) / 2.0))
	PixelDigits.draw_text(self, numbers, numbers_top_left, number_color, outline_color)


func _share_of_health_left() -> float:
	return clampf(float(_health.current_health) / float(_health.max_health), 0.0, 1.0)


## Dark outline one pixel around the heart, so it reads on any ground.
func _draw_outline(top_left: Vector2) -> void:
	for y in HEART_PIXELS.size():
		for x in int(HEART_SIZE.x):
			if HEART_PIXELS[y][x] == "x":
				draw_rect(Rect2(top_left + Vector2(x - 1, y - 1), Vector2(3, 3)), outline_color)


## Red fills the heart from the bottom up to the share of health left.
func _draw_contents(top_left: Vector2, share_left: float) -> void:
	var first_filled_row := HEART_SIZE.y * (1.0 - share_left)
	for y in HEART_PIXELS.size():
		for x in int(HEART_SIZE.x):
			if HEART_PIXELS[y][x] != "x":
				continue
			var is_filled := y >= first_filled_row - 0.001
			var color := fill_color if is_filled else empty_color
			if is_filled and Vector2(x, y) in SHINE_PIXELS:
				color = shine_color
			draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), color)
