class_name Pickups
extends Node3D
## Things the creatures leave behind: light motes (experience) and glowing ingredients. Inside the player's pickup
## reach they fly to the player and are collected.

signal collected(item: String, amount: int)

const XP: String = "xp"

var magnet_bonus: float = 0.0
var _player: Node3D
var _items: Array[Node3D] = []
var _clock: float = 0.0


func setup(player: Node3D) -> void:
	name = "Pickups"
	_player = player


## Drops an item ("xp" or an ingredient id) near a spot, scattered a little.
func drop(item: String, amount: int, at: Vector3) -> void:
	var colour: Color = Tuning.color(Tuning.doc("defence")["pickup"]["xp_color"])
	var size: float = Tuning.number("defence", "pickup", "xp_size")
	if item != XP:
		colour = Tuning.color(Tuning.doc("defence")["ingredients"][item]["color"])
		size = Tuning.number("defence", "pickup", "ingredient_size")
	var node := Node3D.new()
	node.set_meta("item", item)
	node.set_meta("amount", amount)
	node.add_child(_gem(colour, size, item == XP))
	add_child(node)
	var scatter: float = Tuning.number("defence", "pickup", "scatter")
	node.global_position = Vector3(at.x + randf_range(-scatter, scatter), 0.0, at.z + randf_range(-scatter, scatter))
	_items.append(node)


func count() -> int:
	return _items.size()


func clear() -> void:
	for item: Node3D in _items:
		item.queue_free()
	_items.clear()


func _process(delta: float) -> void:
	_clock += delta
	var reach: float = Tuning.number("defence", "player", "pickup_radius") * (1.0 + magnet_bonus)
	var target: Vector3 = _player.global_position
	for item: Node3D in _items.duplicate():
		var to: Vector3 = Vector3(target.x - item.global_position.x, 0.0, target.z - item.global_position.z)
		if to.length() < Tuning.number("defence", "player", "collect_distance"):
			_collect(item)
		elif to.length() < reach:
			item.global_position += to.normalized() * Tuning.number("defence", "player", "magnet_speed") * delta
		var gem: Node3D = item.get_child(0)
		gem.position.y = Tuning.number("defence", "pickup", "float") * (1.0 + sin(_clock * PI) * 0.5)
		gem.rotation.y = _clock * Tuning.number("defence", "pickup", "spin_speed")


func _collect(item: Node3D) -> void:
	_items.erase(item)
	collected.emit(item.get_meta("item"), item.get_meta("amount"))
	item.queue_free()


func _gem(colour: Color, size: float, is_mote: bool) -> MeshInstance3D:
	var mesh: PrimitiveMesh
	if is_mote:
		var sphere := SphereMesh.new()
		sphere.radius = size * 0.5
		sphere.height = size
		mesh = sphere
	else:
		var prism := PrismMesh.new()
		prism.size = Vector3.ONE * size
		mesh = prism
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = Tuning.number("defence", "pickup", "energy")
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
