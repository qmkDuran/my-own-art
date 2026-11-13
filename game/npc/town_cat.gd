class_name TownCat
extends Node3D
## The ginger cat on the canal wall: a still Meshy model brought to life with slow breathing and the odd lazy
## turn of the whole body towards whatever caught its eye.

var _model: Node3D
var _base_yaw: float = 0.0
var _goal_turn: float = 0.0
var _turn_timer: float = 0.0
var _clock: float = 0.0


func setup(library: AssetLibrary, spec: Dictionary) -> void:
	name = "Cat"
	position = Tuning.point(spec["at"])
	_base_yaw = deg_to_rad(float(spec["rot"]))
	rotation.y = _base_yaw
	_model = library.spawn("cat", 1.0, false)
	add_child(_model)


func _process(delta: float) -> void:
	_clock += delta
	var breath: float = sin(_clock * TAU / Tuning.f("cat", "breath_seconds")) * Tuning.f("cat", "breath_amount")
	_model.scale = Vector3(1.0 + breath * 0.5, 1.0 + breath, 1.0 + breath * 0.5)
	_turn_timer -= delta
	if _turn_timer <= 0.0:
		_turn_timer = randf_range(Tuning.f("cat", "turn_every_min"), Tuning.f("cat", "turn_every_max"))
		_goal_turn = deg_to_rad(randf_range(-1.0, 1.0) * Tuning.f("cat", "turn_deg"))
	var blend: float = clampf(Tuning.f("cat", "turn_sharpness") * delta, 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, _base_yaw + _goal_turn, blend)
