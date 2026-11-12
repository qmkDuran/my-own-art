class_name TacticalMarkers
extends Node3D
## F3 debug view in the world: the best few points of the bot's latest tactical ranking, as small balls (bright
## green for the best, fading for the rest) with their scores floating above.

const BALL_RADIUS: float = 0.18
const LABEL_HEIGHT: float = 0.5
const LABEL_PIXEL: float = 0.004
const LABEL_SIZE: int = 64
const REFRESH_TIME: float = 0.5
const BEST_COLOR: Color = Color(0.4, 1.0, 0.4)
const WORST_COLOR: Color = Color(1.0, 0.5, 0.2)

var _tactics: TacticalEval
var _refresh_left: float = 0.0


func setup(tactics: TacticalEval) -> void:
	_tactics = tactics
	name = "TacticalMarkers"
	visible = false


func _process(delta: float) -> void:
	_refresh_left -= delta
	if not visible or _refresh_left > 0.0:
		return
	_refresh_left = REFRESH_TIME
	for child: Node in get_children():
		child.queue_free()
	var shown: int = int(Tuning.ai_f("tactics", "markers_shown"))
	var top: Array[Dictionary] = _tactics.last_ranking.slice(0, shown)
	for rank: int in top.size():
		_marker(top[rank], BEST_COLOR.lerp(WORST_COLOR, float(rank) / maxf(shown - 1, 1)))


func _marker(point: Dictionary, color: Color) -> void:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BALL_RADIUS
	sphere.height = BALL_RADIUS * 2.0
	ball.mesh = sphere
	ball.material_override = WoodsMaterials.glow(color, 1.0)
	ball.position = point["pos"] + Vector3.UP * BALL_RADIUS
	add_child(ball)
	var label := Label3D.new()
	label.text = "%.2f" % float(point["score"])
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.pixel_size = LABEL_PIXEL
	label.font_size = LABEL_SIZE
	label.modulate = color
	label.position = ball.position + Vector3.UP * LABEL_HEIGHT
	add_child(label)
