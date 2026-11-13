class_name Pickups
extends Node3D
## Things the creatures leave behind: light motes (experience) and ingredients (each its own little shape).
## Inside the player's pickup reach they fly to the player and are collected.

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
	var spec: Dictionary = Tuning.doc("defence")["pickup"]
	var node := Node3D.new()
	node.set_meta("item", item)
	node.set_meta("amount", amount)
	if item == XP:
		node.add_child(IngredientShapes.make("mote", Tuning.color(spec["xp_color"]), float(spec["xp_size"]),
			float(spec["xp_energy"])))
	else:
		var ingredient: Dictionary = Tuning.doc("defence")["ingredients"][item]
		node.add_child(IngredientShapes.make(ingredient["shape"], Tuning.color(ingredient["color"]),
			float(spec["ingredient_size"]), float(spec["energy"])))
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
