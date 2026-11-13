class_name BotReflexes
extends RefCounted
## Split-second reactions, decided once per threat with a fixed chance so the bot is beatable: roll sideways out of
## the path of an incoming shot it can see, or roll back from a strike wind-up it can see. The roll comes after the
## difficulty's reflex delay. Also reports incoming shots so the bot can decide to take cover.

const ROLL_SIDE_ANGLE: float = PI * 0.25

var _bot: Creature
var _target: Creature
var _senses: Perception
var _rng: RandomNumberGenerator
var _decided: Dictionary = {}
var _bite_decided: bool = false
var _pending: Vector3 = Vector3.ZERO
var _pending_left: float = INF


func _init(bot: Creature, target: Creature, senses: Perception, rng: RandomNumberGenerator) -> void:
	_bot = bot
	_target = target
	_senses = senses
	_rng = rng


func tick(delta: float) -> void:
	_pending_left -= delta
	if _pending_left <= 0.0:
		_pending_left = INF
		_roll(_pending)
	var glob: Projectile = incoming_shot()
	if glob != null and not _decided.has(glob.get_instance_id()):
		_decided[glob.get_instance_id()] = true
		if _rng.randf() < Tuning.f("bot", "dodge_chance"):
			_plan_roll(glob.velocity().cross(Vector3.UP).normalized() * BotBrain.random_side(_rng))
	_react_to_strike()


## The target's shot that will pass close to us soon, if any.
func incoming_shot() -> Projectile:
	for node: Node in _bot.get_tree().get_nodes_in_group("projectiles"):
		var glob := node as Projectile
		if glob.shooter != _target or not Sight.clear(_bot.get_world_3d(), _bot.eye_position(), glob.global_position):
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


func _react_to_strike() -> void:
	var strike: Move = _winding_strike()
	if strike == null:
		_bite_decided = false
		return
	var reach: float = BotFacts.effective_range(strike)
	if _bite_decided or not _senses.sees_target or _bot.global_position.distance_to(_target.global_position) > reach:
		return
	_bite_decided = true
	if _rng.randf() < Tuning.f("bot", "dodge_chance"):
		var away: Vector3 = _bot.global_position - _target.global_position
		var back: Vector3 = Vector3(away.x, 0.0, away.z).normalized()
		_plan_roll(back.rotated(Vector3.UP, BotBrain.random_side(_rng) * ROLL_SIDE_ANGLE))


func _winding_strike() -> Move:
	for move: Move in _target.moves:
		if move.phase == Ability.Phase.WINDUP and (move is MeleeMove or move is AreaMove):
			return move
	return null


func _plan_roll(direction: Vector3) -> void:
	_pending = direction
	_pending_left = Difficulty.setting("reflex_delay")


func _roll(direction: Vector3) -> void:
	var steering: Vector3 = _bot.move_intent
	_bot.move_intent = direction
	if not _bot.try_roll():
		_bot.move_intent = steering
