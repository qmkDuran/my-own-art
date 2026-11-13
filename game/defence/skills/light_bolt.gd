class_name LightBolt
extends Node3D
## One Lantern Flare bolt: flies straight, hurts each creature it passes through (up to its pierce count) and
## fades out at the end of its range (or as soon as its attack is gone, when a night ends).

var _attack: Attack
var _direction: Vector3
var _travelled: float = 0.0
var _hits_left: int = 0
var _already: Array[Creature] = []


func setup(attack: Attack, from: Vector3, to: Vector3) -> void:
	name = "LightBolt"
	_attack = attack
	_direction = from.direction_to(to)
	_hits_left = int(attack.stat("pierce"))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_attack):
		queue_free()
		return
	var step: float = _attack.stat("speed") * delta
	global_position += _direction * step
	_attack.fade_near_camera(self)
	_travelled += step
	for creature: Creature in _attack.horde.within(global_position, _attack.area_stat("size")):
		if _already.has(creature) or absf(creature.centre().y - global_position.y) > creature.radius * 2.0:
			continue
		_already.append(creature)
		creature.hurt(_attack.stat("damage"), _direction)
		_hits_left -= 1
		if _hits_left <= 0:
			queue_free()
			return
	if _travelled > _attack.stat("range"):
		queue_free()
