class_name Spawner
extends Node
## Brings the night's creatures in from the fog: follows the wave schedule in data/defence.json (a steady trickle
## whose mix and pace change with time, plus a few surges), placing each creature in a ring around the player, on
## open ground the player can walk to (never inside a wall or a house, never in a closed-off yard).

const PROBE_HEIGHT: float = 0.6

var _horde: Horde
var _player: Node3D
var _timer: float = 0.0
var _surges_done: int = 0
var _rng := RandomNumberGenerator.new()
var _grid: WalkGrid


func setup(horde: Horde, player: Node3D) -> void:
	name = "Spawner"
	_horde = horde
	_player = player


func reset() -> void:
	_timer = 0.0
	_surges_done = 0
	if _grid == null:
		_grid = WalkGrid.new()
		_grid.build(_player.get_world_3d(), Tuning.point(Tuning.doc("town")["player_start"]["at"]))


## Advances the schedule to the night's clock (seconds since the night began).
func advance(clock: float, delta: float) -> void:
	var wave: Dictionary = _wave_at(clock)
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(wave["every"])
		spawn_kind(_pick(wave["mix"]))
	var surges: Array = Tuning.doc("defence")["surges"]
	while _surges_done < surges.size() and clock >= float(surges[_surges_done]["at"]):
		for index: int in int(surges[_surges_done]["count"]):
			spawn_kind(surges[_surges_done]["type"])
		_surges_done += 1


## One creature at a free spot in the spawn ring (skipped if the night is already full or no spot is free).
func spawn_kind(kind: String) -> Creature:
	if _horde.creatures.size() >= int(Tuning.number("defence", "spawn", "max_alive")):
		return null
	var at: Vector3 = free_spot()
	return _horde.spawn(kind, at) if at != Vector3.INF else null


func free_spot() -> Vector3:
	for attempt: int in int(Tuning.number("defence", "spawn", "tries")):
		var angle: float = _rng.randf() * TAU
		var distance: float = _rng.randf_range(Tuning.number("defence", "spawn", "radius_min"), Tuning.number(
			"defence", "spawn", "radius_max"))
		var at: Vector3 = _player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		at.y = _grid.floor_at(at) if _grid != null else 0.0
		if not is_nan(at.y) and inside_town(at) and is_open(at):
			return at
	return Vector3.INF


## Nothing solid at this spot (a small ball just above the ground).
func is_open(at: Vector3) -> bool:
	var ball := SphereShape3D.new()
	ball.radius = Vitality.BODY_RADIUS
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = ball
	query.transform = Transform3D(Basis(), at + Vector3.UP * PROBE_HEIGHT)
	query.collision_mask = Layers.WORLD
	return _player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


static func inside_town(at: Vector3) -> bool:
	var bounds: Array = Tuning.doc("town")["walk_bounds"]
	return at.x > float(bounds[0]) and at.z > float(bounds[1]) and at.x < float(bounds[2]) and at.z < float(bounds[3])


func _wave_at(clock: float) -> Dictionary:
	var current: Dictionary = {}
	for wave: Dictionary in Tuning.doc("defence")["waves"]:
		if clock >= float(wave["from"]):
			current = wave
	return current


func _pick(mix: Dictionary) -> String:
	var total: int = 0
	for kind: String in mix:
		total += int(mix[kind])
	var roll: int = _rng.randi_range(1, total)
	for kind: String in mix:
		roll -= int(mix[kind])
		if roll <= 0:
			return kind
	return mix.keys()[0]
