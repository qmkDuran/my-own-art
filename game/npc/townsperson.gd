class_name Townsperson
extends Node3D
## One townsperson living a looping routine from data/npcs.json: walk to a point, or stay a while playing a clip
## (idle, talk, sit, wave) facing someone or something. A sit is taken on the real bench nearest its spot (the seat
## worked out from where that bench stands); with no bench there, the sit is skipped. Moves along straight paths
## the layout keeps clear.

var person_name: String = ""
var model: CharacterModel
var _routine: Array = []
var _step: int = 0
var _timer: float = 0.0
var _yaw: float = 0.0
var _benches: Array[Node3D] = []
## The bench being sat on (null when not sitting).
var seat_bench: Node3D


func setup(spec: Dictionary, benches: Array[Node3D]) -> void:
	_benches = benches
	person_name = spec["name"]
	name = person_name.to_pascal_case()
	model = CharacterModel.new()
	add_child(model)
	model.setup(spec["model"], spec.get("keep_pose", []))
	var steps := Footsteps.new()
	add_child(steps)
	steps.setup(model, Tuning.number("audio", "steps", "townsfolk_db"))
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
	var speed: float = model.foot_speed("walk") * Tuning.f("npc", "pace")
	position += to.normalized() * minf(speed * delta, to.length())
	position.y = move_toward(position.y, target.y, speed * delta)
	_turn_towards(atan2(-to.x, -to.z), delta)


func _stay(step: Dictionary, delta: float) -> void:
	if seat_bench != null:
		var settle: float = clampf(Tuning.f("npc", "turn_sharpness") * delta, 0.0, 1.0)
		position = position.lerp(seat_spot(seat_bench), settle)
		var front: Vector3 = seat_bench.global_basis.z
		_turn_towards(atan2(-front.x, -front.z), delta)
	else:
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


## Where a sitter's origin goes on a bench: in front of its centre along its facing, at the seat's height.
static func seat_spot(bench: Node3D) -> Vector3:
	var seat: Dictionary = Tuning.doc("npcs")["seat"]
	return bench.global_position + bench.global_basis.z * float(seat["forward"]) + Vector3.UP * float(seat["lift"])


func _bench_near(at: Vector3) -> Node3D:
	for bench: Node3D in _benches:
		var flat := Vector2(bench.global_position.x - at.x, bench.global_position.z - at.z)
		if is_instance_valid(bench) and flat.length() < float(Tuning.doc("npcs")["seat"]["search"]):
			return bench
	return null


func _begin_step() -> void:
	var step: Dictionary = current_step()
	var clip: String = step["do"]
	seat_bench = _bench_near(Tuning.point(step["bench_near"])) if step.has("bench_near") else null
	if step.has("bench_near") and seat_bench == null:
		_next()
		return
	_timer = float(step.get("seconds", 0.0))
	var blend: float = Tuning.f("npc", "blend_seconds")
	if clip == "walk":
		model.play("walk", blend, Tuning.f("npc", "pace"))
	else:
		model.play(clip if model.has_clip(clip) else "idle", blend)
