class_name BotReflexes
extends RefCounted
## Split-second reactions, decided once per threat with a fixed chance so the bot is beatable: roll sideways out of
## the path of an incoming glob of spit, or roll back from a bite wind-up it can see. Also reports incoming spit
## so the fight state can decide to take cover.

const ROLL_SIDE_ANGLE: float = PI * 0.25

var _bot: Creature
var _target: Creature
var _senses: Perception
var _rng: RandomNumberGenerator
var _decided: Dictionary = {}
var _bite_decided: bool = false


func _init(bot: Creature, target: Creature, senses: Perception, rng: RandomNumberGenerator) -> void:
	_bot = bot
	_target = target
	_senses = senses
	_rng = rng


func tick() -> void:
	var glob: SpitProjectile = incoming_spit()
	if glob != null and not _decided.has(glob.get_instance_id()):
		_decided[glob.get_instance_id()] = true
		if _rng.randf() < Tuning.f("bot", "dodge_chance"):
			_roll(glob.velocity().cross(Vector3.UP).normalized() * BotBrain.random_side(_rng))
	_react_to_bite()


## The target's glob that will pass close to us soon, if any.
func incoming_spit() -> SpitProjectile:
	for node: Node in _bot.get_tree().get_nodes_in_group("spit"):
		var glob := node as SpitProjectile
		if glob.shooter != _target:
			continue
		var offset: Vector3 = _bot.chest_position() - glob.global_position
		var speed_sq: float = glob.velocity().length_squared()
		var time_to_pass: float = offset.dot(glob.velocity()) / speed_sq
		if time_to_pass <= 0.0 or time_to_pass > Tuning.f("bot", "dodge_react_time"):
			continue
		var miss: float = (offset - glob.velocity() * time_to_pass).length()
		if miss <= Tuning.f("bot", "dodge_threat_width"):
			return glob
	return null


func _react_to_bite() -> void:
	if _target.bite.phase != Ability.Phase.WINDUP:
		_bite_decided = false
		return
	var reach: float = Tuning.f("bite", "range") + Tuning.f("bite", "lunge_distance")
	if _bite_decided or not _senses.sees_target or _bot.global_position.distance_to(_target.global_position) > reach:
		return
	_bite_decided = true
	if _rng.randf() < Tuning.f("bot", "dodge_chance"):
		var away: Vector3 = _bot.global_position - _target.global_position
		var back: Vector3 = Vector3(away.x, 0.0, away.z).normalized()
		_roll(back.rotated(Vector3.UP, BotBrain.random_side(_rng) * ROLL_SIDE_ANGLE))


func _roll(direction: Vector3) -> void:
	var steering: Vector3 = _bot.move_intent
	_bot.move_intent = direction
	if not _bot.try_dodge():
		_bot.move_intent = steering
