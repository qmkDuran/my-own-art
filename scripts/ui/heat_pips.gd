class_name HeatPips
extends Control
## Emberoo's Heat as little flames to the right of the heart (lit = fire, cold = dark coal).
## A newly lit flame flares bright for a moment.

const FLAME := ["..#..", ".#o#.", "#ooo#", "#oyo#", "#oyy#", ".###."]
const SPACING := 6
const FLARE_TIME := 0.18

@export var outline_color: Color = Color(0.035, 0.039, 0.078)
@export var lit_colors: Dictionary = {"o": Color(0.812, 0.341, 0.235), "y": Color(0.871, 0.62, 0.255)}
@export var flare_colors: Dictionary = {"o": Color(0.871, 0.62, 0.255), "y": Color(0.91, 0.757, 0.439)}
@export var cold_colors: Dictionary = {"o": Color(0.204, 0.11, 0.153), "y": Color(0.204, 0.11, 0.153)}

var _heat: int = 0
var _max_heat: int = 0
var _flare_left: float = 0.0


func _ready() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var heat: Heat = player.get_node_or_null("Heat")
	if heat == null:
		return
	heat.heat_changed.connect(_on_heat_changed)
	_heat = heat.heat
	_max_heat = heat.max_heat
	queue_redraw()


func _process(delta: float) -> void:
	if _flare_left > 0.0:
		_flare_left = maxf(0.0, _flare_left - delta)
		if _flare_left == 0.0:
			queue_redraw()


func _on_heat_changed(heat: int, max_heat: int) -> void:
	if heat > _heat:
		_flare_left = FLARE_TIME
	_heat = heat
	_max_heat = max_heat
	queue_redraw()


func _draw() -> void:
	var top := roundf((size.y - FLAME.size()) / 2.0)
	for index in _max_heat:
		var colors := cold_colors
		if index < _heat:
			colors = flare_colors if (index == _heat - 1 and _flare_left > 0.0) else lit_colors
		_draw_flame(Vector2(index * SPACING, top), colors)


func _draw_flame(top_left: Vector2, colors: Dictionary) -> void:
	for y in FLAME.size():
		for x in 5:
			var pixel: String = FLAME[y][x]
			if pixel == ".":
				continue
			var color: Color = outline_color if pixel == "#" else colors[pixel]
			draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), color)
