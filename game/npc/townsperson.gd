class_name Townsperson
extends Node3D
## One townsperson living a looping routine from data/npcs.json: walk to a point, or stay a while playing a clip
## (idle, talk, sit, wave) facing someone or something. Moves along straight paths the layout keeps clear.

var person_name: String = ""
var model: CharacterModel
var _routine: Array = []
var _step: int = 0
var _timer: float = 0.0
var _yaw: float = 0.0


func setup(spec: Dictionary) -> void:
	person_name = spec["name"]
	name = person_name.to_pascal_case()
	model = CharacterModel.new()
	add_child(model)
	model.setup(spec["model"])
	position = Tuning.point(spec["start"])
	_routine = spec["routine"]
	_begin_step()


func current_step() -> Dictionary:
	return _routine[_step]


func _process(delta: float) -> void:
	var step: Dictionary = current_step()
	if step["do"] == "walk":
		_walk(Tuning.point(step["to"]), delta)
	else:
		_stay(step, delta)


func _walk(target: Vector3, delta: float) -> void:
	var to: Vector3 = target - position
	to.y = 0.0
	if to.length() <= Tuning.f("npc", "arrive_distance"):
		_next()
		return
	position += to.normalized() * minf(Tuning.f("npc", "walk_speed") * delta, to.length())
	position.y = move_toward(position.y, target.y, Tuning.f("npc", "walk_speed") * delta)
	_turn_towards(atan2(-to.x, -to.z), delta)


func _stay(step: Dictionary, delta: float) -> void:
	if step.has("at"):
		position = position.lerp(Tuning.point(step["at"]), clampf(Tuning.f("npc", "turn_sharpness") * delta, 0.0, 1.0))
	var to: Vector3 = Tuning.point(step["face"]) - position
	_turn_towards(atan2(-to.x, -to.z), delta)
	_timer -= delta
	if _timer <= 0.0:
		_next()


func _turn_towards(goal: float, delta: float) -> void:
	_yaw = lerp_angle(_yaw, goal, clampf(Tuning.f("npc", "turn_sharpness") * delta, 0.0, 1.0))
	rotation.y = _yaw


func _next() -> void:
	_step = (_step + 1) % _routine.size()
	_begin_step()


func _begin_step() -> void:
	var step: Dictionary = current_step()
	var clip: String = step["do"]
	_timer = float(step.get("seconds", 0.0))
	var blend: float = Tuning.f("npc", "blend_seconds")
	if clip == "walk":
		model.play("walk", blend, Tuning.f("npc", "walk_speed") / Tuning.f("npc", "walk_clip_speed"))
	else:
		model.play(clip if model.has_clip(clip) else "idle", blend)
