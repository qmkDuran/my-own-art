class_name LightBolt
extends Node3D
## One Lantern Flare bolt: flies straight (as a flame wisp), hurts each creature it passes through (up to its
## pierce count, sometimes a critical hit), and on each hit sets off the impact effect, the hit sound and the hit
## feel. At the end of its range, or as soon as its attack is gone, it leaves its trail behind and goes.

var _attack: Attack
var _direction: Vector3
var _travelled: float = 0.0
var _hits_left: int = 0
var _already: Array[Creature] = []
var _wisp: FlameWisp


func setup(attack: Attack, from: Vector3, to: Vector3) -> void:
	name = "LightBolt"
	_attack = attack
	_direction = from.direction_to(to)
	_hits_left = int(attack.stat("pierce"))
	if attack.kit != null:
		_wisp = FlameWisp.new()
		add_child(_wisp)
		_wisp.setup(attack.kit, Tuning.doc("vfx")["lantern_flare"]["wisp"], _direction)
	else:
		add_child(attack.glow_ball(attack.area_stat("size"), 1.0))


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_attack):
		_finish()
		return
	var step: float = _attack.stat("speed") * delta
	global_position += _direction * step
	_travelled += step
	_attack.fade_near_camera(self)
	for creature: Creature in _attack.horde.within(global_position, _attack.area_stat("size")):
		if _already.has(creature) or absf(creature.centre().y - global_position.y) > creature.radius * 2.0:
			continue
		_already.append(creature)
		_hit(creature)
		_hits_left -= 1
		if _hits_left <= 0:
			_finish()
			return
	if _travelled > _attack.stat("range"):
		_finish()


func _hit(creature: Creature) -> void:
	var feel: Dictionary = Tuning.doc("vfx")["lantern_flare"]["hit_feel"]
	var critical: bool = randf() < float(feel["crit_chance"])
	var damage: float = _attack.stat("damage") * (float(feel["crit_multiplier"]) if critical else 1.0)
	var strong: bool = damage >= creature.max_health * float(feel["strong_share"])
	creature.hurt(damage, _direction)
	var kit: VfxKit = _attack.kit
	if kit == null:
		return
	var look: Dictionary = Tuning.doc("vfx")["lantern_flare"]
	var burst := ImpactBurst.new()
	kit.place(burst, creature.centre())
	burst.play(kit, look["impact"], look["mark"], creature.global_position)
	kit.sfx.play("flare_pop", creature.centre())
	kit.sfx.play("flare_crackle", creature.centre())
	if creature.health <= 0.0 or strong:
		kit.hit_feel.hit_stop(int(feel["stop_frames"]), float(feel["stop_time_scale"]))
	if critical:
		kit.hit_feel.nudge(float(feel["nudge"]), float(feel["nudge_seconds"]))


func _finish() -> void:
	if _wisp != null:
		_wisp.leave_behind()
	queue_free()
