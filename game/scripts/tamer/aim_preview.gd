class_name AimPreview
extends Node2D
## While a move key is held, a ghost of the move on the ground in its element's colour: the arc a strike will sweep,
## the lines bolts will fly, the path and landing of a dash, the circle of a burst (at the creature or at the
## cursor, clamped to range), the bubble of a ward. Releasing the key casts it.

const FILL_ALPHA: float = 0.18
const EDGE_ALPHA: float = 0.85
const EDGE_W: float = 2.0
const STEPS: int = 24
const WARD_R: float = 26.0
const BAND: float = 0.6
const SQUASH: float = 0.6               ## circles lie on the ground (seen at an angle)

var user: Creature
var move_id: String = ""
var at: Vector2


func _ready() -> void:
	z_index = Fx.FX_Z - 2
	material = Fx.unshaded()


func aim(c: Creature, id: String) -> void:
	user = c
	move_id = id
	visible = true


func clear() -> void:
	move_id = ""
	visible = false


func aiming() -> bool:
	return move_id != "" and is_instance_valid(user)


func _process(_delta: float) -> void:
	if aiming():
		at = TamerGame.current.input.cursor()
		queue_redraw()


func _draw() -> void:
	if not aiming():
		return
	var m: Dictionary = TamerData.move(move_id)
	var el: String = MoveText.element_of(move_id, user.element_id())
	var col: Color = TamerData.color(el, "core")
	var from: Vector2 = user.global_position
	var dir: Vector2 = MoveKind.dir_to(user, at)
	match String(m["kind"]):
		"strike":
			_cone(from, dir, float(m["range"]), deg_to_rad(float(m.get("arc", 120.0))), col)
		"bolt":
			_bolts(from, dir, m, col)
		"lunge":
			var to: Vector2 = MoveKind.clamp_aim(user, m, at)
			_band(from, to, float(m["radius"]) * (BAND if bool(m.get("path_hits", false)) else 0.15), col)
			_circle(to, float(m["radius"]), col)
		"burst":
			var center: Vector2 = from if String(m.get("at", "aim")) == "self" else MoveKind.clamp_aim(user, m, at)
			if center != from:
				_band(from, center, 1.0, col)
			_circle(center, float(m["radius"]), col)
		_:
			_circle(from, WARD_R, col)
			_circle(TamerGame.current.trainer.global_position, WARD_R, col)


func _local(p: Vector2) -> Vector2:
	return p - global_position


func _circle(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k: int in STEPS + 1:
		var a: float = TAU * k / STEPS
		pts.append(_local(c) + Vector2(cos(a) * r, sin(a) * r * SQUASH))
	draw_colored_polygon(pts.slice(0, STEPS), Color(col, FILL_ALPHA))
	draw_polyline(pts, Color(col, EDGE_ALPHA), EDGE_W)


func _cone(from: Vector2, dir: Vector2, r: float, arc: float, col: Color) -> void:
	var pts := PackedVector2Array([_local(from)])
	for k: int in STEPS + 1:
		var d: Vector2 = dir.rotated(-arc * 0.5 + arc * k / STEPS)
		pts.append(_local(from) + Vector2(d.x, d.y * SQUASH) * r)
	draw_colored_polygon(pts, Color(col, FILL_ALPHA))
	pts.append(_local(from))
	draw_polyline(pts, Color(col, EDGE_ALPHA), EDGE_W)


func _band(from: Vector2, to: Vector2, half: float, col: Color) -> void:
	var n: Vector2 = (to - from).normalized().orthogonal() * maxf(half, 1.0)
	var a: Vector2 = _local(from)
	var b: Vector2 = _local(to)
	draw_colored_polygon(PackedVector2Array([a + n, b + n, b - n, a - n]), Color(col, FILL_ALPHA))
	draw_line(a, b, Color(col, EDGE_ALPHA), EDGE_W)


func _bolts(from: Vector2, dir: Vector2, m: Dictionary, col: Color) -> void:
	var n: int = int(m.get("count", 1))
	var spread: float = deg_to_rad(float(m.get("spread", 0.0)))
	for k: int in n:
		var off: float = TAU * k / n if spread >= TAU - 0.01 else (lerpf(-spread * 0.5, spread * 0.5, float(k) / (n - 1)) if n > 1 else 0.0)
		var end: Vector2 = from + dir.rotated(off) * float(m["range"])
		draw_line(_local(from), _local(end), Color(col, EDGE_ALPHA), EDGE_W)
		draw_circle(_local(end), 3.0, Color(col, EDGE_ALPHA))
