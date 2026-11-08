class_name AidCharges
extends Control
## Trainer's Aid charges as little tonic bottles next to the heart (full = pink, used = dark).

const BOTTLE := [".cc..", "#cc#.", "#gg#.", "#ll#.", "#ll#.", "#ll#.", ".##.."]
const SPACING := 7

@export var outline_color: Color = Color(0.035, 0.039, 0.078)
@export var full_colors: Dictionary = {"g": Color(0.78, 0.812, 0.8), "l": Color(0.875, 0.518, 0.647), "c": Color(0.678, 0.467, 0.341)}
@export var empty_colors: Dictionary = {"g": Color(0.224, 0.29, 0.314), "l": Color(0.125, 0.18, 0.216), "c": Color(0.224, 0.29, 0.314)}

var _charges: int = 0
var _max_charges: int = 0


func _ready() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var aid: TrainerAid = player.get_node_or_null("TrainerAid")
	if aid == null:
		return
	aid.charges_changed.connect(_on_charges_changed)
	_on_charges_changed(aid.charges, aid.max_charges)


func _on_charges_changed(charges: int, max_charges: int) -> void:
	_charges = charges
	_max_charges = max_charges
	queue_redraw()


func _draw() -> void:
	var width := _max_charges * SPACING - 2
	var left := roundf((size.x - width) / 2.0)
	var top := roundf((size.y - BOTTLE.size()) / 2.0)
	for index in _max_charges:
		var colors := full_colors if index < _charges else empty_colors
		_draw_bottle(Vector2(left + index * SPACING, top), colors)


func _draw_bottle(top_left: Vector2, colors: Dictionary) -> void:
	for y in BOTTLE.size():
		for x in 5:
			var pixel: String = BOTTLE[y][x]
			if pixel == ".":
				continue
			var color: Color = outline_color if pixel == "#" else colors[pixel]
			draw_rect(Rect2(top_left + Vector2(x, y), Vector2.ONE), color)
