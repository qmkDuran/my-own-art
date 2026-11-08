class_name HealthHeart
extends Control
## The player's health as one big heart at the left of the skill bar, with the numbers inside it.
##
## The heart is a container of red: it drains from the top down as health is lost,
## with a brighter line on the surface of what's left.

## Pixel map of the heart (29×23). 'x' = inside the heart.
const HEART_PIXELS := [
	".....xxxxxx.......xxxxxx.....",
	"...xxxxxxxxxx...xxxxxxxxxx...",
	"..xxxxxxxxxxxx.xxxxxxxxxxxx..",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	"xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	".xxxxxxxxxxxxxxxxxxxxxxxxxxx.",
	"..xxxxxxxxxxxxxxxxxxxxxxxxx..",
	"..xxxxxxxxxxxxxxxxxxxxxxxxx..",
	"...xxxxxxxxxxxxxxxxxxxxxxx...",
	"....xxxxxxxxxxxxxxxxxxxxx....",
	".....xxxxxxxxxxxxxxxxxxx.....",
	"......xxxxxxxxxxxxxxxxx......",
	".......xxxxxxxxxxxxxxx.......",
	".........xxxxxxxxxxx.........",
	"..........xxxxxxxxx..........",
	"............xxxxx............",
	"..............x..............",
]
const HEART_SIZE := Vector2i(29, 23)
## Pixels on the left lobe that catch the light, when filled.
const SHINE_PIXELS: Array[Vector2i] = [Vector2i(4, 3), Vector2i(5, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 4)]
## Rim pixels right of this column or below this row are in shadow (darker red).
const SHADOW_FROM := Vector2(HEART_SIZE.x * 0.55, HEART_SIZE.y * 0.6)
## Top of the numbers, from the top of the heart.
const NUMBERS_TOP := 9

var _health: Health
var _shape: Dictionary = PixelShape.from_rows(HEART_PIXELS)
var _depths: Dictionary = PixelShape.depths(_shape)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Wait one frame so the player has been added to the level.
	await get_tree().process_frame
	_health = PlayerFinder.find_component(self, "Health") as Health
	if _health != null:
		_health.damaged.connect(func(_amount: int, _from: Vector2) -> void: queue_redraw())
		_health.healed.connect(func(_amount: int) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if _health == null:
		return
	PixelShape.draw_outlined(self, _heart_colors(_share_of_health_left()), Vector2.ZERO, ApolloPalette.OUTLINE)
	var numbers := "%d/%d" % [_health.current_health, _health.max_health]
	var left := floori((HEART_SIZE.x - PixelFont.width_of(numbers)) / 2.0)
	PixelFont.draw_text(self, numbers, Vector2(left, NUMBERS_TOP), ApolloPalette.CREAM, ApolloPalette.OUTLINE)


func _share_of_health_left() -> float:
	return clampf(float(_health.current_health) / float(_health.max_health), 0.0, 1.0)


## The colour of every heart pixel: red up to the share of health left, dark coal above it.
func _heart_colors(share_left: float) -> Dictionary:
	var first_filled_row := HEART_SIZE.y * (1.0 - share_left)
	var surface_row := ceili(first_filled_row) if share_left < 1.0 else -1
	var colors := {}
	for pixel: Vector2i in _shape:
		var is_rim: bool = _depths[pixel] == 0
		if pixel.y < first_filled_row - 0.001:
			colors[pixel] = ApolloPalette.COAL_DARK if is_rim else ApolloPalette.COAL
		elif pixel.y == surface_row or (pixel in SHINE_PIXELS and pixel.y >= first_filled_row):
			colors[pixel] = ApolloPalette.RED_LIGHT
		elif is_rim and (pixel.x > SHADOW_FROM.x or pixel.y > SHADOW_FROM.y):
			colors[pixel] = ApolloPalette.WINE
		else:
			colors[pixel] = ApolloPalette.RED
	return colors
