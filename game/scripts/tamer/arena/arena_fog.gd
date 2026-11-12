class_name ArenaFog
extends Node2D
## Fog over an arena (the forest): only what is near your creature can be seen. Gale moves clear patches for a while
## (TamerData terrain "fog_clear_time").

const ALPHA: float = 0.88
const EDGE: float = 50.0

var a: ArenaLayout
var _cleared: Dictionary = {}           ## cell -> seconds left


func setup(layout: ArenaLayout) -> ArenaFog:
	a = layout
	z_index = Fx.FX_Z - 1
	z_as_relative = false
	return self


func clear_around(at: Vector2, r: float) -> void:
	for y: int in a.rows:
		for x: int in a.cols:
			var c := Vector2i(x, y)
			if a.center_of(c).distance_to(at) <= r:
				_cleared[c] = float(TamerData.rule("terrain.fog_clear_time"))


func cleared_at(p: Vector2) -> bool:
	return _cleared.has(a.cell_of(p))


func _process(delta: float) -> void:
	for c: Vector2i in _cleared.keys():
		_cleared[c] = float(_cleared[c]) - delta
		if float(_cleared[c]) <= 0.0:
			_cleared.erase(c)
	queue_redraw()


func _draw() -> void:
	var p: Creature = TamerGame.current.field.partner
	var eye: Vector2 = p.global_position if p != null and is_instance_valid(p) else a.rect_px().get_center()
	var vision: float = float(TamerData.rule("terrain.fog_vision"))
	for y: int in range(1, a.rows - 1):
		for x: int in range(1, a.cols - 1):
			var c := Vector2i(x, y)
			if _cleared.has(c):
				continue
			var k: float = clampf((a.center_of(c).distance_to(eye) - vision) / EDGE, 0.0, 1.0)
			if k > 0.0:
				draw_rect(a.cell_rect(c), Color(Pal.c("mist"), ALPHA * k))
