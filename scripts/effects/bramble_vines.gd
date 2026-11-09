class_name BrambleVines
extends Node2D
## Mossdillo's Bramble Snare bursting out of the ground: thorny vines whip up in a circle,
## curl and sink back. Drawn in code on the pixel grid.

const LIFETIME := 0.6
const VINE_COUNT := 10

var _radius: float = 24.0
var _age: float = 0.0
var _vine_spots: Array[Vector2] = []


static func spawn(world: Node, at: Vector2, radius: float) -> void:
	var vines := BrambleVines.new()
	vines._radius = radius
	vines.z_index = 1
	world.add_child(vines)
	vines.global_position = at.round()


func _ready() -> void:
	for vine in VINE_COUNT:
		var angle := TAU * vine / VINE_COUNT + randf() * 0.4
		var distance := _radius * randf_range(0.3, 1.0)
		_vine_spots.append(Vector2(cos(angle) * distance, sin(angle) * distance * 0.5).round())


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var rise := minf(1.0, _age / 0.12) * (1.0 - maxf(0.0, (_age - 0.4) / 0.2))
	draw_arc(Vector2.ZERO, roundf(_radius), 0.0, TAU, 24, Color(ApolloPalette.GREEN_DARK, 0.6 * rise), 1.0)
	for index in _vine_spots.size():
		var base := _vine_spots[index]
		var height := roundf((6.0 + (index % 4) * 2.0) * rise)
		var lean := 1.0 if index % 2 == 0 else -1.0
		var tip := base + Vector2(lean * 2.0, -height)
		draw_line(base, base + Vector2(0, -roundf(height * 0.6)), ApolloPalette.GREEN_DARK, 1.0)
		draw_line(base + Vector2(0, -roundf(height * 0.6)), tip, ApolloPalette.GREEN, 1.0)
		draw_rect(Rect2(tip, Vector2.ONE), ApolloPalette.GREEN_LIGHT)
		if index % 3 == 0:
			draw_rect(Rect2(tip + Vector2(-lean, 1), Vector2.ONE), ApolloPalette.PINK)
