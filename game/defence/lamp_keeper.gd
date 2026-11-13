class_name LampKeeper
extends Node3D
## Looks after the town's lamps during a night: finds the nearest lit lamp (moths fly for it), relights a snuffed
## lamp while the player stands beside it for a moment (a ring fills at the lamp's foot), and counts how many are
## lit. Snuffed lamps simply go dark, so the area around them dims.

signal relit(lamp: LampLight)

var lamps: Array[LampLight] = []
var relight_progress: float = 0.0
var _player: Node3D
var _ring: MeshInstance3D


func setup(town_lamps: Array[LampLight], player: Node3D) -> void:
	name = "LampKeeper"
	lamps = town_lamps
	_player = player
	_ring = RingMesh.make(Color(Tuning.color(Tuning.doc("lighting")["street_lamp"]["color"])))
	_ring.visible = false
	add_child(_ring)


func nearest_lit(at: Vector3) -> LampLight:
	var best: LampLight = null
	var best_distance: float = INF
	for lamp: LampLight in lamps:
		var distance: float = lamp.global_position.distance_squared_to(at)
		if lamp.lit and distance < best_distance:
			best = lamp
			best_distance = distance
	return best


func lit_count() -> int:
	return lamps.filter(func(lamp: LampLight) -> bool: return lamp.lit).size()


## Whether the player is close to a lit lamp (they recover a little health there).
func near_lit(at: Vector3, radius: float) -> bool:
	var lamp: LampLight = nearest_lit(at)
	return lamp != null and _flat_distance(lamp.global_position, at) < radius


func relight_all() -> void:
	for lamp: LampLight in lamps:
		lamp.relight()


func _process(delta: float) -> void:
	var lamp: LampLight = _nearest_snuffed()
	var reach: float = Tuning.number("defence", "lamps", "relight_radius")
	if lamp == null or _flat_distance(lamp.global_position, _player.global_position) > reach:
		relight_progress = 0.0
		_ring.visible = false
		return
	relight_progress += delta / Tuning.number("defence", "lamps", "relight_seconds")
	_ring.visible = true
	_ring.global_position = Vector3(lamp.global_position.x, RingMesh.LIFT, lamp.global_position.z)
	var size: float = reach * minf(relight_progress, 1.0)
	_ring.scale = Vector3(size, RingMesh.LIFT, size)
	if relight_progress >= 1.0:
		lamp.relight()
		relight_progress = 0.0
		relit.emit(lamp)


func _nearest_snuffed() -> LampLight:
	var best: LampLight = null
	for lamp: LampLight in lamps:
		if lamp.lit:
			continue
		if best == null or _flat_distance(lamp.global_position, _player.global_position) < _flat_distance(
				best.global_position, _player.global_position):
			best = lamp
	return best


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
