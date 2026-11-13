class_name Horde
extends Node3D
## Every creature alive tonight: spawns them, answers "who is near here?" for the lantern magic, hurts the player
## when one touches them, and pops defeated creatures into sparkles (telling whoever listens, so drops can fall).

signal defeated(creature: Creature)

var creatures: Array[Creature] = []
var toughness: float = 1.0
var _library: AssetLibrary
var _player: Node3D
var _lamps: LampKeeper
var _vitality: Vitality


func setup(library: AssetLibrary, player: Node3D, lamps: LampKeeper, vitality: Vitality) -> void:
	name = "Horde"
	_library = library
	_player = player
	_lamps = lamps
	_vitality = vitality


func spawn(kind: String, at: Vector3) -> Creature:
	var creature := Creature.new()
	creature.setup(kind, _library, _player, _lamps, toughness)
	add_child(creature)
	creature.global_position = at
	creature.died.connect(_on_died)
	creatures.append(creature)
	return creature


func nearest(at: Vector3, within: float = INF) -> Creature:
	var best: Creature = null
	var best_distance: float = within * within
	for creature: Creature in creatures:
		var distance: float = creature.centre().distance_squared_to(at)
		if distance < best_distance:
			best = creature
			best_distance = distance
	return best


## Creatures whose body overlaps a ball (flat distance on the ground, so height does not matter).
func within(at: Vector3, radius: float) -> Array[Creature]:
	var out: Array[Creature] = []
	for creature: Creature in creatures:
		var flat := Vector2(creature.global_position.x - at.x, creature.global_position.z - at.z)
		if flat.length() < radius + creature.radius:
			out.append(creature)
	return out


func boss() -> Creature:
	for creature: Creature in creatures:
		if creature.is_boss:
			return creature
	return null


func clear() -> void:
	for creature: Creature in creatures:
		creature.queue_free()
	creatures.clear()


func _physics_process(_delta: float) -> void:
	for creature: Creature in within(_player.global_position, Vitality.BODY_RADIUS):
		_vitality.hurt(float(creature.spec["damage"]))


func _on_died(creature: Creature) -> void:
	creatures.erase(creature)
	var burst := SparkleBurst.new()
	add_child(burst)
	burst.global_position = creature.centre()
	defeated.emit(creature)
	creature.queue_free()
