class_name OrbitAttack
extends Attack
## Glowing things circling the player that hurt whatever they touch, each creature at most once per hit_every
## seconds: Firefly Swarm, its combo Star Swarm, and the Candle Ring (whose orbiters are little candles).

const ORB_ENERGY: float = 5.0
const ORB_HEIGHT: float = 1.0
const CANDLE_HEIGHT: float = 0.6
const WAX: Color = Color(0.95, 0.9, 0.8)
const WAX_WIDTH_SHARE: float = 0.25
const LIGHT_RANGE: float = 2.5
const LIGHT_ENERGY: float = 0.8
const MS_PER_SECOND: float = 1000.0

var _angle: float = 0.0
var _orbiters: Array[Node3D] = []
var _last_hit: Dictionary = {}


func tick(delta: float) -> void:
	_angle += stat("spin") * delta
	var centre: Vector3 = player.global_position
	var now: float = Time.get_ticks_msec() / MS_PER_SECOND
	for index: int in _orbiters.size():
		var turn: float = _angle + TAU * index / _orbiters.size()
		var orbiter: Node3D = _orbiters[index]
		var ring: Vector3 = Vector3(cos(turn), 0.0, sin(turn)) * area_stat("orbit")
		orbiter.global_position = centre + ring + Vector3.UP * _height()
		for creature: Creature in horde.within(orbiter.global_position, area_stat("size")):
			if now - float(_last_hit.get(creature.get_instance_id(), -INF)) >= stat("hit_every"):
				_last_hit[creature.get_instance_id()] = now
				creature.hurt(stat("damage"))


func on_level_changed() -> void:
	for orbiter: Node3D in _orbiters:
		orbiter.queue_free()
	_orbiters.clear()
	for index: int in int(stat("count")):
		var orbiter: Node3D = _candle() if id == "candle_ring" else glow_ball(area_stat("size"), ORB_ENERGY)
		orbiter.top_level = true
		if index % 2 == 0:
			orbiter.add_child(_glow_light())
		add_child(orbiter)
		_orbiters.append(orbiter)


func _height() -> float:
	return CANDLE_HEIGHT if id == "candle_ring" else ORB_HEIGHT


func _candle() -> Node3D:
	var candle := Node3D.new()
	var wax := CylinderMesh.new()
	wax.top_radius = area_stat("size") * WAX_WIDTH_SHARE
	wax.bottom_radius = wax.top_radius
	wax.height = area_stat("size")
	var material := StandardMaterial3D.new()
	material.albedo_color = WAX
	wax.material = material
	var body := MeshInstance3D.new()
	body.mesh = wax
	candle.add_child(body)
	var flame: MeshInstance3D = glow_ball(area_stat("size") * WAX_WIDTH_SHARE * 2.0, ORB_ENERGY)
	flame.position.y = area_stat("size") * 0.5 + wax.top_radius
	candle.add_child(flame)
	return candle


func _glow_light() -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = colour()
	light.light_energy = LIGHT_ENERGY
	light.omni_range = LIGHT_RANGE
	return light
