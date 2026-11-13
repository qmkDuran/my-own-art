class_name PlayerBolt
extends Node3D
## One primary bolt: a small flame wisp flying straight; it stops at the first wall or enemy in its way (a slightly
## generous ball, so near-misses that look like hits count), deals its damage (sometimes a critical hit) with a
## crisp warm impact on the near side of the enemy and a hit sound, and leaves its trail to fade.

var _kit: LamplighterKit
var _direction: Vector3 = Vector3.FORWARD
var _travelled: float = 0.0
var _wisp: FlameWisp


func setup(kit: LamplighterKit, direction: Vector3) -> void:
	name = "PlayerBolt"
	_kit = kit
	_direction = direction.normalized()
	_wisp = FlameWisp.new()
	add_child(_wisp)
	_wisp.setup(kit.fx.kit, kit.fx.look("primary")["wisp"], _direction)


func _physics_process(delta: float) -> void:
	var from: Vector3 = global_position
	var step: float = Tuning.number("combat", "primary", "speed") * delta
	var to: Vector3 = from + _direction * step
	_travelled += step
	var query := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD, [_kit.player.get_rid()])
	var wall: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = wall["position"] if not wall.is_empty() else to
	var hit: Dictionary = _kit.roster.sweep(from, end, Tuning.number("combat", "primary", "radius"))
	if not hit.is_empty():
		_strike(hit["enemy"], hit["point"])
	elif not wall.is_empty():
		_kit.fx.impact("primary", end, Vector3(end.x, _kit.ground_at(end), end.z))
		_finish()
	elif _travelled > Tuning.number("combat", "primary", "range"):
		_finish()
	else:
		global_position = to


func _strike(enemy: Enemy, at: Vector3) -> void:
	var contact: Vector3 = enemy.centre() - _direction * enemy.radius
	var hit := Hit.new(Tuning.number("combat", "primary", "damage"), "primary", contact, _direction)
	hit.critical = randf() < Tuning.number("combat", "primary", "crit_chance")
	if hit.critical:
		hit.amount *= Tuning.number("combat", "primary", "crit_multiplier")
	enemy.take_hit(hit)
	_kit.fx.impact("primary", contact, Vector3(at.x, enemy.global_position.y, at.z))
	_kit.fx.kit.sfx.cue("primary_hit", contact)
	_finish()


func _finish() -> void:
	_wisp.leave_behind()
	queue_free()
