class_name Minimap
extends Control
## A square minimap in the top-right corner. There's no map data yet, so for now it's a radar:
## Emberoo's arrow in the middle (north is up), red dots for nearby enemies (Wardens as
## taller magenta marks) and pink dots for berries, placed relative to Emberoo.

const MAP_SIZE := 46
## The dark area inside the frame, where the radar is drawn.
const INSIDE := Rect2i(2, 2, MAP_SIZE - 4, MAP_SIZE - 4)
## World pixels per radar pixel: the radar reaches about 125 pixels out from Emberoo.
const WORLD_PIXELS_PER_DOT := 6.0
## How often the dots are refreshed, in seconds.
const REFRESH_SECONDS := 0.1
## Emberoo's arrow, pointing up, as [offset from the centre, colour].
const PLAYER_ARROW := [
	[Vector2i(0, -2), ApolloPalette.GOLD],
	[Vector2i(-1, -1), ApolloPalette.ORANGE], [Vector2i(0, -1), ApolloPalette.GOLD], [Vector2i(1, -1), ApolloPalette.ORANGE],
	[Vector2i(-1, 0), ApolloPalette.ORANGE], [Vector2i(0, 0), ApolloPalette.ORANGE], [Vector2i(1, 0), ApolloPalette.ORANGE],
	[Vector2i(-2, 1), ApolloPalette.ORANGE_DARK], [Vector2i(2, 1), ApolloPalette.ORANGE_DARK],
]

## Each mark to draw: {radar pixel: colour}.
var _marks: Dictionary = {}
var _refresh_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH_SECONDS
	_marks = _find_marks()
	queue_redraw()


func _draw() -> void:
	PixelShape.draw_stone_frame(self, MAP_SIZE)
	draw_rect(Rect2(INSIDE), ApolloPalette.NIGHT)
	_draw_range_cross()
	for pixel: Vector2i in _marks:
		PixelShape.draw_pixel(self, Vector2(pixel), _marks[pixel])
	for part: Array in PLAYER_ARROW:
		PixelShape.draw_pixel(self, Vector2(_centre() + (part[0] as Vector2i)), part[1])
	var north_left := MAP_SIZE / 2 - 1
	PixelFont.draw_text(self, "N", Vector2(north_left, -1), ApolloPalette.GREY_LIGHT, ApolloPalette.OUTLINE)


## Faint lines through the centre, so the dots read as "this way, this far".
func _draw_range_cross() -> void:
	var centre := _centre()
	draw_rect(Rect2(INSIDE.position.x, centre.y, INSIDE.size.x, 1), ApolloPalette.DARK)
	draw_rect(Rect2(centre.x, INSIDE.position.y, 1, INSIDE.size.y), ApolloPalette.DARK)


func _centre() -> Vector2i:
	return INSIDE.position + INSIDE.size / 2


func _find_marks() -> Dictionary:
	var marks := {}
	var player := PlayerFinder.find(self)
	if player == null:
		return marks
	for berry in _berries_near(player):
		_add_mark(marks, player, berry, ApolloPalette.PINK)
	for enemy in get_tree().get_nodes_in_group(EnemyReactions.ENEMIES_GROUP):
		if enemy is TrainingDummy:
			continue  # A practice post, not a threat.
		if enemy is Handler:
			_add_mark(marks, player, enemy as Node2D, ApolloPalette.MAGENTA, 2)
		elif enemy is Node2D:
			_add_mark(marks, player, enemy as Node2D, ApolloPalette.RED_LIGHT)
	return marks


## Berries lie in the same level as Emberoo.
func _berries_near(player: Node2D) -> Array[Node2D]:
	var berries: Array[Node2D] = []
	if player.get_parent() == null:
		return berries
	for node in player.get_parent().get_children():
		if node is Berry:
			berries.append(node as Node2D)
	return berries


## Adds a mark `height` pixels tall where the thing sits relative to Emberoo, if it's in range.
func _add_mark(marks: Dictionary, player: Node2D, thing: Node2D, color: Color, height: int = 1) -> void:
	var offset := (thing.global_position - player.global_position) / WORLD_PIXELS_PER_DOT
	var pixel := _centre() + Vector2i(roundi(offset.x), roundi(offset.y))
	for row in height:
		var mark := pixel + Vector2i(0, row)
		if INSIDE.has_point(mark):
			marks[mark] = color
